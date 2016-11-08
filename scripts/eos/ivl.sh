


#IsoT $(TEMP) temper.in volume.in pressure.tab $(IVLDAT) isot.$(TEMP) )
IsoT() {
T=$1
Tfile=$2
Vfile=$3
Z_VTfile=$4
DatDir=$5
IDformat=$6
Out=$7
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

