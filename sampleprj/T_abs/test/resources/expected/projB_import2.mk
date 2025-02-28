_app_projB_dir:=$(dir $(lastword $(MAKEFILE_LIST)))

-include $(wildcard $(_app_projB_dir)/.abs/index_*.mk)
$(eval $(call extlib_import_template,projB,2.4.2d,libtest-1.0.0 projA-1.4.2d testlib2-1.0.1))

_module_projB_cpplib_depends:=projA_cpplib projA_fileset projB_fileset libtest 
_module_projB_cpplib2_depends:=projA_cpplib testlib2 
_module_projB_fileset_depends:=projA_fileset
_module_projB_cpplib_dir:=$(_app_projB_dir)
_module_projB_cpplib2_dir:=$(_app_projB_dir)
_module_projB_fileset_dir:=$(_app_projB_dir)
_module_projB__extra_dir:=$(_app_projB_dir)


