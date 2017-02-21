SHELL = bash -o pipefail -exv



export LANG=
MkName := $(shell basename $(mkscript))

UserName := $(shell whoami)
markstep = touch $(notdir $@)

# cygwin only
#RunCommand = bash -exvc -o igncr ". $(ScriptDir)/$(MkPref).sh; $1"
# mac
RunCommand = bash -exvc ". $(ScriptDir)/$(MkPref).sh; $1"
CheckCommand = @perl -e ' die("Have to define $$ARGV[0]\n")  if (!defined($$ARGV[1])); ' $1 $$$1 

ShowDiff = cd $1;git diff
ShowDiffF = cd $1; (git status | grep modified | gawk '{print $$3}'  | gsort -u | sed 's/\\/\//g' ) || echo were errors

ifndef GITROOT
GITROOT=https://github.com/pyal/eos_scripts.git
endif
gitdir:=git/eos_scripts

#mkscript  := $(firstword $(MAKEFILE_LIST))
#MkPref := $(shell basename $(mkscript) .mk)
#ScriptDir := $(shell cd $(dir $(mkscript));pwd)
#BaseDir   := $(shell cd $(ScriptDir);cd ..;pwd)

#ifeq ($(shell [ -s $(ScriptDir)/cinc.mk ] && echo ok),ok)
#include $(ScriptDir)/cinc.mk
#else
#GITROOT=https://github.com/pyal/eos_scripts.git
#gitdir:=git/eos_scripts
#endif
#

#showdiff.dst : exportscript.dst
#	$(call ShowDiff, $(gitdir)/scripts)
#	$(call ShowDiffF, $(gitdir)/matters)
