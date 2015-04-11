
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
RunUrs = bash -exvc ". $(ScriptDir)/urs_curve.sh;LANG= $1"


mkdat.dst :
	$(call RunCommand, ColdFull lif.cold)
	$(call RunCommand, MkHugPres lif.hugp)
	$(call RunCommand, MkHugTemp lif.hugt)


apr.dst :
	#$(call RunCommand, MakeConfig lif.apr lif.cold X TVar)
	#$(call RunCommand, MakeConfig lif.apr lif.cold.log log\(X\) TVar)
	#$(call RunCommand, MakeConfig lif.apr lif.cold.pnt.log log\(X\) TVar)
	$(call RunCommand, MakeConfig lif.apr lif.cold.pnt.ls log\(X\) Reader.T)
	famessb.exe lif.apr /s

hug.dst :
	$(call RunCommand, MakeConfig lif.apr lif.cold.pnt.ls log\(X\) Reader.T)
	#$(call RunUrs, EOSF_ISOTHERM 289 2 5 100 \"MatterFreeE { FreeESumMatter {  FileName  lif.apr.mat Substance MatterSumLiFSpl   }  } \"  \"R EOS.Pressure EOS.Energy\" lif.the.300.spl)
	#$(call RunUrs, EOSF_ISOTHERM 10 2 5 100 \"MatterFreeE { FreeESumMatter {  FileName  lif.apr.mat Substance MatterSumLiF   }  } \"  \"R EOS.Pressure EOS.Energy\" lif.the.10)
	#$(call RunUrs, EOSF_ISOTHERM 1000 2 5 100 \"MatterFreeE { FreeESumMatter {  FileName  lif.apr.mat Substance MatterSumLiF   }  } \"  \"R EOS.Pressure EOS.Energy\" lif.the.1000)
	$(call RunUrs, EOSC_ISOTHERM 200 2 5 100 \"MatterSpl  { lif_cal.spl  } \"  \"R EOS.Pressure E.Energy EOS.Temperature\" lif.the.120.spl)
	#$(call RunUrs, EOSF_ISOTHERM "MinVal 1.1 MaxVal 8 NumDivStp 100 LogScale 1 NumSame 1" "MinVal 400 MaxVal 400 NumDivStp 1 LogScale 1 NumSame 1" \
	#	100 \"MatterFreeE { FreeESumMatter {  FileName  lif.apr.mat Substance MatterSumLiFSpl   }  } \"  \"R EOS.Pressure EOS.Energy\" lif.the.100.spl)
	#$(call RunUrs, EOSF_ISOTHERM_ISODENCE \"MinVal 4 MaxVal 4 NumDivStp 1 LogScale 1 NumSame 1\" \"MinVal 300 MaxVal 100000 NumDivStp 100 LogScale 1 NumSame 1\" \
	#	100 \"MatterFreeE { FreeESumMatter {  FileName  lif.apr.mat Substance MatterSumLiFSpl   }  } \"  \"T EOS.Pressure EOS.Energy\" lif.the.r.264)
	#$(call RunUrs, HUG_TR lif.hugp.pnt \"R P\" \"MatterFreeE { FreeESumMatter {  FileName  lif.apr.mat Substance MatterSumLiFSpl   }  } \"  \"HUG.Dencity HUG.Pressure EOS.Temperature HUG.Energy\" \"StartDenc 2.64 StartEner -6.43 StartPres 0\" lif.the.hug)
	#$(call RunUrs, HUG_TR lif.hugp.low \"R P\" \"MatterFreeE { FreeESumMatter {  FileName  lif.apr.mat Substance MatterSumLiFSpl   }  } \"  \"HUG.Dencity HUG.Pressure EOS.Temperature HUG.Energy\" \"StartDenc 2.64 StartEner 0 StartPres 0\" lif.the.hug)
	#$(call RunUrs, HUG_TR lif.hugp.low \"R P\" \"MatterSpl { lif_cal.spl } \"  \"HUG.Dencity HUG.Pressure EOS.Temperature HUG.Energy\" \"StartDenc 2.64 StartEner 0 StartPres 0\" lif.the.hugc)


spl.dst :
	$(call RunUrs, MK_TDF_SPL \"MinVal 200 MaxVal 100000 \" 150 \"MinVal 1e-1 MaxVal 10\" 150 \
		\"AddBeforeLogX 0 AddBeforeLogY 0  AddBeforeLogZ 6.3 MulX 1 MulY 1 MulZ 1 GenerationMisfit 1e-6\" \
		\"MatterFreeE { FreeEPureRoss  {  Material_File lif.apr.mat   Substance LiFRoss  }   } \" \
		Lif_FreeESpl LiF_ModRos )
		#Lif_FreeESpl LiF_ModRos Continue)

splcal.dst :
	$(call RunUrs, CaloricSPL lif_cal \"MatterFreeE { FreeESumMatter {  FileName  lif.apr.mat Substance MatterSumLiFSpl   }  } \" \
		\"AddE 1 AddP 10 MinT  160\" \"Xlow 1  Xup  12000 Ylow  0.11  Yup 9.9\"  \
		200 2e-4 1 )








test.dst :
	$(call RunCommand, TestUrs test lif.cold lif.apr.mat )
	urs_curve.exe test.cfg













expdir=root/scripts
ScriptFiles := eos/$(MkPref).mk eos/$(MkPref).sh common/urs_curve.sh


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
