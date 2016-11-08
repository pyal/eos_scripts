SHELL = bash -o pipefail -exv



export LANG=
mkscript  := $(firstword $(MAKEFILE_LIST))
MkName := $(shell basename $(mkscript))
MkPref := $(shell basename $(mkscript) .mk)
ScriptDir := $(shell cd $(dir $(mkscript));pwd)
WorkDir   := $(shell pwd)/ivl
BaseDir   := $(shell cd $(ScriptDir);cd ..;pwd)
UserName := $(shell whoami)
markstep = touch $(notdir $@)
RunCommand = bash -exvc ". $(ScriptDir)/$(MkPref).sh; $1"

SVNROOT=http://pyal-nb-w7.ld.yandex.ru:8080
MatterDir := $(BaseDir)/matters

IVLDAT := /cygdrive/c/Pyal/Work/Ficp/arc/extra_data/ivl/pb


CheckCommand = @perl -e ' die("Have to define $$ARGV[0]\n")  if (!defined($$ARGV[1])); ' $1 $$$1

CheckCfg.dst :
	#$(call CheckCommand,BASE)
	#$(call CheckCommand,CFGFILE)
	mkdir -p $(WorkDir) || echo wau

# P(V,T)
isot.dst : CheckCfg.dst
	$(call CheckCommand,TEMP)
	cd $(WorkDir);$(call RunCommand, IsoT $(TEMP) temper.in volume.in pressu.tab $(IVLDAT) 0 isot.p.$(TEMP) )
	cd $(WorkDir);$(call RunCommand, IsoT $(TEMP) temper.in volume.in energy.tab $(IVLDAT) 0 isot.e.$(TEMP) )
	cd $(WorkDir);$(call RunCommand, IsoT $(TEMP) temper.in volume.in physid.tab $(IVLDAT) 1 isot.id.$(TEMP) )

bnd.dst : CheckCfg.dst
	cd $(WorkDir);$(call RunCommand, GetBnd temper.in volume.in physid.tab $(IVLDAT) 4 5 0 bnd45 )
	cd $(WorkDir);$(call RunCommand, GetBnd temper.in volume.in physid.tab $(IVLDAT) 3 4 1 bnd34 )
	cd $(WorkDir);$(call RunCommand, DecodeBnd temper.in volume.in pressu.tab $(IVLDAT) bnd45 bin.p.low)
	cd $(WorkDir);$(call RunCommand, DecodeBnd temper.in volume.in pressu.tab $(IVLDAT) bnd34 bin.p.hgh)
	cd $(WorkDir);$(call RunCommand, DecodeBnd temper.in volume.in energy.tab $(IVLDAT) bnd45 bin.e.low)

spl.dst :CheckCfg.dst
	cd $(WorkDir);rm -f spl.cfg;$(call RunCommand, MakeSplCfg $$(pwd)/bin.e.low 0 2 $$(pwd)/t2e_low.spl t2e_low 1e-5 spl.cfg )
	cd $(WorkDir);$(call RunCommand, MakeSplCfg $$(pwd)/bin.e.low 0 1 $$(pwd)/t2r_low.spl t2r_low 1e-6 spl.cfg )
	cd $(WorkDir);$(call RunCommand, MakeSplCfg $$(pwd)/bin.p.hgh 0 1 $$(pwd)/t2r_hgh.spl t2r_hgh 5e-2 spl.cfg )
	cd $(WorkDir);CFGFILE=spl.cfg BASE=t2e_low make -f $(ScriptDir)/eos.mk run.dst
	cd $(WorkDir);CFGFILE=spl.cfg BASE=t2r_low make -f $(ScriptDir)/eos.mk run.dst
	cd $(WorkDir);CFGFILE=spl.cfg BASE=t2r_hgh make -f $(ScriptDir)/eos.mk run.dst
	#cd $(WorkDir);rm -f $$(pwd)/t2e_low.spl.xy $$(pwd)/t2r_low.spl.xy $$(pwd)/t2r_hgh.spl.xy 

sum.dst : spl.dst #CheckCfg.dst
	rm -f pb.gasd.bin
	for aa in t2r_low.spl t2r_hgh.spl t2e_low.spl ; do echo $$aa >>pb.gasd.bin;awk 'NR>2' $(WorkDir)/$$aa >>pb.gasd.bin;done


expdir := svn/root
$(MkPref).files := scripts/eos/$(MkPref).mk scripts/eos/$(MkPref).sh
#$(MkPref).files := $($(MkPref).files) scripts/common/mat.mk scripts/common/UrsCurve.pm

updatescript.dst :
	rm -rf $(expdir) || echo cannot remove
	svn co $(SVNROOT)/$(expdir) $(expdir) > /dev/null
	for aa in $($(MkPref).files) ; do \
		bb=$$(basename $$aa) ;\
		cp $(expdir)/$$aa $(ScriptDir)/$$bb ;\
		chmod uog=rwx $(ScriptDir)/$$bb ;\
	done

exportscript.dst :
	rm -rf $(expdir) && mkdir -p $(expdir)
	svn co $(SVNROOT)/$(expdir) $(expdir) > /dev/null
	for aa in $($(MkPref).files) ; do \
		bb=$$(basename $$aa) ;\
		cp $(ScriptDir)/$$bb $(expdir)/$$aa  ;\
	done

showdiff.dst : exportscript.dst
	cd $(expdir)/scripts; svn stat | grep -w M | awk '{print $$2}' | sort -u | xargs -n1 svn diff


 