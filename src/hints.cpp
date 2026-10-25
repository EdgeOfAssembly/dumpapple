#include "hints.h"
#include <fstream>
#include <sstream>

namespace da {

bool parseNumber(const std::string &s0, uint32_t &v) {
    std::string s = s0;
    if (s.empty()) return false;
    int baseN = 16;
    if (s[0] == '$') s = s.substr(1);
    else if (s.size() > 2 && s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) s = s.substr(2);
    else if (s[0] == '#') { s = s.substr(1); baseN = 10; }
    if (s.empty() || s.size() > 10) return false;
    uint64_t r = 0;
    for (char ch : s) {
        int d;
        if (ch >= '0' && ch <= '9') d = ch - '0';
        else if (baseN == 16 && ch >= 'a' && ch <= 'f') d = ch - 'a' + 10;
        else if (baseN == 16 && ch >= 'A' && ch <= 'F') d = ch - 'A' + 10;
        else if (ch == '_') continue;
        else return false;
        r = r * baseN + d;
        if (r > 0xFFFFFFFFull) return false;
    }
    v = (uint32_t)r;
    return true;
}

bool parseAddr(const std::string &s, const Image &img, uint32_t &addr) {
    auto c = s.find(':');
    if (c != std::string::npos) {
        uint32_t sn, off;
        if (!parseNumber(s.substr(0, c), sn) || !parseNumber(s.substr(c + 1), off)) return false;
        for (auto &g : img.segs)
            if (g.segnum == sn) { addr = g.base + off; return off <= g.data.size(); }
        return false;
    }
    if (!parseNumber(s, addr)) return false;
    return addr <= 0xFFFFFF;
}

bool readHintsFile(const std::string &path, RawHints &raw, std::string &err) {
    std::ifstream in(path);
    if (!in) { err = "cannot open hints file " + path; return false; }
    raw.file = path;
    std::string line;
    int n = 0;
    while (std::getline(in, line)) {
        n++;
        std::string body = line, tail;
        // comment directive keeps its text verbatim
        std::istringstream ss(body);
        std::vector<std::string> w;
        std::string t;
        while (ss >> t) {
            if (t[0] == '#' || t[0] == ';') break;
            w.push_back(t);
            if (w.size() == 2 && w[0] == "comment") {
                std::string rest;
                std::getline(ss, rest);
                size_t p = rest.find_first_not_of(" \t");
                w.push_back(p == std::string::npos ? "" : rest.substr(p));
                break;
            }
        }
        if (w.empty()) continue;
        raw.lines.push_back(w);
        raw.lineNo.push_back(n);
        raw.files.push_back(path);
    }
    return true;
}

static std::string where(const RawHints &r, size_t i) { return (i < r.files.size() ? r.files[i] : r.file) + ":" + std::to_string(r.lineNo[i]) + ": "; }

bool hintsSegBase(const RawHints &raw, std::map<uint16_t, uint32_t> &out, std::string &err) {
    for (size_t i = 0; i < raw.lines.size(); i++) {
        auto &w = raw.lines[i];
        if (w[0] != "segbase") continue;
        uint32_t sn, a;
        if (w.size() != 3 || !parseNumber(w[1], sn) || !parseNumber(w[2], a) || a > 0xFFFFFF) {
            err = where(raw, i) + "usage: segbase SEGNUM ADDR"; return false;
        }
        out[(uint16_t)sn] = a;
    }
    return true;
}

bool hintsRegions(const RawHints &raw, std::vector<Hints::Region> &out, std::string &err) {
    for (size_t i = 0; i < raw.lines.size(); i++) {
        auto &w = raw.lines[i];
        if (w[0] != "region") continue;
        Hints::Region r;
        if (w.size() != 4 || !parseNumber(w[1], r.fileOff) || !parseNumber(w[2], r.len) || !parseNumber(w[3], r.addr) || r.len == 0 || r.addr > 0xFFFFFF) {
            err = where(raw, i) + "usage: region FILEOFF LEN ADDR"; return false;
        }
        out.push_back(r);
    }
    return true;
}

bool resolveHints(const RawHints &raw, const Image &img, Hints &h, std::string &err) {
    for (size_t i = 0; i < raw.lines.size(); i++) {
        auto &w = raw.lines[i];
        const std::string &k = w[0];
        if (k == "segbase" || k == "region") continue;
        uint32_t a = 0;
        if (w.size() < 2 || (!(k == "rtstable" && w[1] == "split") && !parseAddr(w[1], img, a))) { err = where(raw, i) + "bad or missing address"; return false; }
        State st;
        if (k == "entry" || k == "code") {
            Hints::Entry e{a, false, State{}};
            if (w.size() >= 3) {
                if (!parseState(w[2], e.st)) { err = where(raw, i) + "bad state '" + w[2] + "'"; return false; }
                e.hasState = true;
            }
            h.entries.push_back(e);
        } else if (k == "state" || k == "returns") {
            if (w.size() != 3 || !parseState(w[2], st)) { err = where(raw, i) + "usage: " + k + " ADDR STATE"; return false; }
            (k == "state" ? h.forced : h.returns)[a] = st;
        } else if (k == "noreturn") {
            h.noreturn.insert(a);
        } else if (k == "data" || k == "word") {
            uint32_t len = 1;
            if (w.size() >= 3 && !parseNumber(w[2], len)) { err = where(raw, i) + "bad length"; return false; }
            if (len == 0) { err = where(raw, i) + "zero length"; return false; }
            h.dataRanges[a] = std::max(h.dataRanges[a], len);
            if (k == "word") h.wordRanges[a] = len;
        } else if (k == "inline") {
            uint32_t n;
            if (w.size() == 3 && (w[2] == "z" || w[2] == "hi" || w[2] == "lo" || w[2] == "len")) { h.varInlines[a] = w[2] == "z" ? 4 : w[2] == "hi" ? 5 : w[2] == "lo" ? 6 : 7; h.inlines.erase(a); continue; }
            if (w.size() != 3 || !parseNumber(w[2], n) || n == 0 || n > 255) { err = where(raw, i) + "usage: inline ADDR N (1..255) | inline ADDR z|hi|lo|len"; return false; }
            h.inlines[a] = n; h.varInlines.erase(a);
        } else if (k == "table") {
            Hints::Table t{a, 0, 0, false, State{}};
            if (w.size() < 3 || !parseNumber(w[2], t.count) || t.count == 0 || t.count > 65536) { err = where(raw, i) + "usage: table ADDR COUNT [word|long|rts] [STATE]"; return false; }
            for (size_t j = 3; j < w.size(); j++) {
                if (w[j] == "word") t.kind = 0;
                else if (w[j] == "long") t.kind = 1;
                else if (w[j] == "rts") t.kind = 2;
                else if (parseState(w[j], t.st)) t.hasState = true;
                else { err = where(raw, i) + "bad table option '" + w[j] + "'"; return false; }
            }
            h.tables.push_back(t);
        } else if (k == "rtstable") {
            // rtstable ADDR N            words holding target-1 (RTS dispatch)
            // rtstable split HI LO N     target-1 split into high- and low-byte tables
            Hints::Table t{0, 0, 2, false, State{}};
            if (w.size() >= 2 && w[1] == "split") {
                uint32_t hi, lo;
                if (w.size() < 5 || !parseAddr(w[2], img, hi) || !parseAddr(w[3], img, lo) || !parseNumber(w[4], t.count) || t.count == 0 || t.count > 256) {
                    err = where(raw, i) + "usage: rtstable split HI LO N [STATE]"; return false;
                }
                t.addr = lo; t.hiAddr = hi; t.kind = 4;
                if (w.size() == 6) { if (!parseState(w[5], t.st)) { err = where(raw, i) + "bad state '" + w[5] + "'"; return false; } t.hasState = true; }
                else if (w.size() > 6) { err = where(raw, i) + "usage: rtstable split HI LO N [STATE]"; return false; }
            } else {
                t.addr = a;
                if (w.size() < 3 || w.size() > 4 || !parseNumber(w[2], t.count) || t.count == 0 || t.count > 65536) { err = where(raw, i) + "usage: rtstable ADDR N [STATE]"; return false; }
                if (w.size() == 4) { if (!parseState(w[3], t.st)) { err = where(raw, i) + "bad state '" + w[3] + "'"; return false; } t.hasState = true; }
            }
            h.tables.push_back(t);
        } else if (k == "name") {
            if (w.size() != 3) { err = where(raw, i) + "usage: name ADDR NAME"; return false; }
            const std::string &nm = w[2];
            bool okName = !nm.empty() && (isalpha((unsigned char)nm[0]) || nm[0] == '_');
            for (char ch : nm) okName = okName && (isalnum((unsigned char)ch) || ch == '_');
            if (!okName) { err = where(raw, i) + "invalid label name '" + nm + "'"; return false; }
            h.names[a] = nm;
        } else if (k == "comment") {
            h.comments[a].push_back(w.size() >= 3 ? w[2] : "");
        } else {
            err = where(raw, i) + "unknown directive '" + k + "'"; return false;
        }
    }
    return true;
}

}
