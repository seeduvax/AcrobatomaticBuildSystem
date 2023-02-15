#include "projA/cpplib/Example.hpp"
#include "projB/cpplib/Example.hpp"
#include "projC/cpplib/Example.hpp"
#include "projD/cpplib/Example.hpp"

namespace projC {
	namespace cpplib {
// --------------------------------------------------------------------
// ..........................................................
//
void Example::helloWorld() {
    projA::cpplib::Example example;
    example.helloWorld();
    projB::cpplib::Example exampleB;
    exampleB.helloWorld();
    projD::cpplib::Example exampleD;
    exampleD.helloWorld();
}

}} // namespace projC::cpplib 
