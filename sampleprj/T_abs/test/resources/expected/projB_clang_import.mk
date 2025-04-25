_app_projB_dir:=$(dir $(lastword $(MAKEFILE_LIST)))

_app_projB_version:=2.4.2d_clang-13
_app_projB_uselib:=projA|1.4.2d runtime-clang-13 testlib-dashed|1.0.1
_app_projB_modules:=cpplib cpplib2 cpplib3 fileset

_module_projB_cpplib_uselib:=libtest-1.0.0
_module_projB_cpplib2_uselib:=libtest-1.0.0

_module_projB_cpplib_depends:=libtest projA_cpplib projB_fileset
_module_projB_cpplib2_depends:=libtest projA_cpplib testlib-dashed
_module_projB_fileset_depends:=projA_fileset

_module_projB_cpplib_dir:=$(_app_projB_dir)
_module_projB_cpplib2_dir:=$(_app_projB_dir)
_module_projB_cpplib3_dir:=$(_app_projB_dir)
_module_projB_fileset_dir:=$(_app_projB_dir)
_module_projB__extra_dir:=$(_app_projB_dir)
_app_projB_alluselib:=$(sort $(_app_projB_uselib) $(_module_projB_cpplib_uselib) $(_module_projB_cpplib2_uselib))

-include $(wildcard $(_app_projB_dir)/.abs/index_*.mk)
$(eval $(call extlib_import_template,projB,$(_app_projB_version),$(_app_projB_alluselib)))


