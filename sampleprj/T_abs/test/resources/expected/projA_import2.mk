_app_projA_dir:=$(dir $(lastword $(MAKEFILE_LIST)))

_app_projA_version:=1.4.2d
_app_projA_uselib:=

-include $(wildcard $(_app_projA_dir)/.abs/index_*.mk)
$(eval $(call extlib_import_template,projA,$(_app_projA_version),$(_app_projA_uselib)))

_module_projA_cppexe_depends:=projA_cpplib 
_module_projA_cpplib_depends:= 
_module_projA_fileset_depends:=
_module_projA_cppexe_dir:=$(_app_projA_dir)
_module_projA_cpplib_dir:=$(_app_projA_dir)
_module_projA_fileset_dir:=$(_app_projA_dir)
_module_projA__extra_dir:=$(_app_projA_dir)


