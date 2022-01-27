all: $(patsubst %,$(BUILDROOT)/.abs/%.mk,vars $(HOSTNAME)-vars)

$(BUILDROOT)/.abs/vars.mk:
	@mkdir -p $(@D)
	@echo "# generated file, do not edit" > $@
	@svn info > /dev/null 2>&1 && echo "ABS_SCM_TYPE:=svn" >> $@|| :
	@git status > /dev/null 2>&1 && echo "ABS_SCM_TYPE:=git" >> $@ || :
	@echo "ABS_VARS_GEN_FLAG:=true" >> $@

$(BUILDROOT)/.abs/$(HOSTNAME)-vars.mk:
	mkdir -p $(@D)
	@echo "# generated file, do not edit" > $@
	@LSBRCMD=`which lsb_release 2>/dev/null` ;\
	release="" ;\
	distId="" ;\
	if [ "$$LSBRCMD" != "" ] ;\
	then \
		distId=`$$LSBRCMD -is | sed 's/ /_/g'`;\
	fi ;\
	if [ ! "$$distId" = "" ] ;\
	then \
		release=`$$LSBRCMD -rs` ;\
		mrelease=`echo $$release | cut -f 1 -d '.'` ;\
	else \
		distId=`uname -o | sed 's:[/ ]:_:g'` ;\
	fi ;\
	case "$$distId"_"$$release" in \
		_) echo "SYSNAME?=UnknownArch" >> $@ ;;\
		Msys*|Cygwin*) echo "Windows";;\
		*) echo "SYSNAME?=$$distId"_"$$mrelease" >> $@;;\
	esac
	@echo "HWNAME?="`uname -m` >> $@

