#!/bin/perl

use strict;
use warnings;



sub ChanelDescription(){
    my ($Lag, $Line) = ($ARGV[0], $ARGV[1]);
    my %Lag_Chan_LC = (
                       1=>{ 1=>{L=>700, C=>0.00116},
                            2=>{L=>900, C=>0.00764},
                            3=>{L=>1000, C=>0.00539},
                            4=>{L=>1300, C=>0.00233},
                            5=>{L=>1500, C=>0.00313}
                           },
                       2=>{ 1=>{L=>700, C=>0.0017},
                            2=>{L=>900, C=>0.00268},
                            3=>{L=>1000, C=>0.00257},
                            4=>{L=>1300, C=>0.00428},
                            5=>{L=>1500, C=>0.00349}
                           }
                       );
    return \%Lag_Chan_LC;
}

sub ReadConfig($){
    my ($file) = @_;
    open(IN, "<$file")      or die "Could not open config file $file:$!\n";
    my @cfg;
    while(<IN>){
        next        if (substr($_, 0, 1) eq "#");
        my @l = split;
        next        if (int(@l)==0);
        die "Bad format have to be 9 column and is : $_ "   if (int(@l)!=9);
        my @ch = split(/:/, $l[3]);
        my @out = split(/:/, $l[5]);
        my (@AbsCh, @AbsOut);
        if ($l[2] == 1){
            $AbsCh[int(@AbsCh)] = $_ + 1  foreach (@ch);
            $AbsOut[int(@AbsOut)] = $_    foreach (@out);
        } else {
            $AbsCh[int(@AbsCh)] = $_ + 6  foreach (@ch);
            $AbsOut[int(@AbsOut)] = $_    foreach (@out);
        }
##Exp     MinTime  Lag  GreyChanels FixedGreyCoef  OutChanel  OutPrefix
#12296    2e-4     1     4:5         0             1:2:3:4:5    ch45
        my %Config = (Name=>$l[0],
                      MinT=>$l[1],
                      Lag=>$l[2],
                      gCh=>\@ch,
                      gCo=>$l[4],
                      Out=>\@out,
                      Prefix=>$l[6],
                      Smooth1=>$l[7],
                      Smooth2=>$l[8],
                      AbsCh=>\@AbsCh,
                      AbsOut=>\@AbsOut
                     );
        $cfg[int(@cfg)] = \%Config;
    }
    close IN;
    return \@cfg;
}
sub MakeGreyCfg($){
    my ($cfg) = @_;
    open OUT, ">tmp.make_grey.cfg";
    if ($cfg->{gCo}>0){
        print OUT <<EOF
        URS_Curve {
            Variables {
                File UrsCurve_FileReader {
                    FileName $cfg->{Name}.lim DataNames { time b l1_700 l1_900 l1_1000 l1_1300 l1_1500
                                                       l2_700 l2_900 l2_1000 l2_1300 l2_1500
                                                       ch13 ch14 ch15 ch16 ch17 ch18 ch19 } DefaultValue  0
                }
                Fix UrsCurve_StepClc {  MinVal $cfg->{gCo} MaxVal $cfg->{gCo} NumDivStp $cfg->{NumL} LogScale 0 NumSame 1 Centered 0 }
            }
            Output  URS_Curve::Output {
               FileToStore $cfg->{Name}.$cfg->{Prefix}.opacity VectorOfNames { File.time  Fix    }
            }
            NumIter  $cfg->{NumL}
        }
EOF
    ;
    } else {
        my $descr = ChanelDescription();
#File.l1_700:Ch_0 File.l1_1300:Ch_1 File.l1_1500:Ch_2
        my $inpChan = "";
        my $i = 0;
        foreach my $ch (@{$cfg->{gCh}}){
            my $wave = $descr->{$cfg->{Lag}}{$ch}{L};
            my $cal =  $descr->{$cfg->{Lag}}{$ch}{C};
            $inpChan = "$inpChan File.l$cfg->{Lag}_$wave:Ch_$i ";
#print "$ch $wave $cal $i\n$inpChan\n";
            $i++;
        }
        print OUT <<EOF
        URS_Curve {
            Variables {
                File UrsCurve_FileReader {
                    FileName $cfg->{Name}.lim DataNames { time b l1_700 l1_900 l1_1000 l1_1300 l1_1500
                                                       l2_700 l2_900 l2_1000 l2_1300 l2_1500
                                                       ch13 ch14 ch15 ch16 ch17 ch18 ch19 } DefaultValue  0
                }
            Color UrsCurve_ManyVarFunction {
                InputVal_Var:Clc {  $inpChan }
                ManyVarFunction  ColorTemp {
                    Chanels {
EOF
;
        foreach my $ch (@{$cfg->{gCh}}){
            my $wave = $descr->{$cfg->{Lag}}{$ch}{L};
            my $cal =  $descr->{$cfg->{Lag}}{$ch}{C};
            print OUT <<EOF
                        BrigtnesTemp {
                             L2OSourceCal ManyVarFunc2OneVar { ManyVarFunc  Spl2DGenerator { SplineFile  pirolamp.spl GenerateSpline 0 SplineDescr Spline SplineClass CurveSpline GenNumX  100  GenMisf  1e-7 } InVarName  X OutVarName Z  FixedParameters { Y:2700  }   }
                             L2OSourceExp PolynomFunc {  X0  0  Coef { 1:0  }  }
                             L2ODetector  ManyVarFunc2OneVar { ManyVarFunc  Spl2DGenerator { SplineFile  dfd1000.da GenerateSpline 2 SplineDescr Spline SplineClass CurveSpline GenNumX  1000  GenMisf  1e-7 } InVarName  X OutVarName Y  FixedParameters {   }   }
                             InterFilter  PolynomFunc {  X0  0  Coef { 1:0  }  }
                             ZeroFilterSignal 1e-5
                             WaveLength   $wave  SourceTemp  2700  Opacity  1  SingleLine  1  CalibrationSignal  $cal
                          }


EOF
;
        }
        print OUT <<EOF
                        }
                    }
                }
            }

            Output  URS_Curve::Output {
               FileToStore $cfg->{Name}.$cfg->{Prefix}.opacity VectorOfNames { File.time  Color.Opacity    }
            }
            NumIter  $cfg->{NumL}
        }
EOF
    ;

    }
    close OUT;

}
sub MakeBrCfg($$$$$){
    my ($cfg, $inPrefix, $outPrefix, $cfgPrefix, $clcChan) = @_;
    open OUT, ">tmp.make_$cfgPrefix.cfg";
        my $descr = ChanelDescription();
        print OUT <<EOF
        URS_Curve {
            Variables {
                File UrsCurve_FileReader {
                    FileName $cfg->{Name}.$inPrefix DataNames { time b l1_700 l1_900 l1_1000 l1_1300 l1_1500

                                                       l2_700 l2_900 l2_1000 l2_1300 l2_1500
                                                       ch13 ch14 ch15 ch16 ch17 ch18 ch19 } DefaultValue  0
                }
EOF
;
        my $outCol = "";
        foreach my $ch (@{$cfg->{$clcChan}}){
            my $wave = $descr->{$cfg->{Lag}}{$ch}{L};
            my $cal =  $descr->{$cfg->{Lag}}{$ch}{C};
            $outCol = "$outCol L$cfg->{Lag}_$wave.Val";
            print OUT <<EOF
            L$cfg->{Lag}_$wave  UrsCurve_OneVarFunction {   NameX File.l$cfg->{Lag}_$wave OneVarFunction BrigtnesTemp {
                  L2OSourceCal ManyVarFunc2OneVar { ManyVarFunc  Spl2DGenerator { SplineFile  pirolamp.spl GenerateSpline 0 SplineDescr Spline SplineClass CurveSpline GenNumX  100  GenMisf  1e-7 } InVarName  X OutVarName Z  FixedParameters { Y:2700  }   }
                  L2OSourceExp PolynomFunc {  X0  0  Coef { 1:0  }  }
                  L2ODetector  ManyVarFunc2OneVar { ManyVarFunc  Spl2DGenerator { SplineFile  dfd1000.da GenerateSpline 2 SplineDescr Spline SplineClass CurveSpline GenNumX  1000  GenMisf  1e-7 } InVarName  X OutVarName Y  FixedParameters {   }   }
                  InterFilter  PolynomFunc {  X0  0  Coef { 1:0  }  }
                  ZeroFilterSignal 1e-5
                  WaveLength   $wave  SourceTemp  2700  Opacity  1  SingleLine  1  CalibrationSignal  $cal
               }
               StartIntPnt 1  ClcIntegral  0
            }



EOF
;
        }
        print OUT <<EOF
            }

            Output  URS_Curve::Output {
               FileToStore $cfg->{Name}.$cfg->{Prefix}.$outPrefix VectorOfNames { File.time  $outCol  }
            }
            NumIter  $cfg->{NumL}
        }
EOF
    ;

    close OUT;

}

sub SmoothCfg($$$){
    my ($inName, $outName, $chan) = @_;
    my ($numRow, $numCol);
    {
        open INa, "<$inName";
        my @l = <INa>;
        $numRow = int(@l);
        my @l0 = split(" ", $l[0]);
        $numCol = int(@l0);
        close INa;

    }
    my $Cols = "";
    my %OrigCols;
    for(my $i = 0; $i < $numCol; $i++){
        $Cols = "$Cols ch$i";
        $OrigCols{$i} = 0;
    }

    open OUT, ">tmp.make_smooth.cfg";
        print OUT <<EOF
        URS_Curve {
            Variables {
                File UrsCurve_FileReader {
                    FileName $inName DataNames { $Cols } DefaultValue  0
                }
EOF
;
        my $outCol = "";
        foreach my $ch (@{$chan}){
            $outCol = "$outCol S$ch";
            delete $OrigCols{$ch};
            print OUT <<EOF
		 S$ch UrsCurve_ManyVarFunction {
			InputVal {  File.ch0:X File.ch$ch:Y } ManyVarFunction     NoiseRemoval {
			   ResultFileName  $outName.$ch MaxMisfitVal 1 StartNumDiv 50 MaxNumPnt 6000 SameCoef 4 WriteDescr 0
			}

	     }

EOF
;
        }
        print OUT <<EOF
            }

            Output  URS_Curve::Output {
               FileToStore NULL VectorOfNames {  $outCol  }
            }
            NumIter  $numRow
        }
EOF
    ;

    close OUT;
    system("urs_curve tmp.make_smooth.cfg");


    open OUT, ">tmp.make_smooth.cf1";
        print OUT <<EOF
        URS_Curve {
            Variables {
                File UrsCurve_FileReader {
                    FileName $inName DataNames { $Cols } DefaultValue  0
                }
EOF
;
        my $rmFiles = "";
        foreach my $ch (@{$chan}){
            $rmFiles = "$rmFiles  $outName.$ch";
            print OUT <<EOF
                File$ch UrsCurve_FileReader {
                    FileName $outName.$ch DataNames { 1 2 3 4 5 6 7 } DefaultValue  0
                }

EOF
;
        }
        $outCol = "";
        for(my $i = 0; $i < $numCol; $i++){
            if (defined($OrigCols{$i})){
                $outCol = "$outCol File.ch$i";
            } else {
                $outCol = "$outCol File$i.4";
            }
        }
        print OUT <<EOF
            }

            Output  URS_Curve::Output {
               FileToStore $outName.aaa VectorOfNames {  $outCol  }
            }
            NumIter  $numRow
        }
EOF
    ;

    close OUT;
    #system("urs_curve tmp.make_smooth.cf1; rm -f $rmFiles tmp.make_smooth.cf1 tmp.make_smooth.cfg");
    system("urs_curve tmp.make_smooth.cf1");
    system("cat $outName.aaa | gawk 'NR>1' >$outName");
    system("rm -f $rmFiles $outName.aaa tmp.make_smooth.cf1 tmp.make_smooth.cfg null");

}

sub MakeLimp($){
    my ($cfg) = @_;
    open IND, "<$cfg->{Name}.lim"        or die "Could not open file $cfg->{Name}.lim:$!\n";
    open INO, "<$cfg->{Name}.$cfg->{Prefix}.opacity"        or die "Could not open file $cfg->{Name}.opacity:$!\n";
    open OUT, ">$cfg->{Name}.limp"        or die "Could not open file $cfg->{Name}.limp:$!\n";
    <INO>;
    while(<IND>){
        my $d = $_;
        my @d = split;
        my $o = <INO>;
        my @o = split(" ", $o);
        next                          if (int(@d)==0 && int(@o)==0);
        die "Bad lines: <$d><$o>\n"     if ($d[0] != $o[0]);
        print OUT "$d[0] ";
        for(my $i = 1; $i < int(@d); $i++){
            print OUT $d[$i]/$o[1], " ";
        }
        print OUT "\n";
    }
    close OUT;close INO;close IND;
}

sub EvalConfig($){
    my ($cfg) = @_;
    my ($n, $t) = ($cfg->{"Name"}, $cfg->{"MinT"});
    system("cat $n.dat | gawk -v a=$t '\$1>a' > $n.lim");
    {
        open IN, "<$cfg->{Name}.lim";
        my @l = <IN>;
        $cfg->{NumL} = int(@l);
        close IN;
    }
    if ($cfg->{Smooth1}){
        system("cp $cfg->{Name}.lim $cfg->{Name}.li0");
        SmoothCfg("$cfg->{Name}.li0", "$cfg->{Name}.lim", $cfg->{AbsCh});
    }
    MakeGreyCfg($cfg);
    system("urs_curve tmp.make_grey.cfg");
    MakeBrCfg($cfg, "lim", "brighness", "br", "Out");
    system("urs_curve tmp.make_br.cfg");
    MakeLimp($cfg);
    MakeBrCfg($cfg, "limp", "color", "col", "Out");
    system("urs_curve tmp.make_col.cfg");
    if ($cfg->{Smooth2}){

        system("cat $cfg->{Name}.$cfg->{Prefix}.color |gawk -v n=$cfg->{NumL} 'NR>1 && NR<=n+1' > $cfg->{Name}.li1");
        SmoothCfg("$cfg->{Name}.li1", "$cfg->{Name}.$cfg->{Prefix}.color", $cfg->{AbsOut});
    }
    system("rm -f \"\#\#tmp.test.data\" $cfg->{Name}.lim $cfg->{Name}.limp $cfg->{Name}.li1 $cfg->{Name}.li0 tmp.make_col.cfg tmp.make_br.cfg tmp.make_grey.cfg");


}

my ($file) = ($ARGV[0]);
my $cfg = ReadConfig($file);
for( my $i = 0; $i < int(@{$cfg}); $i++){
    EvalConfig($cfg->[$i]);
}
