
EOSF_TR() {
FILE=$1
FILECOL=$2
MAT="$3"
OUTCOL="$4"  #Reader.R  Reader.T EOS.Pressure
OUTBASE=$5

NUM=$(cat $FILE | wc -l )
cat <<EOF >$OUTBASE.cfg

URS_Curve {
    Variables {
        MAT      EOS_Savable { $MAT  }
        EOS      UrsCurve_FreeE { NameDenc Reader.R NameTemp Reader.T   NameMatter MAT }

        Reader      UrsCurve_FileReader { FileName $FILE DataNames {   $FILECOL  }   DefaultValue  0 }
    }
    Output    URS_Curve::Output {
        FileToStore $OUTBASE.out   VectorOfNames {
            $OUTCOL
        }
    }
    NumIter  $NUM
}


EOF
    urs_curve.exe $OUTBASE.cfg
    #dat.bat $OUTBASE.out
}

EOSC_ISOTHERM() {
TEMP=$1
FRR=$2
TOR=$3
NUMR=$4
MAT="$5"
OUTCOL="$6"  #R  T EOS.Pressure EOS.Energy
OUTBASE=$7

cat <<EOF >$OUTBASE.cfg

URS_Curve {
    Variables {
        MAT      EOS_Savable { $MAT   }
        EOS      UrsCurve_Caloric { NameDenc R NameEnergy E.Energy NameMatter MAT }
        E        UrsCurve_EOS_FindE {  NameDenc R NameTemp T NameMatter MAT }

        R   UrsCurve_StepClc { MinVal $FRR MaxVal $TOR NumDivStp $NUMR LogScale 1 NumSame 1 Centered 0 }
        T   UrsCurve_StepClc { MinVal $TEMP MaxVal $TEMP NumDivStp 1 LogScale 1 NumSame 1 Centered 0 }
    }
    Output    URS_Curve::Output {
        FileToStore $OUTBASE.out   VectorOfNames {
            $OUTCOL
        }
    }
    NumIter  $NUMR
}


EOF
    urs_curve.exe $OUTBASE.cfg
}

EOSF_ISOTHERM() {
TEMP=$1
FRR=$2
TOR=$3
NUMR=$4
MAT="$5"
OUTCOL="$6"  #R  T EOS.Pressure EOS.Energy
OUTBASE=$7

#RPARAM="$1"       #MinVal $FRR MaxVal $TOR NumDivStp $NUMR LogScale 1 NumSame 1
#TPARAM="$2"       #MinVal $FRR MaxVal $TOR NumDivStp $NUMR LogScale 1 NumSame 1
#NUMR=$3
#MAT="$4"
#OUTCOL="$5"  #R  T EOS.Pressure EOS.Energy
#OUTBASE=$6

cat <<EOF >$OUTBASE.cfg

URS_Curve {
    Variables {
        MAT      EOS_Savable { $MAT   }
        EOS      UrsCurve_FreeE { NameDenc R NameTemp T   NameMatter MAT }

        R   UrsCurve_StepClc { MinVal $FRR MaxVal $TOR NumDivStp $NUMR LogScale 1 NumSame 1 Centered 0 }
        T   UrsCurve_StepClc { MinVal $TEMP MaxVal $TEMP NumDivStp 1 LogScale 1 NumSame 1 Centered 0 }
    }
    Output    URS_Curve::Output {
        FileToStore $OUTBASE.out   VectorOfNames {
            $OUTCOL
        }
    }
    NumIter  $NUMR
}


EOF
    urs_curve.exe $OUTBASE.cfg
    #dat.bat $OUTBASE.out
}

EOSF_ISOTHERM_ISODENCE() {
RPARAM="$1"       #MinVal $FRR MaxVal $TOR NumDivStp $NUMR LogScale 1 NumSame 1
TPARAM="$2"       #MinVal $FRR MaxVal $TOR NumDivStp $NUMR LogScale 1 NumSame 1
NUMR=$3
MAT="$4"
OUTCOL="$5"  #R  T EOS.Pressure EOS.Energy
OUTBASE=$6

cat <<EOF >$OUTBASE.cfg

URS_Curve {
    Variables {
        MAT      EOS_Savable { $MAT   }
        EOS      UrsCurve_FreeE { NameDenc R NameTemp T   NameMatter MAT }

        R   UrsCurve_StepClc { $RPARAM Centered 0 }
        T   UrsCurve_StepClc { $TPARAM Centered 0 }
    }
    Output    URS_Curve::Output {
        FileToStore $OUTBASE.out   VectorOfNames {
            $OUTCOL
        }
    }
    NumIter  $NUMR
}


EOF
    urs_curve.exe $OUTBASE.cfg
}





HUG_TR() {
FILE=$1
FILECOL=$2  # P ...
MAT="$3"      # MatterSpl { he_ros_e.spl }
OUTCOL="$4"  #HUG.Velocity  HUG.Dencity HUG.Pressure HUG.Energy HUG.ShockVelocity EOS.Sound EOS.Temperature
STARTPAR="$5" #StartDenc \$STDENC StartEner \$STENER StartPres \$STPRES
OUTBASE=$6

NUM=$(cat $FILE | wc -l )
cat <<EOF > $OUTBASE.cfg

URS_Curve {
    Variables {
        MAT      EOS_Savable { $MAT }
        HUG      UrsCurve_EOS_Hugoniot { NameDenc Reader.P NameMatter MAT $STARTPAR StartVel 0 PressureDependece 1 RecalcPres  0 }
        EOS      UrsCurve_Caloric { NameDenc HUG.Dencity NameEnergy HUG.Energy NameMatter MAT }

        Reader      UrsCurve_FileReader { FileName $FILE DataNames {   $FILECOL  }   DefaultValue  0 }
    }
    Output    URS_Curve::Output {
        FileToStore $OUTBASE.out   VectorOfNames {
            $OUTCOL
        }
    }
    NumIter  $NUM
}


EOF
    urs_curve.exe $OUTBASE.cfg
    #dat.bat $OUTBASE.out

}

MK_TDF_SPL() {
# T D - > F
TEMP="$1"   #MinVal 100 MaxVal 1e6
TEMPNUM=$2  #250
DENC="$3"   #MinVal 1e-4 MaxVal 3
DENCNUM=$4  #250
ADD="$5"    #AddBeforeLogX 0 AddBeforeLogY 0  AddBeforeLogZ 1 MulX 1 MulY 1 MulZ 1 GenerationMisfit 1e-6
MATTER="$6" #MatterFreeE { FreeEPureRoss Material_File matter_sum.cfg Substance H2Mod_Mol }
DESCR=$7
OUTBASE=$8
REBUILD=$9

DENCNUMS=$(( $DENCNUM + 5 ))
TEMPNUMS=$(( $TEMPNUM + 5 ))
FULLNUM=$(( $DENCNUM * $TEMPNUM ))
NAMEZ=UrsFreeE.FreeE
OUTFILE=$OUTBASE.dat
[ "x$REBUILD" != "x" ] && NAMEZ=Reader.3 && OUTFILE=$OUTFILE.add

cat <<EOF >$OUTBASE.cfg

URS_Curve {
    Variables {
        Dencity     UrsCurve_StepClc { $DENC  NumDivStp $DENCNUM LogScale 1 NumSame 1 Centered 0 }
        Temperature UrsCurve_StepClc { $TEMP  NumDivStp $TEMPNUM LogScale 1 NumSame $DENCNUM Centered 0 }
        Reader      UrsCurve_FileReader { FileName $OUTBASE.dat DataNames {  1 2 3   } DefaultValue  0 }

        Matter      EOS_Savable { $MATTER }
        UrsFreeE    UrsCurve_FreeE { NameDenc Dencity NameTemp Temperature NameMatter Matter }

        SplineFree  UrsCurve_SplConstr { NameX  Temperature NameY Dencity NameZ $NAMEZ ResSplineName  $OUTBASE.spl SplineDescription $DESCR LogX 1 LogY 1 LogZ 1 $ADD GenerationNumX $TEMPNUMS GenerationNumY $DENCNUMS  }
    }

    Output   URS_Curve::Output {
                FileToStore $OUTFILE VectorOfNames {
                    SplineFree  Temperature Dencity $NAMEZ
                }
    }
    NumIter  $FULLNUM
}
EOF
    urs_curve.exe $OUTBASE.cfg
    #dat.bat $OUTBASE.out

}

CaloricSPL() {
BASEOUT=$1
MATTER="$2"     #MatterFreeE { MatterFreeSpl  {  h2claster_f9.spl }   }
SPLPAR="$3"     #AddE 1 AddP 1 MinT  105
SPLLIMITS="$4"  #Xlow 1  Xup  12000 Ylow  0.00021  Yup 1.8
NUMPNT=$5
MISP=$6
MIST=$7
CONT=$8

GETPNT=0
[ "x$CONT" != "x" ] && GETPNT=1

NUMPNT5=$(( $NUMPNT + 5 ))

cat <<EOF >$BASEOUT.lim.cfg

Res_name $BASEOUT.spl DencCold 0.0131 DencMax 2.5
 SplX $NUMPNT5  SplY $NUMPNT5  Meth 0 Misf $MISP  $SPLPAR GetPnt $GETPNT
 NumX $NUMPNT NumY $NUMPNT ExpX 1 ExptY 1
 $SPLLIMITS
 SplX $NUMPNT5  SplY $NUMPNT5  Meth 0 Misf $MIST
EOF


cat <<EOF >$BASEOUT.cfg

$MATTER

u1 0   r1 7.9  p1   0      e1  0.86  porous 1. StndErr 1e-5 SetBegPres 1
u_beg 0.  min_p 1.001 max_u1 100 stp 3
ShowHugPres      0   !h.dat

not_used 0.1 min_D 0.14 max_D 0.35 stp .02
ShowHugDenc     0   !dhug5.dat

No   0.1     No 5         No 1         No 1000
ShowEnergyTabl  0   tab1

No   0.1     No 5         No 1         No 1000
ShowTempTabl  0   data.txt

initial_t    5000 min_r1 0.08    max_r1 2.5     stp .01
ShowIsotherm  0   tr_.dat

init_e 62.2368 min_d 0.46 max_d 1.1 stp 0.01
ShowIsoentr 0   !grig1.dat

No   0.1     No 5         No 1         No 1000
ConstructSpl  1   $BASEOUT.lim.cfg

FileName h2_param.cfg  NameSubstance H2_My
initial_t  10 min_r1 0.029 max_r1 2   stp .01
ShowCold     0   !01.dat

MatterFreeE FreeEEmpiLiquid  FileParam h2_param.cfg  NameSubstance Empi_My3
initial_t  10 min_r1 0.029 max_r1 2   stp .01
ShowCold     0   !01.dat
EOF

madi_ex $BASEOUT.cfg

}




IvlTable2Spl() {


cat <<EOF >cu256.cfg

 MakeCuSpline
       TIvlTable2Spl {
         ResSplFile  cu256.ispl
         ResSplDescription  test spline
         NumEPnt2NewSpl  256  Econverter2NewSpl  TExpConverter { MakeLog  1  MulX  1  AddX  0.1  }
         P_RE_SaveFile P_RE_SaveFile  T_RE_SaveFile  T_RE_SaveFile  UsePT_RE_Files 0


         PTspl_reader   P_tv_data  XFile  eval/cu2/temper.in  YFile  eval/cu2/volume.in  ZFile  eval/cu2/pressu.tab
         P_t_spl  TEncodedSplineGenerator {
            FunctionConverterX..Z {
               CvtX_0  TAutoExpConverter {  MakeLog  1  MulX  1  AddX  0  AutoMin_yesno 1 AutoVal  0.1  }
               CvtY    TAutoExpConverter {  MakeLog  1  MulX  1  AddX  0  AutoMin_yesno 1 AutoVal  1  }
            }
            SplineGen  TSpline1DGenerator {
               GenerationMisfit  1e-004  SplineName  p.ispl  SplineDescr  p_spline  NumX  100  SplineOrder  3  MinXStep  0.1
            }
         }
         E_tv_data  XFile  eval/cu2/temper.in  YFile  eval/cu2/volume.in  ZFile  eval/cu2/energy.tab
         T_e_spl  TEncodedSplineGenerator {
            FunctionConverterX..Z {
               CvtX_0  TAutoExpConverter {  MakeLog  1  MulX  1  AddX  0  AutoMin_yesno 1 AutoVal  0.1  }
               CvtY    TAutoExpConverter {  MakeLog  1  MulX  1  AddX  0  AutoMin_yesno 1 AutoVal  1  }
            }
            SplineGen  TSpline1DGenerator {
               GenerationMisfit  1e-004  SplineName  t.ispl  SplineDescr  t_spline  NumX  100  SplineOrder  3  MinXStep  0.01
            }
         }

         Pspl_finGenerator  TEncodedSplineGenerator {
            FunctionConverterX..Z {
               CvtX_0  TAutoExpConverter {  MakeLog  1  MulX  1  AddX  0  AutoMin_yesno 1 AutoVal  0.1  }
               CvtX_1  TAutoExpConverter {  MakeLog  1  MulX  1  AddX  0  AutoMin_yesno 1 AutoVal  0.01  }
               CvtY    TAutoExpConverter {  MakeLog  1  MulX  1  AddX  0  AutoMin_yesno 1 AutoVal  1  }

            }
            SplineGen  TSpline2DGenerator {
               GenerationMisfit  1.1e-002  SplineName  SingleFileStorage  SplineDescr  p_re_spline  NumX  301  NumY  301
            }
         }
         Tspl_finGenerator  TEncodedSplineGenerator {
            FunctionConverterX..Z {
               CvtX_0  TAutoExpConverter {  MakeLog  1  MulX  1  AddX  0  AutoMin_yesno 1 AutoVal  0.1  }
               CvtX_1  TAutoExpConverter {  MakeLog  1  MulX  1  AddX  0  AutoMin_yesno 1 AutoVal  0.01  }
               CvtY    TAutoExpConverter {  MakeLog  1  MulX  1  AddX  0  AutoMin_yesno 1 AutoVal  1  }

            }
            SplineGen  TSpline2DGenerator {
               GenerationMisfit  1e-002  SplineName  SingleFileStorage  SplineDescr  t_re_spline  NumX  301  NumY  301
            }
         }

     }

EOF

ivl_cvt blackbox "ConfigFile cu256.cfg"


}
