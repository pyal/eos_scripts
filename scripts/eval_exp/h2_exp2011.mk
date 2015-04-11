

export LANG=
mkscript  := $(firstword $(MAKEFILE_LIST))
MkName := $(shell basename $(mkscript))
MkPref := $(shell basename $(mkscript) .mk)
ScriptDir := $(shell cd $(dir $(mkscript));pwd)
BaseDir   := $(shell cd $(ScriptDir);cd ..;pwd)
UserName := $(shell whoami)
markstep = touch $(notdir $@)
SVNADDR:=https://ppp_pyal:8443/svn/

RunCommand = bash -exvc ". $(ScriptDir)/$(MkPref).sh;LANG= $1"


RESDIR:=$(BaseDir)/results
EXP = $(shell cat $(BaseDir)/lst | grep -v _mol )

ExpDir:=g:/Pyal/dbPaper/experiment/res_clc/the

#GASDCLCNAME:=$(BaseDir)/h2gasd_clc
#PARAMSNAME:=h2params
GASDCLCNAME:=$(BaseDir)/h2gasd_clc_5_2
PARAMSNAME:=h2params_5_2
#MOL=_mol


start.dst :
	rm -f $(PARAMSNAME).*

$(EXP:=.maketable.dst) : %.maketable.dst : start.dst
	$(call RunCommand, GetParams $(GASDCLCNAME) $* $(PARAMSNAME).$*)
	$(call RunCommand, AddMeanT $(ExpDir)/$*/$*_clc.Temperature 1 50 $(PARAMSNAME).$*)
	$(call RunCommand, AddMeanT $(ExpDir)/$*/$*_clc.Temperature 3 50 $(PARAMSNAME).$*)

	$(call RunCommand, AddMeanT $(ExpDir)/$*$(MOL)/$*$(MOL)_clc.Temperature 1 50 $(PARAMSNAME).$*)
	$(call RunCommand, AddMeanT $(ExpDir)/$*$(MOL)/$*$(MOL)_clc.Temperature 3 50 $(PARAMSNAME).$*)

	$(call RunCommand, AddMeanT $(ExpDir)/$*/$*_clc.Pressure 2 50 $(PARAMSNAME).$*)
	$(call RunCommand, AddMeanT $(ExpDir)/$*/$*_clc.Density 2 50 $(PARAMSNAME).$*)

	$(call RunCommand, AddMeanT $(ExpDir)/$*$(MOL)/$*$(MOL)_clc.Density 1 50 $(PARAMSNAME).$*)
	$(call RunCommand, AddMeanT $(ExpDir)/$*$(MOL)/$*$(MOL)_clc.Density 3 50 $(PARAMSNAME).$*)
	gawk 'BEGIN{print ""}' >> $(PARAMSNAME).$*



mkparams.dst : $(EXP:=.maketable.dst)
	gawk 'BEGIN{print "Exp\tSt_u\tSt_l\tAl_l\tSt_l\tH2_p\tH2_l\tLiF_l\tSap_l\tTst\tTlif\tTstMol\tTlifMol\tPMetCent\tDensMetCent\tDencMolSt\tDencMolLiF"}'  > $(PARAMSNAME)
	cat $(PARAMSNAME).* | sort >> $(PARAMSNAME)
	rm -f $(PARAMSNAME).*

addexpt.dst : mkparams.dst
	$(call RunCommand, SetExpT $(PARAMSNAME) $(PARAMSNAME).exp )

clcdis.dst : mkparams.dst
	$(call RunCommand, ClcDis $(PARAMSNAME) 16 12 14 $(PARAMSNAME).disdeg1) #dis dep from final pres
	$(call RunCommand, ClcDis $(PARAMSNAME) 16 12 6 $(PARAMSNAME).disdeg)	#dis dep from start pres


save.dst : clcdis.dst addexpt.dst
	rm -rf $(RESDIR)/tmp ; mkdir -p $(RESDIR)/tmp
	cp $(PARAMSNAME) $(PARAMSNAME).exp $(PARAMSNAME).disdeg1 $(PARAMSNAME).disdeg $(GASDCLCNAME) $(RESDIR)/tmp/
	#cd $(ExpDir);rar a exp_clc.rar $(EXP) $$(cat $(EXP)| xargs -n1 echo gawk '{$1"_mol"}'); mv exp_clc.rar $(RESDIR)/tmp/
	cd $(ExpDir);rar a exp_clc.rar $(EXP) ; mv exp_clc.rar $(RESDIR)/tmp/
	cd $(RESDIR)/tmp/;rar a ../$(PARAMSNAME).rar *
	rm -rf $(RESDIR)/tmp


#RESULTCFG:=exp.h2.5.2
#PARAMSNAME:=params.5.2
startcfg.dst :
	rm -f $(RESULTCFG).*

$(EXP:=.makecfg.dst) : %.makecfg.dst : start.dst
	$(call RunCommand, SetParams  $(PARAMSNAME) $* $(RESULTCFG).$*)



makecfg.dst : $(EXP:=.makecfg.dst)
	cat $(RESULTCFG).* > $(RESULTCFG)
	rm -f $(RESULTCFG).*









expdir=root/scripts
ScriptFiles := eval_exp/$(MkPref).mk eval_exp/$(MkPref).sh


updatescript.dst :
	rm -rf $(expdir) && mkdir -p $(expdir);
	svn co $(SVNADDR)/$(expdir) $(expdir) > NULL
	for aa in $(ScriptFiles) ; do \
		bb=$$(basename $$aa) ;\
		cp $(expdir)/$$aa $(ScriptDir)/$$bb ;\
	done
	rm -rf $(expdir) NULL
	chmod uog=rwx $(ScriptDir)/*



exportscript.dst :
ifndef EXPAND
	rm -rf $(expdir)
endif
	mkdir -p $(expdir)
	svn co $(SVNADDR)/$(expdir) $(expdir) > NULL
	for aa in $(ScriptFiles) ; do \
		bb=$$(basename $$aa) ;\
		cp $(ScriptDir)/$$bb $(expdir)/$$aa || echo leaving file $$bb;\
	done
	rm -f NULL

showdiff.dst : exportscript.dst
	cd $(expdir); svn stat | grep -w M | gawk '{print $$2}' | sed 's/\\/\//g' | xargs -n1 svn diff


commit.dst :
	cd $(expdir); svn ci -m "minor change"
