#include "projA/cpplib/Example.hpp"
#include "projB/cpplib/Example.hpp"

namespace projB {
	namespace cpplib {
// --------------------------------------------------------------------
// ..........................................................
//
void Example::helloWorld() {
    projA::cpplib::Example example;
    example.helloWorld();
}

}} // namespace projB::cpplib 
