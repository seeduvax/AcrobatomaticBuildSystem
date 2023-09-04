_app_projC_dir:=$(dir $(lastword $(MAKEFILE_LIST)))

-include $(wildcard $(_app_projC_dir)/.abs/index_*.mk)
$(eval $(call extlib_import_template,projC,2.4.3d,projB-2.4.2d projD-2.4.4d))
_module_projC_cpplib_depends:=projB_cpplib projD_cpplib
_module_projC_cpplib_dir:=$(_app_projC_dir)
_module_projC__extra_dir:=$(_app_projC_dir)



