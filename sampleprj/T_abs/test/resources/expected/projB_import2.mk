_app_projB_dir:=$(dir $(lastword $(MAKEFILE_LIST)))

_app_projB_version:=2.4.2d
_app_projB_uselib:=libtest-1.0.0 projA|1.4.2d testlib-dashed|1.0.1

-include $(wildcard $(_app_projB_dir)/.abs/index_*.mk)
$(eval $(call extlib_import_template,projB,$(_app_projB_version),$(_app_projB_uselib)))

_module_projB_cpplib_depends:=projA_cpplib projA_fileset projB_fileset libtest 
_module_projB_cpplib2_depends:=projA_cpplib testlib-dashed 
_module_projB_cpplib3_depends:= 
_module_projB_fileset_depends:=projA_fileset
_module_projB_cpplib_dir:=$(_app_projB_dir)
_module_projB_cpplib2_dir:=$(_app_projB_dir)
_module_projB_cpplib3_dir:=$(_app_projB_dir)
_module_projB_fileset_dir:=$(_app_projB_dir)
_module_projB__extra_dir:=$(_app_projB_dir)


