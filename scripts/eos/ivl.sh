


#IsoT $(TEMP) temper.in volume.in pressure.tab $(IVLDAT) isot.$(TEMP) )
IsoT() {
    local T=$1
    local Tfile=$2
    local Vfile=$3
    local Z_VTfile=$4
    local DatDir=$5
    local IDformat=$6
    local Out=$7

    cat $DatDir/$Tfile | sed 's/D/E/g' > $Out.t
    cat $DatDir/$Vfile | sed 's/D/E/g' > $Out.v
FLT=cat
    [ "x$IDformat" != "x0" ] && FLT=' sed s/\(.\)/\1\x20/g '
    cat $DatDir/$Z_VTfile | sed 's/D/E/g' | sed 's/\([0-9]\)-\([0-9]\)/\1 -\2/g' | $FLT | perl -e '
        use strict;use warnings;
        my ($t, $Tfile, $Vfile) = @ARGV;
        my @tdat = `cat $Tfile`;my @t = split(" ", join(" ",@tdat));
        my @vdat = `cat $Vfile`;my @v = split(" ", join(" ",@vdat));
        my ($tPos, $vPos) = (0, 0);
        my @zRow;
        while(<STDIN>) {
            my @l = split;
            $vPos += int(@l);
            @zRow = (@zRow, @l)  if ($t <= $t[$tPos]*1000);
            next        if ($vPos + 1 < int(@v));
            die("very bad - format violation: pos $vPos size ".int(@v)."\n".join("\n",@zRow))    if ($vPos > int(@v));
            #print STDERR "$tPos $t[$tPos] ", $t[$tPos]*1000, " $t\n";
            $tPos++;
            $vPos = 0;
            @zRow = (), next        if ($t > $t[$tPos -1] * 1000);
            for(my $i = int(@zRow) - 1; $i >= 0; $i--) {
                print 1/$v[$i], " ", $zRow[$i], " ", $t[$tPos - 1] * 1000, "\n";
            }
            exit;
            
        }
    ' $T $Out.t $Out.v  > $Out
    rm -f $Out.t $Out.v 
}

IsoTList() {
    local T="$1"
    local Tfile=$2
    local Vfile=$3
    local Z_VTfile=$4
    local DatDir=$5
    local IDformat=$6
    local Out=$7

    for aa in $T ; do 
        IsoT $aa $Tfile $Vfile $Z_VTfile $DatDir $IDformat $Out.$aa
        awk '{print $1,$2}' $Out.$aa > $Out.2.$aa
    done
    set1grph $Out.2.* $Out /a || echo WAU
    rm -rf  $Out.2.*
}

GetBnd() {
Tfile=$1
Vfile=$2
Z_VTfile=$3
DatDir=$4
FROM=$5
TO=$6
SHIFT=$7
Out=$8
    cat $DatDir/$Tfile | sed 's/D/E/g' > $Out.t
    cat $DatDir/$Vfile | sed 's/D/E/g' > $Out.v
    cat $DatDir/$Z_VTfile | sed 's/\(.\)/\1 /g' | perl -e '
        use strict;use warnings;
        my ($Tfile, $Vfile, $from, $to, $shift) = @ARGV;
#print STDERR "$Tfile, $Vfile, $from, $to\n";
        my @tdat = `cat $Tfile`;my @t = split(" ", join(" ",@tdat));
        my @vdat = `cat $Vfile`;my @v = split(" ", join(" ",@vdat));
        my ($tPos, $vPos) = (0, 0);
        my @zRow;
        while(<STDIN>) {
            my @l = split;
            #@zRow = (@zRow, @l);
            for(my $i = 0; $i < int(@l) - 1; $i++) {
                print("$tPos ", $vPos + $i + $shift, "\n")   if ($l[$i] == $from && $l[$i + 1] == $to);
                #print("$tPos ", $vPos + $i, " $l[$i + 1]\n")   if ($l[$i] == $from);
            }
            $vPos += int(@l);
            next        if ($vPos + 1 < int(@v));
            die("very bad - format violation: pos $vPos size ".int(@v)."\n".join("\n",@zRow))    if ($vPos > int(@v));
            $tPos++;
            $vPos = 0;
            #@zRow = ();
        }
    ' $Out.t $Out.v $FROM $TO $SHIFT > $Out
    rm -f $Out.t $Out.v 
    
}

DecodeBnd() {
Tfile=$1
Vfile=$2
Z_VTfile=$3
DatDir=$4
PNT=$5
Out=$6
    cat $DatDir/$Tfile | sed 's/D/E/g' > $Out.t
    cat $DatDir/$Vfile | sed 's/D/E/g' > $Out.v
    cat $DatDir/$Z_VTfile | sed 's/D/E/g' | sed 's/\([0-9]\)-\([0-9]\)/\1 -\2/g' | perl -e '
        use strict;use warnings;use Data::Dumper;
        my ($Tfile, $Vfile, $PNTfile) = @ARGV;
        my @tdat = `cat $Tfile`;my @t = split(" ", join(" ",@tdat));
        my @vdat = `cat $Vfile`;my @v = split(" ", join(" ",@vdat));
        my @pntdat = `cat $PNTfile`;my %pnt;
        foreach my $l (@pntdat) {
            my @l = split(" ", $l);
            $pnt{$l[0]} = $l[1];
        }
        #print STDERR Dumper(\%pnt);exit;
        
        my ($tPos, $vPos) = (0, 0);
        my @zRow;
        while(<STDIN>) {
            my @l = split;
            print($t[$tPos] * 1000, " ", 1/$v[$pnt{$tPos}], " $l[$pnt{$tPos} - $vPos]\n")     if (defined($pnt{$tPos}) && $pnt{$tPos} >= $vPos && $pnt{$tPos} < $vPos + int(@l));
            #print("$t[$tPos] $v[$pnt{$tPos}] $l[$pnt{$tPos} - $vPos]\n")     if (defined($pnt{$tPos}));# && $pnt{$tPos} >= $vPos && $pnt{$tPos} < $vPos + int(@l));
            $vPos += int(@l);
            
            next        if ($vPos + 1 < int(@v));
            die("very bad - format violation: pos $vPos size ".int(@v)."\n".join("\n",@zRow))    if ($vPos > int(@v));
            $tPos++;
            $vPos = 0;
            #@zRow = ();
        }
    ' $Out.t $Out.v $PNT > $Out
    rm -f $Out.t $Out.v 
    
    
}

#MakeSplCfg bin.e.low 0 2 t2e_low.spl spl.cfg
MakeSplCfg() {
DAT=$1
X=$2
Y=$3
NAMESPL=$4
NAMECFG=$5
MISFIT=$6
OUT=$7


    cat $DAT | awk -v x=$X -v y=$Y '{print $(x+1), $(y+1)}' > $NAMESPL.xy
    cat <<EOF >>$OUT

$NAMECFG {
    Curve UrsCurve::SplGen
    DatFile $NAMESPL.xy
    SplNum 180
    SplMis $MISFIT
    ResSpl $NAMESPL
}

EOF

}





IvlTable2Spl() {
IvlDir=$1
SplBase=${2:-$(basename $IvlDir)}
NumEPnt=${3:-256}


NumSplPnt=$(( $NumEPnt + 5 ))
NumSplPnt=260
#echo $NumEPnt $NumSplPnt $IvlDir $SplBase
ReadSplineError=1e-5

MakeSplineError=1e-2


cat <<EOF >$SplBase.cfg

 MakeCuSpline
       TIvlTable2Spl {
         ResSplFile  ${SplBase}.ispl
         ResSplDescription  test spline
         NumEPnt2NewSpl  ${NumEPnt}  Econverter2NewSpl  TExpConverter { MakeLog  1  MulX  1  AddX  0  }
         P_RE_SaveFile P_RE_SaveFile  T_RE_SaveFile  T_RE_SaveFile  UsePT_RE_Files 0


         Data_reader   
         P_tv_data  XFile  $IvlDir/temper.in  YFile  $IvlDir/volume.in  ZFile  $IvlDir/pressu.tab
         P_t_spl  TEncodedSplineGenerator {
            FunctionConverterX..Z {
               CvtX_0  TAutoExpConverter {  MakeLog  1  MulX  1  AddX  0  AutoMin_yesno 1 AutoVal  0.1  }
               CvtY    TAutoExpConverter {  MakeLog  1  MulX  1  AddX  0  AutoMin_yesno 1 AutoVal  0.1  }
            }
            SplineGen  TSpline1DGenerator {
               GenerationMisfit  $ReadSplineError  SplineName  p.ispl  SplineDescr  p_spline  NumX  $NumSplPnt  SplineOrder  3  MinXStep  0.1
            }
         }
         E_tv_data  XFile  $IvlDir/temper.in  YFile  $IvlDir/volume.in  ZFile  $IvlDir/energy.tab
         T_e_spl  TEncodedSplineGenerator {
            FunctionConverterX..Z {
               CvtX_0  TAutoExpConverter {  MakeLog  1  MulX  1  AddX  0  AutoMin_yesno 1 AutoVal  0.1  }
               CvtY    TAutoExpConverter {  MakeLog  1  MulX  1  AddX  0  AutoMin_yesno 1 AutoVal  0.SplineGen  }
            }
            1  TSpline1DGenerator {
               GenerationMisfit  $ReadSplineError  SplineName  t.ispl  SplineDescr  t_spline  NumX  $NumSplPnt  SplineOrder  3  MinXStep  0.01
            }
         }

         Pspl_finGenerator  TEncodedSplineGenerator {
            FunctionConverterX..Z {
               CvtX_0  TAutoExpConverter {  MakeLog  1  MulX  1  AddX  0  AutoMin_yesno 1 AutoVal  1  }
               CvtX_1  TAutoExpConverter {  MakeLog  1  MulX  1  AddX  0  AutoMin_yesno 1 AutoVal  1  }
               CvtY    TAutoExpConverter {  MakeLog  1  MulX  1  AddX  0  AutoMin_yesno 1 AutoVal  1  }

            }
            SplineGen  TSpline2DGenerator {
               GenerationMisfit  $MakeSplineError  SplineName  SingleFileStorage  SplineDescr  p_re_spline  NumX  $NumSplPnt  NumY  $NumSplPnt
            }
         }
         Tspl_finGenerator  TEncodedSplineGenerator {
            FunctionConverterX..Z {
               CvtX_0  TAutoExpConverter {  MakeLog  1  MulX  1  AddX  0  AutoMin_yesno 1 AutoVal  1  }
               CvtX_1  TAutoExpConverter {  MakeLog  1  MulX  1  AddX  0  AutoMin_yesno 1 AutoVal  1  }
               CvtY    TAutoExpConverter {  MakeLog  1  MulX  1  AddX  0  AutoMin_yesno 1 AutoVal  1  }

            }
            SplineGen  TSpline2DGenerator {
               GenerationMisfit  $MakeSplineError  SplineName  SingleFileStorage  SplineDescr  t_re_spline  NumX  $NumSplPnt  NumY  $NumSplPnt
            }
         }

     }

EOF

ivl_cvt blackbox "ConfigFile $SplBase.cfg"


}
