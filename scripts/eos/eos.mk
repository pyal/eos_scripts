SHELL = bash -o pipefail -exv



export LANG=
mkscript  := $(firstword $(MAKEFILE_LIST))
MkName := $(shell basename $(mkscript))
MkPref := $(shell basename $(mkscript) .mk)
ScriptDir := $(shell cd $(dir $(mkscript));pwd)
WorkDir   := $(shell pwd)/run
BaseDir   := $(shell cd $(ScriptDir);cd ..;pwd)
UserName := $(shell whoami)
markstep = touch $(notdir $@)
RunCommand = bash -exvc ". $(ScriptDir)/$(MkPref).sh; $1"

SVNROOT=http://pyal-nb-w7.ld.yandex.ru:8080
MatterDir := $(BaseDir)/matters


CheckCommand = @perl -e ' die("Have to define $$ARGV[0]\n")  if (!defined($$ARGV[1])); ' $1 $$$1

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



expdir := svn/root
$(MkPref).files := scripts/eos/$(MkPref).mk scripts/eos/$(MkPref).pl scripts/eos/$(MkPref).cfg scripts/common/CfgReader.pm scripts/eos/EosMarch.pm
$(MkPref).files := $($(MkPref).files) scripts/common/mat.mk scripts/common/UrsCurve.pm

updatescript.dst :
	rm -rf $(expdir) || echo cannot remove
	svn co $(SVNROOT)/$(expdir) $(expdir) > /dev/null
	for aa in $($(MkPref).files) ; do \
		bb=$$(basename $$aa) ;\
		cp $(expdir)/$$aa $(ScriptDir)/$$bb ;\
		chmod uog=rwx $(ScriptDir)/$$bb ;\
	done
	make -f $(ScriptDir)/mat.mk mat.updatescript.dst

exportscript.dst :
	rm -rf $(expdir) && mkdir -p $(expdir)
	svn co $(SVNROOT)/$(expdir) $(expdir) > /dev/null
	for aa in $($(MkPref).files) ; do \
		bb=$$(basename $$aa) ;\
		cp $(ScriptDir)/$$bb $(expdir)/$$aa  ;\
	done
	make -f $(ScriptDir)/mat.mk mat.exportscript.dst

showdiff.dst : exportscript.dst
	cd $(expdir)/scripts; svn stat | grep -w M | awk '{print $$2}' | sort -u | xargs -n1 svn diff
	cd $(expdir)/matters; svn stat | grep -w M | awk '{print $$2}' | sort -u 


 