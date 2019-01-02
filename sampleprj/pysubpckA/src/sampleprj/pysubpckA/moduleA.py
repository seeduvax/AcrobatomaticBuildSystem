# -*-coding:Utf-8 -*
# @file moduleA.py
#
# Copyright 2016 Airbus Safran Launchers. All rights reserved.
# Use is subject to license terms.
# 
# $Id$
# $Date$
# 
# module hierarchy:
# sampleprj.pysubpckA.moduleA

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

class Toto():
    def check(self):
        return False

staticToto=Toto()

# Classic dynamic overload
staticToto.check = lambda *a,**k: True

# Dynamic member overload 
# performed by the module
# through its api
def addMember(key,value):
    setattr(staticToto,key,value)


