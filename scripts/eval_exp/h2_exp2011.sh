
GetParams() {
PARFILE=$1
PARNAME=$2
RES=$3
    cat $PARFILE | perl -e '
        use strict;use warnings;
        my $name = $ARGV[0];
        my %res;
        sub FindParam($$) {
            my ($l, $n) = @_;
            my @l = split(" ", $l);
            for(my $i=0; $i < int(@l) - 1; $i++) {
                return $l[$i+1]       if (lc($l[$i]) eq lc($n));
            }
            die "Exp $ARGV[0] have no param $n\n$l\n";
        }
        while(<STDIN>) {
            my @l = split;
            next	if (int(@l)!=2 || $l[0] ne $name);
#Exp St_u St_l  Al_l St_l H2_p H2_l LiF_l Sap_l
            my $l = <STDIN>;
            printf("%12s", $name);
            printf("\t%4g\t%4g", FindParam($l, "U"), FindParam($l, "L"));
            $l = <STDIN>;
            printf("\t%4g", FindParam($l, "L"));
            $l = <STDIN>;
            printf("\t%4g", FindParam($l, "L"));
            $l = <STDIN>;
            printf("\t%4g\t%4g", FindParam($l, "P"), FindParam($l, "L"));
            $l = <STDIN>;
            printf("\t%4g", FindParam($l, "L"));
            $l = <STDIN>;
            printf("\t%4g", FindParam($l, "L"));
            last;
        }
    ' $PARNAME >$RES
}

SetParams() {
PARFILE=$1
PARNAME=$2
RES=$3
    cat $PARFILE | perl -e '
        use strict;use warnings;
        my $name = $ARGV[0];
        sub Print($$$) {
            my ($l, $name, $mat) = @_;
            my @l = @$l;
#Exp St_u St_l  Al_l St_l H2_p H2_l LiF_l Sap_l
            print("$name { \n");
            print("    ( Mat Steel    L $l[2]  N 450 U $l[1] )\n");
            print("    ( Mat Al       L $l[3]  N 200 )\n");
            print("    ( Mat Steel    L $l[4]  N 150 )\n");
            print("    ( Mat $mat L $l[6] N 200 P $l[5] T 77.3 PntT 5 100 -5 )\n");
            print("    ( Mat LiF      L $l[7]  N 200 )\n");
            print("    ( Mat Sapphir  L $l[8]  N 200 PntE -1 )\n");
            print("      EndTime 2300\n}\n\n");
        }
        while(<STDIN>) {
            my @l = split;
            next	if (int(@l)<2 || $l[0] ne $name);
            Print(\@l, $name, "H2dismet");
            #Print(\@l, "${name}_mol", "H2");
            last;
        }
    ' $PARNAME >$RES
}


#$(ExpDir)/$*/$*_clc.Density 2 50 params.$*
AddMeanT () {
File=$1
Column=$2
MeanNum=$3
RES=$4
NumPnt=$(cat $File | wc -l)




    cat $File | perl -e '
        use strict;use warnings;
        my ($col, $mean, $pnts) = @ARGV;
        sub GetVal() {
            my $l = <STDIN>;
            my @l = split(" ", $l);
            return $l[$col];
        }
        my (@dat, $s, $t, $i, $sMax, $pos);
        for ($i = 0; $i < $pnts * 0.1; $i++)  { <STDIN>; }
        for($pos=$i; $i < $pos + $mean; $i++) { $t = GetVal(); $dat[int(@dat)] = $t; $s+=$t; }
        $sMax = $s;
        for(; $i < $pnts*0.9; $i++) {
            $t = GetVal();
            $s = $s + $t - shift(@dat);
            $dat[int(@dat)] = $t;
            $sMax = $s      if ($s > $sMax);
        }
        my $v = $sMax / int(@dat);
        if (abs($v) < 100) {
            printf("\t%.3f", $v);
        } else {
            printf("\t%.0f", $v);
        }
    ' $Column $MeanNum $NumPnt >> $RES
}
SetExpT() {
PARAMS=$1
RESULT=$2
    cat <<EOF > $RESULT.expdat
h2_001     5600
h2_002     3500
h2_003     3000
h2_004     5100
h2_005     3300
h2_006     2600
h2_007     3800
h2_008     3550
h2_014_lif 5000
h2_015_lif 2700
h2_016_lif 3300  bad
h2_017_lif 3200
h2_018_lif 2700
h2_019_lif 3500
h2_020_lif 5000  bad
h2_021_lif 3000
h2_022_lif 4400
h2_lif42   3300  very bad
h2_lif43   3000
h2_lif44   2900
EOF
    cat $RESULT.expdat | Rm15 | gsort > $RESULT.exp.srt
    cat $PARAMS | Rm15 | gawk 'NR==1{print $0"\tTStableExp"}' > $RESULT
    cat $PARAMS | gawk 'NR>1' | sed 's/^ *//' | Rm15 | gsort | join - $RESULT.exp.srt | awk -v OFS="\t" '{print $0}'  >> $RESULT
    rm -f $RESULT.exp.srt $RESULT.expdat
}
RmLF() {
sed 's/\\015\\015/\\015/g'
}
Rm15() {
sed 's/\\015//g'
}

ClcDis() {
FILE=$1
DENS=$2
TEMP=$3
XCOL=$4
RESULT=$5
    cat $FILE | gawk -v x=$XCOL -v d=$DENS -v t=$TEMP 'NR>1{print $x, $d, $t}' > $RESULT.dat
    MakeMatter $RESULT.mat
    MakeDisCfg $RESULT.cfg $RESULT.mat $RESULT.dat $RESULT
    urs_curve.exe  $RESULT.cfg
    rm -f $RESULT.cfg $RESULT.dat $RESULT.mat
}

MakeDisCfg() {
FILENAME=$1
MAT=$2
DAT=$3
RES=$4
NUM=$(cat $DAT | wc -l )
cat <<EOF >$FILENAME

URS_Curve {
    Variables {
        MDis2      EOS_Savable { MatterFreeE   {  ClcDissociation::FreeEDis2 {  Material_File $MAT Substance Mol_Atom2   } }  }
        IDis2      UrsCurve_FreeE { NameDenc Reader.R NameTemp Reader.T   NameMatter MDis2 }

        Reader      UrsCurve_FileReader { FileName $DAT DataNames {   X R T  }   DefaultValue  0 }
    }
    Output    URS_Curve::Output {
        FileToStore $RES   VectorOfNames {
            Reader.X Reader.R  Reader.T IDis2.Pressure  IDis2.Mol_M   IDis2.Atom_M
        }
    }
    NumIter  $NUM
}


EOF

}


MakeMatter() {
FILENAME=$1
cat <<EOF >$FILENAME

// FreeEElectron
H2Electron  NumEl  1 MolVeight 1 Zero 0 HiT  0

// FreeEElectronStrict
HElectronS                NumElPerAtom 1   MolVeight 1   Gfactor 2  ElMass_ElseNuclear  1 OutBoltzman 0  ColdCurve 0  ColdCurveTempCor 0
HElectronZero                NumElPerAtom 1   MolVeight 1   Gfactor 2  ElMass_ElseNuclear  1 OutBoltzman 0   ColdCurve 1  ColdCurveTempCor 0

// FreeEIdeal
IdealHMol      CvId 1.5 NMol 2 Zero 0 HiT 0  Tvib 6390 Trot 170.8
IdealHAtom   CvId 1.5 NMol 1 Zero 216 HiT -0.69315  Tvib 0 Trot 0
IdealHMet    CvId 1.5 NMol 1 Zero 0 HiT -0.  Tvib 0 Trot 0
IdealH   CvId 1.5 NMol 1 Zero 0 HiT -0.69315  Tvib 0 Trot 0


// Sol_Liq boundary
IdealHMetTrans   CvId 1.5 NMol 1 Zero 60 HiT -0  Tvib 0 Trot 0
IdealHMetTransSarov   CvId 1.5 NMol 1 Zero 75 HiT -0  Tvib 0 Trot 0
// Last version with 9 cluster
IdealHMetTransClast_9   CvId 1.5 NMol 1 Zero 83 HiT -0  Tvib 0 Trot 0


// FreeESumMatter
MatterSumH2Mol  {
    Coef1   1
    Matter1   MatterFreeSpl {   H2Mod_Mol.spl }
    Coef2   1
    Matter2   FreeEIdeal   {  Material_File $FILENAME Substance IdealHMol  }
}
MatterSumH2Atom  {
    Coef1   1
    Matter1   MatterFreeSpl  {  H2Mod_Met.spl  }
    Coef2   1
    Matter2   FreeEIdeal {  Material_File $FILENAME Substance IdealHAtom  }
}

MatterSumH2MetCorr  {
    Coef1   1
    Matter1   MatterFreeSpl  { H2Mod_Met.spl  }
    Coef2   -1
    Matter2   FreeEElectronStrict   { Material_File mat.bad Substance HElectronZero  }
    Coef2   1
    Matter2   FreeEElectronStrict   { Material_File mat.bad Substance HElectronS }
    Coef3   1
    Matter3   FreeEIdeal     { Material_File mat.bad Substance IdealHMetTrans   }
    Coef4   1
    Matter4   FreeEFormula   { Material_File mat.bad Substance FormMetCorr  }
}
MatterSumH2MetCorrSarov  {
    Coef1   1
    Matter1   MatterFreeSpl  { H2Mod_Met.spl  }
    Coef2   -1
    Matter2   FreeEElectronStrict   { Material_File $FILENAME Substance HElectronZero  }
    Coef2   1
    Matter2   FreeEElectronStrict   { Material_File $FILENAME Substance HElectronS }
    Coef3   1
    Matter3   FreeEIdeal     { Material_File $FILENAME Substance IdealHMetTransSarov   }
    Coef4   1
    Matter4   FreeEFormula   { Material_File $FILENAME Substance FormMetCorr  }
}


MatterSumH2MetCorrClast_9  {
    Coef1   1
    Matter1   MatterFreeSpl  { H2Mod_Met.spl  }
    Coef2   -1
    Matter2   FreeEElectronStrict   { Material_File $FILENAME Substance HElectronZero  }
    Coef2   1
    Matter2   FreeEElectronStrict   { Material_File $FILENAME Substance HElectronS }
    Coef3   1
    Matter3   FreeEIdeal     { Material_File $FILENAME Substance IdealHMetTransClast_9   }
    Coef4   1
    Matter4   FreeEFormula   { Material_File $FILENAME Substance FormMetCorr  }
}

FormMetCorr
     EndSymbol }
double MolVeight,Eioniz,Ediss,deltaE,CenterDenc,Width,Eadd;
Eioniz=15.4271; //eV/mol
Ediss=  432.006; //kJ/mol
deltaE=Ediss/2+M_eV_kJ*M_Na*Eioniz;
MolVeight=1;
CenterDenc=0.3;
Width=0.01;

 Eadd=1/M_PI*atan(((Denc-CenterDenc)/Width));
 FreeE=deltaE*(0.5-Eadd);

}

MatterSumH2MolStrict  {
    Coef1   1
    Matter1   FreeEPureRoss  {  Material_File matter_sum.cfg   Substance H2Mod_Mol  }
    Coef2   1
    Matter2   FreeEIdeal   {  Material_File $FILENAME Substance IdealHMol  }
}
MatterSumH2MetStrict  {
    Coef1   1
    Matter1   FreeEPureRoss  {  Material_File matter_sum.cfg   Substance H2Mod_Met  }
    Coef2   -1
    Matter2   FreeEElectronStrict   { Material_File $FILENAME Substance HElectronZero                }
    Coef2   1
    Matter2   FreeEElectronStrict   { Material_File $FILENAME Substance HElectronS }
    Coef3   1
    Matter3   FreeEIdeal     { Material_File $FILENAME Substance IdealHMet    }
}

MatterSumH2MetCorSarovStrict  {
    Coef1   1
    Matter1   FreeEPureRoss  {  Material_File matter_sum.cfg   Substance H2Mod_Met  }
    Coef2   -1
    Matter2   FreeEElectronStrict   { Material_File $FILENAME Substance HElectronZero                }
    Coef2   1
    Matter2   FreeEElectronStrict   { Material_File $FILENAME Substance HElectronS }
    Coef3   1
    Matter3   FreeEIdeal     { Material_File $FILENAME Substance IdealHMetTransSarov   }
    Coef4   1
    Matter4   FreeEFormula   { Material_File $FILENAME Substance FormMetCorr  }

}





// new dis version with cluster... MatterFreeE   {  ClcDissociation::FreeEDis2 {  Material_File $FILENAME Substance Mol_Atom2   } }
// Dissosiation...
Mol_Atom2
    EnterList_SubsName_FreeESubstance_SubsMolVeight {
        Name Atom     MolWeight 1 StartProportion 0 StartVolumeCoef 1 SubstMixtures 1 DerivStp 3e-4 MatterFreeE FreeESumMatter {  FileName  $FILENAME Substance MatterSumH2Atom  }
        Name Mol      MolWeight 2 StartProportion 1 StartVolumeCoef 1 SubstMixtures 1 DerivStp 3e-4 MatterFreeE FreeESumMatter {  FileName  $FILENAME Substance MatterSumH2Mol    }

    }  EnterListOfVectors_Vector_SubsName_SubsCoef {   {     Atom -2  Mol 1  }   }
    PressureMinim  FixedVolumeCoef  0  AddPolicy  1  AlphaMullCoef  1000  MaxPresMisfit  1.49012e-013  StartAddPressure  1e5  PressureMinParams {
        Matter Atom       MinDenc 1e-18 MaxDenc 2.1 MinVolCoef 0.0001 MaxVolCoef 10000
        Matter Mol        MinDenc 1e-18 MaxDenc 2.1 MinVolCoef 0.0001 MaxVolCoef 10000
    }
    NumberMinim   MatName_ClastSize {
        Matter Atom     ClasterSize 1
        Matter Mol      ClasterSize 1
    }
    NumberMinimMin   MatName_ClastSize {
        Matter Atom     ClasterSize 1
        Matter Mol      ClasterSize 1
    }


//   FreeELiqSol - old bad boundary clc ? mol - met
AtomMet_2Phase
 MatHghTemp FreeESumMatter  {  Material_File $FILENAME Substance MatterSumH2MetCorr  }
 MatLowTemp FreeEDis              {  Material_File $FILENAME Substance Mol_Atom   }
     Bnd FreeELiqSol_Bnd            {  NameBndSplFile h2_dismet_bnd.bin  }

AtomMet_2PhaseSarov
 MatHghTemp FreeESumMatter  {  Material_File $FILENAME Substance MatterSumH2MetCorrSarov  }
 MatLowTemp FreeEDis              {  Material_File $FILENAME Substance Mol_Atom   }
     Bnd FreeELiqSol_Bnd            {  NameBndSplFile h2_dismet_bnd_sarov.bin  }



// MatterFreeE   {  ClcDissociation::FreeEDis2 {  Material_File $FILENAME Substance Mol_Atom2   } }
// Metallization
// old vertion!!!
MolAtom_Met2
    EnterList_SubsName_FreeESubstance_SubsMolVeight {
        Name MolAtom  MolWeight 2 StartProportion 1 StartVolumeCoef 1 SubstMixtures 1 MatterFreeE ClcDissociation::FreeEDis2  {  FileName  $FILENAME Substance Mol_Atom2    }
        Name Met      MolWeight 1 StartProportion 0 StartVolumeCoef 1 SubstMixtures 1 MatterFreeE FreeESumMatter {  FileName  $FILENAME Substance MatterSumH2MetCorr    }

    }  EnterListOfVectors_Vector_SubsName_SubsCoef {   {   MolAtom 1      Met -2     }   }
    PressureMinim  FixedVolumeCoef  0  AddPolicy  0  AlphaMullCoef  1  MaxPresMisfit  1.49012e-010  StartAddPressure  1e+006  PressureMinParams {
        Matter MolAtom   MinDenc 1e-8 MaxDenc 2 MinVolCoef 0.0001 MaxVolCoef 10000
        Matter Met       MinDenc 0.3 MaxDenc 2 MinVolCoef 0.0001 MaxVolCoef 10000
    }
    NumberMinim   MatName_ClastSize {
        Matter MolAtom  ClasterSize 1
        Matter Met      ClasterSize 1
    }


MolAtom_Claster
    EnterList_SubsName_FreeESubstance_SubsMolVeight {
        Name Met      MolWeight 1 StartProportion 0 StartVolumeCoef 1 SubstMixtures 1 DerivStp 3e-4 MatterFreeE FreeESumMatter {  FileName  $FILENAME Substance MatterSumH2MetCorrClast      }
        Name MolAtom  MolWeight 2 StartProportion 1 StartVolumeCoef 1 SubstMixtures 1 DerivStp 3e-4 MatterFreeE MatterFreeSpl   {  h2molatom2_f.spl }
    }  EnterListOfVectors_Vector_SubsName_SubsCoef {   {     Met -2  MolAtom 1  }   }
    PressureMinim  FixedVolumeCoef  0  AddPolicy  1  AlphaMullCoef  1000  MaxPresMisfit  1.49012e-013  StartAddPressure  1e5  PressureMinParams {
        Matter Met       MinDenc 0.4 MaxDenc 1.95 MinVolCoef 0.0001 MaxVolCoef 10000
        Matter MolAtom   MinDenc 1e-18 MaxDenc 1.95 MinVolCoef 0.0001 MaxVolCoef 10000
    }
    NumberMinim   MatName_ClastSize {
        Matter Met      ClasterSize 15
        Matter MolAtom  ClasterSize 15
    }
    NumberMinimMin   MatName_ClastSize {
        Matter Met      ClasterSize 15
        Matter MolAtom  ClasterSize 15
    }

MolAtom_Claster_9
    EnterList_SubsName_FreeESubstance_SubsMolVeight {
        Name Met      MolWeight 1 StartProportion 0 StartVolumeCoef 1 SubstMixtures 1 DerivStp 3e-4 MatterFreeE FreeESumMatter {  FileName  $FILENAME Substance MatterSumH2MetCorrClast_9      }
        Name MolAtom  MolWeight 2 StartProportion 1 StartVolumeCoef 1 SubstMixtures 1 DerivStp 3e-4 MatterFreeE MatterFreeSpl   {  h2molatom2_f.spl }


    }  EnterListOfVectors_Vector_SubsName_SubsCoef {   {     Met -2  MolAtom 1  }   }
    PressureMinim  FixedVolumeCoef  0  AddPolicy  1  AlphaMullCoef  1000  MaxPresMisfit  1.49012e-013  StartAddPressure  1e5  PressureMinParams {
        Matter Met       MinDenc 0.4 MaxDenc 1.95 MinVolCoef 0.0001 MaxVolCoef 10000
        Matter MolAtom   MinDenc 1e-18 MaxDenc 1.95 MinVolCoef 0.0001 MaxVolCoef 10000
    }
    NumberMinim   MatName_ClastSize {
        Matter Met      ClasterSize 9
        Matter MolAtom  ClasterSize 9
    }
    NumberMinimMin   MatName_ClastSize {
        Matter Met      ClasterSize 9
        Matter MolAtom  ClasterSize 9
    }

//	MatterFreeE   ClcDissociation::FreeEDis2 {  Material_File $FILENAME Substance Mol_Atom2   }
//	MatterFreeE MatterFreeSpl   {  mol_atom_f.spl }
//	MatterFreeE MatterFreeSpl   {  h2molatom2_f.spl }





MatterFreeE FreeEPureRoss
H2Ross_Mol MolVeight 2 Zero 0 HiT 0 Exp6Part Exp_6_en 36.4 Exp_6_alph 11.1 Exp_6_r 3.43  Exp_6_r0 1.45855  CutDiameter 0.74  IncludePow6 1
H2Mod_Mol  MolVeight 2 Zero 0 HiT 0 Exp6Part Exp_6_en 17.8421 Exp_6_alph 10.8997 Exp_6_r 3.86859  Exp_6_r0 2.12375  CutDiameter 0.74  IncludePow6 1
H2Mod_Atom  MolVeight 1 Zero 0 HiT 0 Exp6Part Exp_6_en 12.3475 Exp_6_alph 10.6312 Exp_6_r 3.39569  Exp_6_r0 1.58951  CutDiameter 0.75  IncludePow6 1
H2Mod_Met  MolVeight 1 Zero 0 HiT 0 Exp6Part Exp_6_en  67.9593  Exp_6_alph 11.3 Exp_6_r 1.74053  Exp_6_r0  0.73974  CutDiameter 0.75  IncludePow6 1
// old Met_10          log(a+bx)




EOF


}
