SHELL = bash -o pipefail -exv



export LANG=
mkscript  := $(firstword $(MAKEFILE_LIST))
MkPref := $(shell basename $(mkscript) .mk)
ScriptDir := $(shell cd $(dir $(mkscript));pwd)
BaseDir   := $(shell cd $(ScriptDir);cd ..;pwd)

WorkDir   := $(shell pwd)/run
MatterDir := $(BaseDir)/matters

ifeq ($(shell [ -s $(ScriptDir)/cinc.mk ] && echo ok),ok)
include $(ScriptDir)/cinc.mk
else
GITROOT=https://github.com/pyal/eos_scripts.git
gitdir:=git/eos_scripts
endif

CheckCfg.dst :
	$(call CheckCommand,BASE)
	$(call CheckCommand,CFGFILE)
	mkdir -p $(WorkDir) || echo wau

getmatter.dst :
	cd $(WorkDir);make -f $(ScriptDir)/mat.mk getmatter.dst
	$(markstep)

getscript.dst : getmatter.dst
	cp $(ScriptDir)/* $(WorkDir)  || echo WAU
	#$(markstep)

run.dst : getscript.dst CheckCfg.dst
	CfgDir=$$(cd $$(dirname $$CFGFILE);pwd) ;\
		cd $(WorkDir); perl $(ScriptDir)/$(MkPref).pl $(WorkDir) $$CfgDir/$(basename $$CFGFILE) matter_name.txt $$BASE $$RESULTDIR




$(MkPref).files := scripts/eos/$(MkPref).mk scripts/eos/$(MkPref).pl scripts/eos/$(MkPref).cfg scripts/common/CfgReader.pm scripts/eos/EosMarch.pm
$(MkPref).files := $($(MkPref).files) scripts/common/mat.mk scripts/common/UrsCurve.pm

updatescript.dst :
	rm -rf $(gitdir) || echo cannot remove
	git clone  $(GITROOT) $(gitdir) > /dev/null
	for aa in $($(MkPref).files) ; do \
		bb=$$(basename $$aa) ;\
		cp $(gitdir)/$$aa $(ScriptDir)/$$bb ;\
		chmod uog=rwx $(ScriptDir)/$$bb ;\
	done
	make -f $(ScriptDir)/mat.mk mat.updatescript.dst

exportscript.dst :
	rm -rf $(gitdir) && mkdir -p $(gitdir)
	git clone  $(GITROOT) $(gitdir) > /dev/null
	for aa in $($(MkPref).files) ; do \
		bb=$$(basename $$aa) ;\
		cp $(ScriptDir)/$$bb $(gitdir)/$$aa  ;\
	done
	make -f $(ScriptDir)/mat.mk mat.exportscript.dst

showdiff.dst : exportscript.dst
	$(call ShowDiff, $(gitdir)/scripts)
	$(call ShowDiffF, $(gitdir)/matters)


 