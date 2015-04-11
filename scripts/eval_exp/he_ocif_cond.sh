

Make2DSpline() {
DatFile=$1
Num=$(cat  $DatFile | wc -l )
    cat >spl.cfg <<EOF
    URS_Curve {
        Variables {
            File UrsCurve_FileReader {
                FileName $DatFile DataNames { Temp Alpha Cond  } DefaultValue  0
            }
            SplGen UrsCurve_ManyVarFunction {
                InputVal_Var:Clc {  File.Temp:X File.Alpha:Y File.Cond:Z } ManyVarFunction  Spl2DGenerator {
                    SplineFile  he_ta2cond.spl GenerateSpline 1 SplineDescr Conductivity_in_Ohm_meter
                    SplineClass ExtendedRegridSpline
                        LogX 1 LogY 1 LogZ 1 AddBeforeLogX 0 AddBeforeLogY 0 AddBeforeLogZ 0
                        MulX 1 MulY 1 MulZ 1
                        GenerationMisfit 1e-001 GenerationNumX 105 GenerationNumY 25
                }
            }


        } Output  URS_Curve::Output {
            FileToStore $DatFile.read  VectorOfNames { File.Temp File.Alpha File.Cond SplGen }
        } NumIter  $Num
    }

                        GenerationMisfit 5e-003 GenerationNumX 105 GenerationNumY 25


EOF
    urs_curve spl.cfg
}
FindMax() {
    cat $1 | awk -v c=$2 'NR>1{if ($c > max) max = $c}END{print max}'
}

ClcAlpha() {
cat <<EOF >ion_deg.cfg


URS_Curve {
    Variables {
        Reader      UrsCurve_FileReader { FileName rt_the.pnt1 DataNames {   R T P   } DefaultValue  0 }

        Mat         EOS_Savable {  MatterFreeE {  ClcIonisation::FreeEIonDebyHuckel {  Material_File mat.he   Substance HeIonOCP  }   }  }
        Urs         UrsCurve_FreeE { NameDenc Reader.R NameTemp Reader.T  NameMatter Mat }

        MatPres  EOS_Savable {  MatterFreeE { FreeESumMatter { Material_File mat.he   Substance HeRosSumOCPSpl  } }  }
        UrsPres   UrsCurve_FreeE { NameDenc Reader.R NameTemp Reader.T  NameMatter MatPres  }
    }
    Output   URS_Curve::Output {
           FileToStore exp_ion_the.dat1  VectorOfNames {
                Reader.R Reader.T UrsPres.Pressure    Urs.IonNum_1
          }
    }
NumIter  $NumPnt   }



EOF

urs_curve ion_deg.cfg

}
ClcCond(){
DatFile=$1
cat $DatFile | gawk 'NR>1{print $2,$3,$4}' | sed 's/\0x0D\0x0D/\0x0D/g'  > dat
Num=$(cat  dat | wc -l )
    cat >cond.cfg <<EOF
    URS_Curve {
        Variables {
            File UrsCurve_FileReader {
                FileName dat DataNames { Denc Temp Pres  } DefaultValue  0
            }

            Mat         EOS_Savable {  MatterFreeE {  ClcIonisation::FreeEIonDebyHuckel {  Material_File mat.he   Substance HeIonOCP  }   }  }
            Urs         UrsCurve_FreeE { NameDenc File.Denc NameTemp File.Temp  NameMatter Mat }

            MatPres  EOS_Savable {  MatterFreeE { FreeESumMatter { Material_File mat.he   Substance HeRosSumOCPSpl  } }  }
            UrsPres   UrsCurve_FreeE { NameDenc File.Denc NameTemp File.Temp  NameMatter MatPres  }

            SplGen UrsCurve_ManyVarFunction {
                InputVal_Var:Clc {  File.Temp:X Urs.IonNum_1:Y File.Temp:Z } ManyVarFunction  Spl2DGenerator {
                    SplineFile  he_ta2cond.spl GenerateSpline 0 SplineDescr Spline
                    SplineClass ExtendedRegridSpline
                        LogX 1 LogY 1 LogZ 1 AddBeforeLogX 0 AddBeforeLogY 0 AddBeforeLogZ 0
                        MulX 1 MulY 1 MulZ 1
                        GenerationMisfit 5e-003 GenerationNumX 105 GenerationNumY 25
                }
            }


        } Output  URS_Curve::Output {
            FileToStore expcond.da  VectorOfNames { File.Denc File.Temp File.Pres UrsPres.Pressure Urs.IonNum_1 SplGen.Z }

        } NumIter  $Num
    }



EOF
    urs_curve cond.cfg

    perl -e '
        use strict;use warnings;
        open(PNT, "<expcond.da ");
        open(D, "<$ARGV[0] ");
        my $l = <D>;
        $l = <PNT>;
        my @l = split(" ", $l);
        print join("\t", ("Name", @l)),"\n";
        while($l=<PNT>) {
            my @d=split(" ", <D>);
            @l = split(" ", $l);
            next    if (int(@l)<2);
            $l[5] /= 100;
            print join("\t", ($d[0], @l)),"\n";
        }
    ' $DatFile  | sed 's/\0x0D\0x0D/\0x0D/g'  > expcond.dat

}


TestSpl() {
TempFrom=$1
TempTo=$2
NumTemp=$3
AlphaFrom=$4
AlphaTo=$5
NumAlpha=$6

let Num=$NumAlpha*$NumTemp
    cat >test.cfg <<EOF
    URS_Curve {
        Variables {
            Temp  UrsCurve_StepClc {  MinVal $TempFrom MaxVal $TempTo NumDivStp $NumTemp LogScale 1 NumSame 1 Centered 0  }
            Alpha UrsCurve_StepClc {  MinVal $AlphaFrom MaxVal $AlphaTo NumDivStp $NumAlpha LogScale 1 NumSame $NumTemp Centered 0  }

            SplGen UrsCurve_ManyVarFunction {
                InputVal_Var:Clc {  Temp:X Alpha:Y Alpha:Z } ManyVarFunction  Spl2DGenerator {
                    SplineFile  he_ta2cond.spl GenerateSpline 0 SplineDescr Spline
                    SplineClass ExtendedRegridSpline
                        LogX 1 LogY 1 LogZ 1 AddBeforeLogX 0 AddBeforeLogY 0 AddBeforeLogZ 0
                        MulX 1 MulY 1 MulZ 1
                        GenerationMisfit 5e-003 GenerationNumX 105 GenerationNumY 25
                }
            }


        } Output  URS_Curve::Output {
            FileToStore test.da  VectorOfNames { Temp SplGen.Z Alpha  }

        } NumIter  $Num
    }



EOF
    urs_curve test.cfg

}

Sum2Files() {
Fst=$1
W1=$2
Sec=$3
W2=$4
RES=$5
    perl -e '
        use strict;use warnings;
        open(F, "<$ARGV[0]");
        open(S, "<$ARGV[2]");
        my ($w1, $w2) = ($ARGV[1], $ARGV[3]);
        my $l1 = <F>;$l1 = <F>;
        my $l2 = <S>;$l2 = <S>;
        while($l1 = <F>) {
            $l2 = <S>;
            my @l1 = split(" ", $l1);
            my @l2 = split(" ", $l2);
            print "$l1[0]  ", ($l1[1]*$w1 + $l2[1]*$w2) / ($w1 + $w2), "\n";
        }
        close F;close S;
    ' $Fst $W1 $Sec $W2 > $RES
}
