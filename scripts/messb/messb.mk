

export LANG=
mkscript  := $(firstword $(MAKEFILE_LIST))
MkName := $(shell basename $(mkscript))
MkPref := $(shell basename $(mkscript) .mk)
ScriptDir := $(shell cd $(dir $(mkscript));pwd)
BaseDir   := $(shell cd $(ScriptDir);cd ..;pwd)


ifeq ($(shell [ -s $(ScriptDir)/cinc.mk ] && echo ok),ok)
include $(ScriptDir)/cinc.mk
else
GITROOT=https://github.com/pyal/eos_scripts.git
gitdir:=git/eos_scripts
endif





data.dst :
	$(call RunCommand, MakeStep -5 5 301 data.1)
	$(call RunCommand, MakeLorentz 100 10 -2 0.3 1 data.1 data.2)
	$(call RunCommand, MakeLorentz 100 10  2 0.3 1 data.1 data.3)
	paste data.1 data.2 data.3 | awk '{print $$1, $$2 + $$3}' > data
	rm -f data.1 data.2 data.3
	#$(markstep)

clc.dst :
	#$(call RunCommand, MessbSimpleCfg data data.est data.fm)
	$(call RunCommand, MessbCfg data data.est data.fm)
	$(call RunCommand, RelaxCfg data data.est data.fm)
	#famessb data.fm /s
	famessb data.fm
	famessb data.fm /s

data1.dst :
	$(call RunCommand, MakeStep -5 5 301 data.1)
	$(call RunCommand, MakeLorentz 100 10 -2 0.3 1 data.1 data.2)
	$(call RunCommand, MakeLorentz 100 10  2 0.3 1 data.1 data.3)
	paste data.1 data.2 data.3 | awk '{print $$1, $$2 + $$3}' > data
	rm -f data.1 data.2 data.3

clc1.dst :
	#$(call RunCommand, MessbSimpleCfg data data.est data.fm)
	$(call RunCommand, MessbCfgLast data data.est data.fm)
	#$(call RunCommand, RelaxCfg data data.est data.fm)
	#famessb data.fm /s
	famessb data.fm
	famessb data.fm /s





ScriptFiles := messb/$(MkPref).mk messb/$(MkPref).sh 


updatescript.dst :
	rm -rf $(gitdir) && mkdir -p $(gitdir);
	git clone  $(GITROOT) $(gitdir) > NULL
	for aa in $(ScriptFiles) ; do \
		bb=$$(basename $$aa) ;\
		cp $(gitdir)/$$aa $(ScriptDir)/$$bb ;\
	done
	rm -rf $(gitdir) NULL
	chmod uog=rwx $(ScriptDir)/*



exportscript.dst :
ifndef EXPAND
	rm -rf $(gitdir)
endif
	mkdir -p $(gitdir)
	git clone  $(GITROOT) $(gitdir) > NULL
	for aa in $(ScriptFiles) ; do \
		bb=$$(basename $$aa) ;\
		cp $(ScriptDir)/$$bb $(gitdir)/$$aa || echo leaving file $$bb;\
	done
	rm -f NULL

showdiff.dst : exportscript.dst
	$(call ShowDiff, $(gitdir)/scripts)
	$(call ShowDiffF, $(gitdir)/matters)
