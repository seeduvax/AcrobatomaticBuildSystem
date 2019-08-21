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

EXTRA_SIMVERS:=$(patsubst %,$(TRDIR)/obj/%/Module.symvers,$(USELKMOD))
CFGFILES:=$(patsubst %,$(TRDIR)/%,$(shell find etc -name $(LKMNAME).conf -o -name $(LKMNAME)))

$(TRDIR)/etc/drast/%.conf: src/etc/drast/%.conf
	mkdir -p $(@D)
	cp $^ $@

$(TRDIR)/etc/init.d/%: src/etc/init.d/%
	mkdir -p $(@D)
	cp $^ $@
	chmod +x $@

all-impl:: $(OBJDIR)/Makefile $(PUBLISHED_HEADERS) $(CFGFILES)
	$(MAKE) -C $(KERNELDIR) M=$(OBJDIR) KBUILD_EXTRA_SYMBOLS="$(EXTRA_SIMVERS)" modules
	mkdir -p $(TRDIR)/lib/modules/
	cp $(TRDIR)/obj/$(MODNAME)/*.ko $(TRDIR)/lib/modules

install:: all
	@( test -x /etc/init.d/$(LKMNAME) && ( \
$(ABS_PRINT_info) "Stopping device $(LKMNAME) before install" ; \
/etc/init.d/$(LKMNAME) stop ) ) || true
	@$(MAKE) -C $(KERNELDIR) M=$(OBJDIR) INSTALL_MOD_DIR=drast modules_install
	@$(ABS_PRINT_info) "Running depmod..."
	@depmod -a
	@( test -f etc/drast/$(LKMNAME).conf -a ! -f /etc/drast/$(LKMNAME).conf && ( \
	$(ABS_PRINT_info) "Installing module configuration file..." ; \
	mkdir -p /etc/drast ; \
	cp etc/drast/$(LKMNAME).conf /etc/drast/ ; \
	chmod 644 /etc/drast/$(LKMNAME).conf ) ) || true
	@( test -f etc/init.d/$(LKMNAME) && ( \
	$(ABS_PRINT_info) "Installing startup script." ;\
	cp etc/init.d/$(LKMNAME) /etc/init.d/ ;\
	chmod 755 /etc/init.d/$(LKMNAME) ;\
	which chkconfig && chkconfig --add $(LKMNAME) ; \
	which update-rc.d && update-rc.d $(LKMNAME) defaults ; \
	$(ABS_PRINT_info) "Starting device." ; \
	/etc/init.d/$(LKMNAME) start ) ) || true


define forward-command
@$(ABS_PRINT_info) "Forwarding file $^ to $@"
@mkdir -p $(@D)
@sed -e 's/MODULE_DESCRIPTION[ ]*[(]/MODULE_DESCRIPTION("$$Attr: app.name=$(APPNAME) $$ $$Attr: app.version=$(VERSION) $$ $$Attr: app.revision=$(REVISION) $$ $$Attr: build.mode=$(MODE) $$ $$Attr: build.opts=$(DEFINES) $$Attr: build.date='`date +%Y-%m-%d.%H:%M:%S`' $$ $$Attr: build.host='`hostname`' $$ $$Attr: build.user=$(USER)' $$ $$Attr: build.id=$(BUILDNUM) $$ \\n\\t\\t\" /g' $^ > $@
endef

$(OBJDIR)/$(LKMNAME)_main__.c: src/$(LKMNAME).c
	$(forward-command)

$(OBJDIR)/%.c: src/%.c
	$(forward-command)

$(OBJDIR)/%.h: src/%.h
	mkdir -p $(@D)
	cp $^ $@

LKMSRC=$(subst /$(LKMNAME).c,/$(LKMNAME)_main__.c,$(patsubst src/%,$(OBJDIR)/%,$(shell find src -name "*.c" $(patsubst %, -a -not -name %,$(DISABLE_SRC)))))
LKMOBJ=$(patsubst $(OBJDIR)/%.c,%.o,$(LKMSRC))
LKMH=$(patsubst src/%,$(OBJDIR)/%,$(shell find src -name "*.h"))


$(TRDIR)/include/$(APPNAME)/%: $(PRJROOT)/%/Makefile
	make -C $(^D)

$(OBJDIR)/Makefile: $(LKMSRC) $(LKMH) $(patsubst %,$(TRDIR)/include/$(APPNAME)/%,$(USELKMOD))
	printf "\
INSTALL_MOD_DIR=drast\n\
obj-m:=$(LKMNAME).o\n\
$(LKMNAME)-objs:=$(LKMOBJ)\n\
EXTRA_CFLAGS+=-I$(MODROOT)/include -I$(MODROOT)/src $(EXTRA_CFLAGS) $(patsubst %,-D%,$(DEFINES)) -D_$(APPNAME)_$(MODNAME)_$(MODE)\n\
"> $@
