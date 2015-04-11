SHELL = bash -o pipefail -exv




mkscript  := $(firstword $(MAKEFILE_LIST))
MkPref := $(shell basename $(mkscript) .mk)
ScriptDir := $(shell cd $(dir $(mkscript));pwd)
BaseDir   := $(shell cd $(ScriptDir);cd ..;pwd)

ifeq ($(shell [ -s $(ScriptDir)/cinc.mk ] && echo ok),ok)
include $(ScriptDir)/cinc.mk
endif

MatterDir := $(BaseDir)/matters
MatterFiles := $(shell [ ! -s $(MatterDir)/matter_name.txt ] ||  bash -exvc ". $(ScriptDir)/$(MkPref).sh; GetExtFile $(MatterDir)/matter_name.txt cfg:spl:ispl ")
#MatterFiles := $(shell [ ! -s $(MatterDir)/matter_name.txt ] ||  $(RunCommand, GetExtFile $(MatterDir)/matter_name.txt cfg:spl:ispl ) && echo no matters...)
$(MkPref).binfiles := matter_name.txt time.24.prn $(MatterFiles)


getmatter.dst :
	#echo $(BaseDir) $(MatterDir) $($(MkPref).binfiles)
	CD=$$(pwd);cd $(MatterDir);cp -f $($(MkPref).binfiles) $$CD/ || echo ok

ifndef SVNROOT
export SVNROOT=http://localhost:8080
endif


expdir := svn/root

$(MkPref).files := scripts/common/$(MkPref).mk scripts/common/$(MkPref).sh scripts/common/cinc.mk


$(MkPref).updatescript.dst :
	mkdir -p $(MatterDir) || echo cannot make dir
	for aa in $($(MkPref).files) ; do \
		bb=$$(basename $$aa) ;\
		cp $(expdir)/$$aa $(ScriptDir)/$$bb ;\
		chmod uog=rwx $(ScriptDir)/$$bb ;\
	done
	for aa in matter_name.txt time.24.prn ; do \
		bb=$$(basename $$aa) ;\
		cp $(expdir)/matters/$$aa $(MatterDir)/$$bb ;\
	done
	. $(ScriptDir)/$(MkPref).sh;for aa in $$(GetExtFile $(MatterDir)/matter_name.txt cfg:spl:ispl) ; do \
		bb=$$(basename $$aa) ;\
		cp $(expdir)/matters/$$aa $(MatterDir)/$$bb ;\
	done
	mkdir -p $(MatterDir)/he; cp -rp $(expdir)/matters/he $(MatterDir)/

$(MkPref).exportscript.dst :
	for aa in $($(MkPref).files) ; do \
		bb=$$(basename $$aa) ;\
		cp $(ScriptDir)/$$bb $(expdir)/$$aa  ;\
	done
	for aa in $($(MkPref).binfiles) ; do \
		bb=$$(basename $$aa) ;\
		cp $(MatterDir)/$$bb $(expdir)/matters/$$aa  ;\
	done
	cp -rp $(MatterDir)/he $(MatterDir)/matters/

updatescript.dst :
	rm -rf $(expdir) || echo cannot remove
	svn co $(SVNROOT)/$(expdir) $(expdir) > /dev/null
	make -f $(ScriptDir)/$(MkPref).mk $(MkPref).updatescript.dst

exportscript.dst :
	rm -rf $(expdir) && mkdir -p $(expdir)
	svn co $(SVNROOT)/$(expdir) $(expdir) > /dev/null
	make -f $(ScriptDir)/$(MkPref).mk $(MkPref).exportscript.dst

showdiff.dst : exportscript.dst
	$(call ShowDiff, $(expdir)/scripts)
	$(call ShowDiffF, $(expdir)/matters)


