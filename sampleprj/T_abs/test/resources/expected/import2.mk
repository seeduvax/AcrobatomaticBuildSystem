_app_projC_dir:=$(dir $(lastword $(MAKEFILE_LIST)))

_app_projC_version:=2.4.3d
_app_projC_uselib:=libtest-2.0.0 projB-2.4.2d projD-2.4.4d

-include $(wildcard $(_app_projC_dir)/.abs/index_*.mk)
$(eval $(call extlib_import_template,projC,$(_app_projC_version),$(_app_projC_uselib)))

_module_projC_cpplib_depends:=projB_cpplib projB_cpplib2 projD_cpplib projD_fileset
_module_projC_cpplib_dir:=$(_app_projC_dir)
_module_projC__extra_dir:=$(_app_projC_dir)


