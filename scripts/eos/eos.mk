SHELL = bash -o pipefail -exv



export LANG=
mkscript  := $(firstword $(MAKEFILE_LIST))
MkPref := $(shell basename $(mkscript) .mk)
ScriptDir := $(shell cd $(dir $(mkscript));pwd)
BaseDir   := $(shell cd $(ScriptDir);cd ..;pwd)

#WorkDir   := $(shell pwd)/run
WorkDir   := $(ScriptDir)/run
MatterDir := $(BaseDir)/matters

VENV := $(shell cd ~;pwd)/work/venv
PYTHON := $(VENV)/bin/python
EXPYAML := $(shell echo $${EXPYAML:-$(ScriptDir)/eos.exp.yaml})
EXPCOL := $(shell echo $${EXPCOL:-"''"})

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
# optional RESULTDIR - where to write results

CheckDescription.dst :
	$(call CheckCommand,CFGFILE)
	mkdir -p $(WorkDir) || echo wau

getmatter.dst :
	cd $(WorkDir);make -f $(ScriptDir)/mat.mk getmatter.dst
	$(markstep)

getscript.dst : getmatter.dst
	cp $(ScriptDir)/* $(WorkDir)  || echo WAU
	#$(markstep)

run.dst : CheckCfg.dst getscript.dst 
	CfgDir=$$(cd $$(dirname $$CFGFILE);pwd) ;\
		cd $(WorkDir);$(call RunCommand,SingleJob $$CfgDir/$$(basename $$CFGFILE) matter_name.txt $$BASE $$RESULTDIR)
		#cd $(WorkDir); perl $(ScriptDir)/$(MkPref).pl $(WorkDir) $$CfgDir/$$(basename $$CFGFILE) matter_name.txt $$BASE $$RESULTDIR

multi.dst : CheckDescription.dst getscript.dst
	CfgDir=$$(cd $$(dirname $$CFGFILE);pwd) ;\
		cd $(WorkDir);$(call RunCommand,MultiJob $$CfgDir/$(basename $$CFGFILE) matter_name.txt $$CfgDir)

dat.dst : CheckDescription.dst
	$(call RunCommand,ShowDat $$CFGFILE)

buildvenv.dst:
	#brew install python # to get pip
	#pip install virtualenv
	virtualenv $(VENV)
	$(VENV)/bin/pip install PyYAML

getexp.dst:
	$(call CheckCommand,EXPNAME)
	$(PYTHON) $(ScriptDir)/exp_yaml.py $(EXPYAML)  $(EXPNAME)  "$(EXPCOL)" exp.$(EXPNAME)

getexpc.dst:
	$(call CheckCommand,EXPNAME)
	$(PYTHON) $(ScriptDir)/exp_yaml.py $(EXPYAML)  $(EXPNAME)  "$(EXPCOL)" /dev/stdout | sed 's| |,|g' > expc.$(EXPNAME)

showexp.dst:
	$(PYTHON) $(ScriptDir)/exp_yaml.py -s $(EXPYAML) "fake"  "fake" "fake"

$(MkPref).files := scripts/eos/$(MkPref).mk scripts/eos/$(MkPref).pl scripts/eos/$(MkPref).cfg scripts/eos/$(MkPref).sh 
$(MkPref).files := $($(MkPref).files) scripts/common/CfgReader.pm scripts/eos/EosMarch.pm scripts/eos/ivl.mk scripts/eos/ivl.sh 
$(MkPref).files := $($(MkPref).files) scripts/eos/exp_yaml.py scripts/eos/eos.model.yaml scripts/eos/eos.exp.yaml scripts/eos/h2.model.yaml scripts/eos/h2.depricated.yaml

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


 