

MVNTARGET:=$(TRDIR)/target

$(MVNTARGET)/.abs:
	@mkdir -p $(@D)
	@ln -sf $(@D) target
	@mvn versions:set -DnewVersion=$(VERSION)
	@touch $@


all-impl:: $(MVNTARGET)/.abs
	mvn jar:jar

test:: $(MVNTARGET)/.abs
	mvn verify


clean::
	mvn clean
	rm target
