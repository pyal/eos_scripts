
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


DataDir:=$(BaseDir)/data
WorkDir:=$(shell pwd)

decode.dst :
	rm -f sum.dat
	cd $(DataDir);for aa in $$(ls alpha*) ; do \
		bb=$$(basename $$aa .dat  | sed 's/alpha_//' | sed 's/_/-/'); \
		echo bb $$bb ;\
		cat $$aa | awk -v n=$$bb 'NR>2{print 10**$$1"\t"10**$$2"\t"n}' >>$(WorkDir)/sum.dat ; \
	done
	cat sum.dat | gsort +2g -1 +0g | sed 's/\0x0D\0x0D/\0x0D/g' > sum.da
	$(markstep)

decode1.dst :
	cd $(DataDir);for aa in $$(ls alpha*) ; do \
		cp $$aa $(WorkDir)/$$aa.enc ; \
		echo $$(cat $(WorkDir)/$$aa.enc | awk 'BEGIN{n=-100000}{if(NR>2 && n<$$1) n=$$1}END{print n}') > $(WorkDir)/max;\
		echo $$(cat $(WorkDir)/$$aa.enc | awk 'BEGIN{n= 100000}{if(NR>2 && n>$$1) n=$$1}END{print n}') > $(WorkDir)/min ;\
		echo min max $$(cat $(WorkDir)/min $(WorkDir)/max );\
	done
	echo min max $$(cat min max )
	awk -v min=$$(cat min) -v max=$$(cat max) -v num=100 'BEGIN{for(i=0;i<num;i++) print min+(max-min)/(num-1)*i}' >base
	rm -f sum.dat min max
	for aa in $$(ls alpha*) ; do \
		bb=$$(basename $$aa .dat.enc  | sed 's/alpha_//' | sed 's/_/-/'); \
		set1grph.exe  base $$aa step  /i /a /e ;\
		cat step | awk -v n=$$bb 'NR>2{print 10**$$1"\t"n"\t"10**$$2}' >>sum.dat ; \
	done
	#cat sum.dat | gsort +0g +1g | sed 's/\0x0D\0x0D/\0x0D/g' > sum.da
	#rm -f base
	$(markstep)

adddat.dst : decode1.dst
	cp sum.dat sum.da1
	set1grph.exe  base alpha_3e_2.dat.enc f3_2  /i /e /a || echo bad1
	set1grph.exe  base alpha_1e_0.dat.enc f1_0  /i /e /a || echo bad2
	$(call RunCommand, Sum2Files f3_2 2 f1_0 1 1e_1.base )
	$(call RunCommand, Sum2Files f3_2 1 f1_0 2 3e_1.base)
	cat 1e_1.base | awk -v n=1e-1  '{print 10**$$1"\t"n"\t"10**$$2}' >>sum.da1
	cat 3e_1.base | awk -v n=3e-1  '{print 10**$$1"\t"n"\t"10**$$2}' >>sum.da1
	cat sum.da1 | gsort +0g +1g | sed 's/\0x0D\0x0D/\0x0D/g' > sum.da

splgen.dst : decode1.dst
	$(call RunCommand, Make2DSpline sum.da)
	$(markstep)

PntDir:=/cygdrive/h/he/experiment

getpnt.dst :
	echo ExpName MaxDens MaxTemp MaxPres > $(DataDir)/pnt.dat
	cd $(PntDir);for aa in $$(ls -d he*); do \
		bb=$$(ls $$aa/model) ;\
		. $(ScriptDir)/$(MkPref).sh ;\
		echo $$aa $$(FindMax $$aa/model/$${bb}/$${bb}_clc.Density 5) $$(FindMax $$aa/model/$${bb}/$${bb}_clc.Temperature 3) $$(FindMax $$aa/model/$${bb}/$${bb}_clc.Pressure 5)  >> $(DataDir)/pnt.dat ;\
	done
	$(markstep)

clcpnt.dst : getpnt.dst splgen.dst
	#$(call RunCommand, ClcCond $(DataDir)/pnt.dat)
	cat $(WorkDir)/expcond.dat | sed 's/\0x0D//g' | perl $(ScriptDir)/roepke_cond.pl > $(WorkDir)/expcond.dat.roepke





testspl.dst :
	$(call RunCommand, TestSpl 1000 33800 20 3e-7 1e-0 14)











ScriptFiles := eval_exp/$(MkPref).mk eval_exp/$(MkPref).sh eval_exp/he_roepke_cond.pl eval_exp/$(MkPref).tgz


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
	cd $(DataDir);gtar -czf $(ScriptDir)/$(MkPref).tgz alpha* roepke.dat pnt.dat
	for aa in $(ScriptFiles) ; do \
		bb=$$(basename $$aa) ;\
		cp $(ScriptDir)/$$bb $(gitdir)/$$aa || echo leaving file $$bb;\
	done
	rm -f $(ScriptDir)/$(MkPref).tgz NULL

showdiff.dst : exportscript.dst
	$(call ShowDiff, $(gitdir)/scripts)
	$(call ShowDiffF, $(gitdir)/matters)
