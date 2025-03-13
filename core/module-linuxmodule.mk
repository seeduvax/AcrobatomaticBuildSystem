# path to kernel headers
ifeq (1,$(shell test -d /usr/src/linux-headers-$(KVERSION) && echo 1 || echo 0))
# debian style
KERNELDIR?=/usr/src/linux-headers-$(KVERSION)
else
# CentOS style
KERNELDIR?=/lib/modules/$(KVERSION)/build
endif
LKMNAME:=$(patsubst %_lkm,%,$(MODNAME))

include $(ABSROOT)/core/module-cheaders.mk

include $(ABSROOT)/core/module-crules-patches.mk

EXTRA_SIMVERS:=$(patsubst %,$(TRDIR)/obj/%/Module.symvers,$(USELKMOD))
CFGFILES:=$(patsubst %,$(TRDIR)/%,$(shell find etc -type f -a \( -name $(LKMNAME).conf -o -name $(LKMNAME) \)))
SERVICEFILES:=$(patsubst %,$(TRDIR)/%,$(shell find etc -name $(LKMNAME).service))
INITSFILES:=$(patsubst %,$(TRDIR)/%,$(shell find etc -type f -name $(LKMNAME)))

LKMSRCDIR=src

$(TRDIR)/etc/$(APPNAME)/%: $(LKMSRCDIR)/etc/$(APPNAME)/%
	@mkdir -p $(@D)
	cp $< $@
	
$(TRDIR)/etc/init.d/%: $(LKMSRCDIR)/etc/init.d/%
	@mkdir -p $(@D)
	cp $< $@
	@chmod +x $@

all-impl:: $(OBJDIR)/Makefile $(PUBLISHED_HEADERS) $(CFGFILES) $(SERVICEFILES) $(INITSFILES)
	$(MAKE) -C $(KERNELDIR) M=$(OBJDIR) KBUILD_EXTRA_SYMBOLS="$(EXTRA_SIMVERS)" modules
	@mkdir -p $(TRDIR)/lib/modules/
	@cp $(OBJDIR)/*.ko $(TRDIR)/lib/modules

install:: all
	@( test -x /etc/init.d/$(LKMNAME) && ( \
$(ABS_PRINT_info) "Stopping device $(LKMNAME) before install" ; \
/etc/init.d/$(LKMNAME) stop ) ) || true
	@$(MAKE) -C $(KERNELDIR) M=$(OBJDIR) INSTALL_MOD_DIR=$(APPNAME) modules_install
	@$(ABS_PRINT_info) "Running depmod..."
	@depmod -a
	@( test -f etc/$(APPNAME)/$(LKMNAME).conf -a ! -f /etc/$(APPNAME)/$(LKMNAME).conf && ( \
	$(ABS_PRINT_info) "Installing module configuration file..." ; \
	mkdir -p /etc/$(APPNAME) ; \
	cp etc/$(APPNAME)/$(LKMNAME).conf /etc/$(APPNAME)/ ; \
	chmod 644 /etc/$(APPNAME)/$(LKMNAME).conf ) ) || true
	@( test -f etc/init.d/$(LKMNAME) && ( \
	$(ABS_PRINT_info) "Installing startup script." ;\
	cp etc/init.d/$(LKMNAME) /etc/init.d/ ;\
	chmod 755 /etc/init.d/$(LKMNAME) ;\
	which chkconfig && chkconfig --add $(LKMNAME) ; \
	which update-rc.d && update-rc.d $(LKMNAME) defaults ; \
	$(ABS_PRINT_info) "Starting device." ; \
	/etc/init.d/$(LKMNAME) start ) ) || true


define forward-command
@$(ABS_PRINT_info) "Forwarding file $< to $@"
@mkdir -p $(@D)
@sed -e 's%MODULE_DESCRIPTION[ ]*[(]%MODULE_DESCRIPTION("$$Attr: app.name=$(APPNAME) $$ $$Attr: app.version=$(VERSION) $$ $$Attr: app.revision=$(REVISION) $$ $$Attr: build.mode=$(MODE) $$ $$Attr: build.opts=$(DEFINES) $$ $$Attr: build.date='`date +%Y-%m-%d.%H:%M:%S`' $$ $$Attr: build.host='`hostname`' $$ $$Attr: build.user=$(USER) $$ $$Attr: build.id=$(BUILDNUM) $$ \\n\\t\\t\" %g' $< > $@
endef
ALL_SRC_LKM_SRC=$(shell find src \( -name "*.c" -o -name "*.obj" \) $(patsubst %, -a -not -name %,$(DISABLE_SRC)))
ALL_LKM_SRC=$(patsubst src/%,$(OBJDIR)/%,$(shell find src \( -name "*.c" -o -name "*.obj" \) $(patsubst %, -a -not -name %,$(DISABLE_SRC))))
ALL_LKM_SRC+=$(patsubst $(EXT_MODSRC_DIR)/%,$(OBJDIR)/%,$(filter-out $(DISABLE_SRC),$(filter %.c %.obj,$(ARCHSRC_SRCFILES))))
LKMSRC=$(subst /$(LKMNAME).c,/$(LKMNAME)_main__.c,$(ALL_LKM_SRC))

$(ALL_LKM_SRC): $(ALL_PATCHED)

CFLAGS+=-I$(OBJDIR)
EXTRA_CFLAGS+=-I$(OBJDIR)

$(OBJDIR)/%.c: $(LKMSRCDIR)/%.c
	$(forward-command)

$(OBJDIR)/%.c: $(EXT_MODSRC_DIR)/%.c
	$(forward-command)

$(OBJDIR)/%.obj: $(LKMSRCDIR)/%.obj
	$(forward-command)
	
$(OBJDIR)/%.obj: $(EXT_MODSRC_DIR)/%.obj
	$(forward-command)

$(OBJDIR)/%.h: $(LKMSRCDIR)/%.h
	@mkdir -p $(@D)
	cp $< $@

$(OBJDIR)/%.h: $(EXT_MODSRC_DIR)/%.h
	@mkdir -p $(@D)
	cp $< $@
	
$(OBJDIR)/$(LKMNAME)_main__.c: $(OBJDIR)/$(LKMNAME).c
	$(forward-command)

LKMOBJ=$(patsubst $(OBJDIR)/%.obj,%.obj,$(patsubst $(OBJDIR)/%.c,%.o,$(LKMSRC)))
LKMH=$(patsubst src/%,$(OBJDIR)/%,$(shell find src -name "*.h"))
LKMH+=$(patsubst $(EXT_MODSRC_DIR)/%,$(OBJDIR)/%,$(filter %.h,$(ARCHSRC_SRCFILES)))

$(TRDIR)/include/$(APPNAME)/%: $(PRJROOT)/%/Makefile
	make -C $(^D)

$(OBJDIR)/Makefile: $(LKMSRC) $(LKMH)
	printf "\
INSTALL_MOD_DIR=$(APPNAME)\n\
obj-m:=$(LKMNAME).o\n\
$(LKMNAME)-objs:=$(LKMOBJ)\n\
EXTRA_CFLAGS+=-I$(MODROOT)/include -I$(MODROOT)/src $(EXTRA_CFLAGS) $(patsubst %,-D%,$(DEFINES)) -D_$(APPNAME)_$(MODNAME)_$(MODE)\n\
"> $@
