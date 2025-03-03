## 
## --------------------------------------------------------------------
## Docker utilities.
## --------------------------------------------------------------------
##  Enable easy cross build on same hardware architecture for an alternate
##  OS distribution without setting up a huge VM.
## Variables:
##  - DOCKER_WORKSPACE: workspace root dir inside the container ot use for the
##    build. Caution it shall be writeable for the uid/gid calling make, since
##    it is set from current user to ensure proper access to project source tree
##    that is bind into the container as 
##    $(DOCKER_WORKSPACE)/$(APPNAME)-$(VERSION).
##    Default is set to /tmp that is a quite standard place world writable.
## 
## Targets:
##  - docker[.<target>] <image>
##     call make from current place binded in the provided docker image.
DOCKER_CMD?=docker

ifneq ($(filter docker%,$(word 1,$(MAKECMDGOALS))),)
DOCKER_IMAGE:=$(word 2,$(MAKECMDGOALS))
ifeq ($(DOCKER_IMAGE),)
docker.%:
	@$(ABS_PRINT_error) "argument missing: need a docker image name."
	@$(ABS_PRINT_error) "   make docker[.<target>] <image>"

else
DOCKER_TARGET:=$(TARGET)
DOCKER_ARGS+=--rm --hostname $(shell hostname).$(subst /,.,$(DOCKER_IMAGE))
DOCKER_WORKSPACE:=/home/$(USER)
# preliminary command to create user env in the container.
DOCKER_CREATEUSERENV:=echo $(USER):x:$(shell id -u):$(shell id -g)::$(DOCKER_WORKSPACE):/bin/bash >> /etc/passwd && chown $(USER) $(DOCKER_WORKSPACE) && echo $(USER):*:18464:0:99999:7::: >> /etc/shadow
# let the dockerized build open ssh session as the user from the host.
DOCKER_ARGS+=-v $(HOME)/.ssh:$(DOCKER_WORKSPACE)/.ssh
DOCKER_WDIR:=$(DOCKER_WORKSPACE)/$(APPNAME)-$(VERSION)
DOCKER_ARGS+=-v $(PRJROOT):$(DOCKER_WDIR)

.PHONY: docker.%
docker.%:
	@$(ABS_PRINT_info) "Running build with target $* from docker image $(DOCKER_IMAGE)"
	@# the () are needed to avoid the quit of container at the end of execution of some commands.
	@$(DOCKER_CMD) run $(DOCKER_ARGS) $(DOCKER_IMAGE) bash -c "($(DOCKER_CREATEUSERENV) && su - $(USER) -c 'cd $(DOCKER_WDIR) && make $(patsubst docker.%,%,$@) $(MAKEARGS)')"

dockershell:
	@$(ABS_PRINT_info) "Starting shell from docker image $(DOCKER_IMAGE)"
	@$(DOCKER_CMD) run $(DOCKER_ARGS) -it $(DOCKER_IMAGE) bash -c "($(DOCKER_CREATEUSERENV) && su - $(USER))"

.PHONY: $(DOCKER_IMAGE)
$(DOCKER_IMAGE):
	@:

endif # if DOCKER_IMAGE
else
.PHONY: docker.%
docker.%:
	@$(ABS_PRINT_warning) "docker target ignored, should be used first to run build from docker image."
	@$(ABS_PRINT_warning) "   make docker[.<target>] <image>"

endif # docker as first target.

.PHONY: docker
docker: docker.all
