## 
## --------------------------------------------------------------------
## typescript module specific services
## 
## typescript services variables:
## 
##  - NODE: node interpreter run command, default setting is searching for node to be present on the system.
##          If node is not present on the system please export this variable.
##  - TSC: path to typescript compiler main file (usually named tsc in the bin folder of the official github release).
##  - TS_MODULE_TYPE: how to resolve modules: use amd for web development and commonjs for nodejs development.
##  - TS_ESLIB: version of ES standard, default is es5.
NODE?=$(shell which node 2>/dev/null)
ifeq ($(NODE),)
$(call abs_error,Unable to find a valid node interpreter, please set NODE environment variable)
endif
ifeq ($(TSC),)
$(call abs_error,Unable to find a valid typescript compiler, please set TSC environment variable)
endif

$(call abs_debug,Using NODE=$(NODE))
$(call abs_debug,Using TSC=$(TSC))

TS_ESLIB?=ES5

TS_LIBS?=$(TS_ESLIB),DOM,ScriptHost

TS_MODULE_TYPE?=commonjs

# scripts .ts/.tsx directory
TS_SRCDIR=src

# Typescript modules are really weird and appears to not support directory structures so put everything under app dir.

# JS output directory
JS_PATH=$(TRDIR)/etc/www/js
JS_MODPATH=$(TRDIR)/etc/www/js/$(MODNAME)
# TS declarations output directory
TSD_PATH=$(TRDIR)/lib/typescript
TSD_MODPATH=$(TRDIR)/lib/typescript/$(MODNAME)

# Setup TS type roots
TS_TYPE_ROOTS?=$(TSD_PATH)
TS_EXT_TYPE_ROOTS=$(patsubst %/import.mk,%/lib/typescript,$(EXTLIBMAKES))

$(call abs_debug,Using TS_EXT_TYPE_ROOTS=$(TS_EXT_TYPE_ROOTS))

TS_TYPE_ROOTS+=$(wildcard $(TS_EXT_TYPE_ROOTS)/.)

TS_COMMA:=,
TS_EMPTY:=
TS_SPACE:=$(TS_EMPTY) $(TS_EMPTY)
TS_TYPE_ROOTS2=$(subst $(TS_SPACE),$(TS_COMMA),$(TS_TYPE_ROOTS))

$(call abs_debug,Using TS_TYPE_ROOTS=$(TS_TYPE_ROOTS2))

#Nice we'got a big problem: TSC cannot deal with multi-layer directories
TSCFLAGS=--lib $(TS_LIBS) --baseUrl $(TS_SRCDIR) --module $(TS_MODULE_TYPE) --typeRoots $(TS_TYPE_ROOTS2)
TSXCFLAGS=--lib $(TS_LIBS) --baseUrl $(TS_SRCDIR) --module $(TS_MODULE_TYPE) --typeRoots $(TS_TYPE_ROOTS2) --jsx react --esModuleInterop

#TS_SRC=$(wildcard $(TS_SRCDIR)/*.ts)
#TSX_SRC=$(wildcard $(TS_SRCDIR)/*.tsx)

TS_SRC=$(filter $(TS_SRCDIR)/%.ts,$(SRCFILES))
TSX_SRC=$(filter $(TS_SRCDIR)/%.tsx,$(SRCFILES))

TS_OBJS:=$(patsubst $(TS_SRCDIR)/%.ts,$(JS_MODPATH)/%.js,$(TS_SRC))
TSD_OBJS:=$(patsubst $(TS_SRCDIR)/%.ts,$(TSD_MODPATH)/%.d.ts,$(TS_SRC))
TSX_OBJS:=$(patsubst $(TS_SRCDIR)/%.tsx,$(JS_MODPATH)/%.js,$(TSX_SRC))
TSXD_OBJS:=$(patsubst $(TS_SRCDIR)/%.tsx,$(TSD_MODPATH)/%.d.ts,$(TSX_SRC))

$(call abs_debug,Src: $(TS_SRC) $(TSX_SRC))
$(call abs_debug,Objs: $(TS_OBJS) $(TSD_OBJS) $(TSX_OBJS) $(TSXD_OBJS))

TARGETFILES+=$(TSD_OBJS) $(TSXD_OBJS) $(TS_OBJS) $(TSX_OBJS)
$(TARGETFILES): $(TSD_MODPATH)/index.d.ts

$(TSD_MODPATH)/index.d.ts:
	@mkdir -p $(TSD_MODPATH)
	@echo "" > $(TSD_MODPATH)/index.d.ts

$(JS_MODPATH)/%.js: $(TS_SRCDIR)/%.ts
	@$(ABS_PRINT_info) "$< ---> $@"
	@mkdir -p $(@D)
	@$(NODE) $(TSC) $(TSCFLAGS) --outDir $(@D) $<

$(JS_MODPATH)/%.js: $(TS_SRCDIR)/%.tsx
	@$(ABS_PRINT_info) "$< ---> $@"
	@mkdir -p $(@D)
	@$(NODE) $(TSC) $(TSXCFLAGS) --outDir $(@D) $<

$(TSD_MODPATH)/%.d.ts: $(TS_SRCDIR)/%.ts
	@$(ABS_PRINT_info) "$< ---> $@"
	@mkdir -p $(@D)
	@$(NODE) $(TSC) $(TSCFLAGS) --declaration --emitDeclarationOnly --outDir $(@D) $<

$(TSD_MODPATH)/%.d.ts: $(TS_SRCDIR)/%.tsx
	@$(ABS_PRINT_info) "$< ---> $@"
	@mkdir -p $(@D)
	@$(NODE) $(TSC) $(TSXCFLAGS) --declaration --emitDeclarationOnly --outDir $(@D) $<

$(TSD_MODPATH)/%.d.ts: $(TSD_MODPATH)/index.d.ts
$(JS_MODPATH)/%.js: $(TSD_MODPATH)/index.d.ts

# run application
run:: all
	@NODE_PATH="$(JS_PATH):$(JS_MODPATH)" LD_LIBRARY_PATH="$(LIB_PATH)" $(NODE) $(JS_MODPATH)/main.js $(RUNARGS)
