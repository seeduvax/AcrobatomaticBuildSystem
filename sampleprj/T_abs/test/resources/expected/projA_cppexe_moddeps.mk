ifeq ($(_module_projA_cppexe_dir),)
include $(patsubst %,$(PRJOBJDIR)/%/moddeps.mk,cpplib)

_module_projA_cppexe_dir=$(TRDIR)
_module_projA_cppexe_depends=$(sort $(call getLibrariesNameFromLinklib,)  projA_cpplib)

_module_projA_cppexe_done_depends=$(patsubst %,$(PRJOBJDIR)/%/.done,cpplib)

_module_projA_cppexe_uselib=rust-1.82.0
_module_projA_cppexe_nduselib=libtest|1.0.0
_modules_projA_uselib+=$(_module_projA_cppexe_uselib)
_modules_projA_nduselib+=$(_module_projA_cppexe_nduselib)

$(PRJOBJDIR)/cppexe/.depready: $(_module_projA_cppexe_done_depends)

$(PRJOBJDIR)/cppexe/.done: $(wildcard $(foreach toLook,etc src include module.cfg local.cfg,$(call find,$(PRJROOT)/cppexe/$(toLook),*)))

$(PRJOBJDIR)/cppexe/.done: $(_module_projA_cppexe_done_depends)

$(PRJOBJDIR)/cppexe/.testdone: $(PRJOBJDIR)/cppexe/.done
$(PRJOBJDIR)/cppexe/.testdone: $(wildcard $(foreach toLook,test module.cfg local.cfg,$(call find,$(PRJROOT)/cppexe/$(toLook),*)))

testmod.cppexe: $(patsubst %,testmod.%,cpplib)

endif
