# -*-coding:Utf-8 -*
# @file moduleB.py
#
# Copyright 2016 Airbus Safran Launchers. All rights reserved.
# Use is subject to license terms.
# 
# $Id$
# $Date$
# 
# module hierarchy:
# sampleprj.pysubpckB.moduleB


# A python 'module' file is a script .py file
# which creates its objects:
# - variables 
# - classes
# - functions
# - ...
# at importation time
# 
# Its objects populate its local context.
# and are accessible via module 
# importation
#
# Nota:
# dynamic context overload is to be handled
# carefully and should be performed as much as 
# possible by the module itself.

# The line below will import package and subpackage
# sampleprj and pysubpckA and fetch the class member Toto
# from moduleA
# This action is performed at importation time !
from sampleprj.pysubpckA.moduleA import Toto  

class Tata(Toto):
    def check(self):
        return True

