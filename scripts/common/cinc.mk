SHELL = bash -o pipefail -exv



export LANG=
MkName := $(shell basename $(mkscript))

UserName := $(shell whoami)
markstep = touch $(notdir $@)

RunCommand = bash -exvc ". $(ScriptDir)/$(MkPref).sh; $1"
CheckCommand = @perl -e ' die("Have to define $$ARGV[0]\n")  if (!defined($$ARGV[1])); ' $1 $$$1 

ShowDiff = cd $1;(svn stat | grep -w M | awk '{print $$2}' | gsort -u | sed 's/\\/\//g' | xargs -n1 svn diff ) || echo were errors
ShowDiffF = cd $1;(svn stat | grep -w M | awk '{print $$2}' | gsort -u | sed 's/\\/\//g' ) || echo were errors



#mkscript  := $(firstword $(MAKEFILE_LIST))
#MkPref := $(shell basename $(mkscript) .mk)
#ScriptDir := $(shell cd $(dir $(mkscript));pwd)
#BaseDir   := $(shell cd $(ScriptDir);cd ..;pwd)
#ifeq ($(shell [ -s $(ScriptDir)/cinc.mk ] && echo ok),ok)
#include $(ScriptDir)/cinc.mk
#endif

#ifndef SVNROOT
#export SVNROOT=http://localhost:8080
#endif

