#pragma once
#include "analyze.h"
#include <string>

namespace da {
struct EmitOptions {
    std::string sourceName;    // shown in header
    std::string listingBase;   // basename used in the rebuild comment
    Cpu cpu = Cpu::C65816;
    std::string platform = "none";
};
// Produces the ca65 source listing and the matching ld65 config.
bool emitListing(const Image &img, const Hints &h, const Analysis &an, const EmitOptions &o,
                 std::string &asmOut, std::string &cfgOut, std::string &err);
}
