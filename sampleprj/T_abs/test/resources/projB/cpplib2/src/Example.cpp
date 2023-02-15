#include "projA/cpplib/Example.hpp"
#include "projB/cpplib2/Example.hpp"

namespace projB {
	namespace cpplib2 {
// --------------------------------------------------------------------
// ..........................................................
//
void Example::helloWorld() {
    projA::cpplib::Example example;
    example.helloWorld();
}

}} // namespace projB::cpplib2 
