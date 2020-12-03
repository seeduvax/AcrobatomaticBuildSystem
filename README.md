# Acrobatomatic Build System
![logo](_doc/src/abslogo128.png "ABS logo")
---

## What
Acrobatic Build System (ABS) is a generic build and packaging system for software. It supports many language and many targets. To be compatible, a project shall match the file and directory organization ABS expects. ABS is mainly made of a set of makefiles (GNU make to be used to run those makefiles). It is completed by some common commands available from any (near) posix like system (including cygwin and mingw) to handle some advance features such as downloading dependencies, running tests, packaging and publishing builds. Among the features are:
  - multi language support: C/C++, java, python.
  - generation of source code skeletons from templates: C++ class, unit test class
  - target architecture handling (including cross compilation)
  - dependencies management
  - binaries identification and traceability
  - auto installable package generation.
  - configuration management helpers and automation for continuous integration. 

## Why
During my years of coding I used many tools to manage and build projects, from the basic script or makefile to more featured more or less automatic product like autoconf/automake, cmake or maven/ant but never felt comfortable with any:
  - makefile generators (autoconf/automake / cmake) were to difficult to use for the new comer and I met many troubles from version incompatibility.
  - more featured tools like maven are language dependant and often require xml files that involve huge overhead for the everyday edition of project configuration.
  - many of those tools are not commonly available and by default installed. Working in constrained places were internet access is not directly available, being able to install new package becomes a major issue. 

One day I realized the GNU implementation of make provides many macro and text function that enable automatic targets definitions from the source tree content: look at `subst`, `wildcard` and `ifeq` that let you really code a complete build automation. So why use something more, just use `gmake` at its full power. By the time I had hacked collected many macros in a file to be reused by more and more projects. By the time, almost all the build rules were provided by a few generic makefile leaving in it almost nothing else than few variable and identifier. After some further standardization of my projects' layout, sometime inspired by other (in particular maven), ABS was there.

## Getting started
To create an new project to be managed with ABS, perform the following steps:
  - create a new empty directory for your project and enter this directory.
  - copy the file `core/bootstrap.mk` from the abs source tree as `Makefile`.
  - create and edit a file named `app.cfg` including at least the following content:
```
APPNAME:=appname
V_ABS:=3.0
ABS_REPO:=http://www.eduvax.net/dist

```
  - create a new module for your project with `make newmod modulename`
  - start coding and build your new module...
See ABS documentation ([html](http://www.eduvax.net/abs/ABS_manual_170983b.html), [pdf](http://www.eduvax.net/abs/ABS_manual_170983b.pdf)), [introduction slides](http://www.eduvax.net/abs/ABS_introduction_cb844d9.html) and the `sampleprj` [directory](https://github.com/seeduvax/AcrobatomaticBuildSystem/tree/abs-3.0/sampleprj) from the abs source tree for more information and example of use. You may also check my other projects (available at [github](https://github.com/seeduvax)) for more concrete and complete use case.

## Licensing
Acrobatomatic Build System is released under a BSD license. See LICENSE file included in the source file tree for the exact license definition. This licensing policy does not involve any constraint nor restriction on projects using ABS as is or with modifications. 
