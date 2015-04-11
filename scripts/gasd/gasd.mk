SHELL = bash -o pipefail -exv




mkscript  := $(firstword $(MAKEFILE_LIST))
MkPref := $(shell basename $(mkscript) .mk)
ScriptDir := $(shell cd $(dir $(mkscript));pwd)
BaseDir   := $(shell cd $(ScriptDir);cd ..;pwd)

ifeq ($(shell [ -s $(ScriptDir)/cinc.mk ] && echo ok),ok)
include $(ScriptDir)/cinc.mk
endif

WorkDir   := $(shell pwd)/run

MatterDir := $(BaseDir)/matters

CheckCfg.dst :
	$(call CheckCommand,BASE)
	$(call CheckCommand,CFGFILE)

getmatter.dst : 
	mkdir -p $(WorkDir) || echo wau
	cd $(WorkDir);make -f $(ScriptDir)/mat.mk getmatter.dst
	$(markstep)

getscript.dst : CheckCfg.dst getmatter.dst 
	cp $(ScriptDir)/* $(WorkDir) || echo wau
	cp $$CFGFILE $(WorkDir) || echo wau
	#$(markstep)

run.dst : getscript.dst CheckCfg.dst
	cd $(WorkDir);for aa in ClcAssembly GetAllPnt SumFiles ; do \
		perl $(ScriptDir)/$(MkPref).pl $(WorkDir) $$CFGFILE $(WorkDir)/matter_name.txt $$BASE $$aa 1e8;\
		done

run1.dst : getscript.dst CheckCfg.dst
	cd $(WorkDir);for aa in ClcAssemblyNew GetAllPnt SumFiles ; do \
		perl $(ScriptDir)/$(MkPref).pl $(WorkDir) $$CFGFILE $(WorkDir)/matter_name.txt $$BASE $$aa 1e3;\
		done

ifndef SVNROOT
export SVNROOT=http://localhost:8080
endif

expdir := svn/root
$(MkPref).files := scripts/gasd/$(MkPref).mk scripts/gasd/$(MkPref).pl scripts/gasd/$(MkPref).cfg scripts/gasd/GasdCfgReader.pm
$(MkPref).files := $($(MkPref).files) scripts/gasd/lib/AnalyzeData.pm scripts/gasd/lib/ClcGasd.pm scripts/gasd/lib/RegMarch.pm 

$(MkPref).files := $($(MkPref).files) scripts/common/mat.mk scripts/common/cinc.mk

updatescript.dst :
	rm -rf $(expdir) || echo cannot remove
	mkdir -p $(MatterDir) || echo cannot make dir 
	mkdir -p $(WorkDir) || echo cannot make dir 
	svn co $$SVNROOT/$(expdir) $(expdir) > /dev/null
	for aa in $($(MkPref).files) ; do \
		bb=$$(basename $$aa) ;\
		cp $(expdir)/$$aa $(ScriptDir)/$$bb ;\
		chmod uog=rwx $(ScriptDir)/$$bb ;\
	done
	make -f $(ScriptDir)/mat.mk mat.updatescript.dst

exportscript.dst :
	rm -rf $(expdir) && mkdir -p $(expdir)
	svn co $$SVNROOT/$(expdir) $(expdir) > /dev/null
	for aa in $($(MkPref).files) ; do \
		bb=$$(basename $$aa) ;\
		cp $(ScriptDir)/$$bb $(expdir)/$$aa  ;\
	done
	make -f $(ScriptDir)/mat.mk mat.exportscript.dst

showdiff.dst : exportscript.dst
	$(call ShowDiff, $(expdir)/scripts)
	$(call ShowDiffF, $(expdir)/matters)

