use strict;
use warnings;

require ClcGasd;
require AnalyzeData;
require AnalyzeConfig;

sub ReadColorCfg($){
    my ($cfg) = @_;
    my %ColorConfig;# {tek1}{ColorChan WriteChan SmoothBefore SmoothAfter }
}

sub ShortenConfig($$){
    
}
sub ClcBrigtness($$){
    
}
sub ClcOpacity($$){
    
}
sub ClcColor($$){
    
}
sub SmoothCurves(){
    
}
sub ClcOptics($) {
    my ($EkspPar) = @_;
    my $dir = $EkspPar->{ClcDir};
    my $Calib ;
    if (defined($EkspPar->{Calibration}) && AnalyzeData::IsNumber($EkspPar->{Calibration}) && $EkspPar->{Calibration}>0) {
            $Calib = $EkspPar->{Calibration};
    }else {
            $Calib = AnalyzeConfig::ClcCalibration("$dir$EkspPar->{CalibFile}.dat");
    }
    
    open OUT1, "> $dir$EkspPar->{ExpFile}.da"               or die "Could not open out file $dir$EkspPar->{ExpFile}.da:$!\n";
    my ($Lam, $UseLine) = ( $EkspPar->{Lambda}, "\"\"");
    if ( lc(substr($EkspPar->{Lambda},0,2)) eq "si" ) {
            $Lam = 700;
            $UseLine = "N";
    }
    if ( lc(substr($EkspPar->{Lambda},0,3)) eq "dfd" ) {
            $Lam = 1500;
            $UseLine = "N";
    }

    my $n = "\x0D\x0A";
    print OUT1 "1 $n$Lam $n$UseLine $n$Calib $n$EkspPar->{Opacity}$n";

    my ($data, $ChShift) = ClcShift("$dir$EkspPar->{ExpFile}.dat");

    for(my $i=0;$i<int(@{$data->[0]});$i++){
        print OUT1 $data->[0][$i]-$EkspPar->{Shift},"   ",$data->[1][$i]-$ChShift, $n;
    }

    system("mv $dir$EkspPar->{ExpFile}.da tmp.dat");

            if ($Lam<=1080){
        system("vol2temp tmp.dat tmp.tbr");
            } else {
        system("vol2temp tmp.dat /Rdfd1000.dat tmp.tbr");
            }
    system("mv  tmp.tbr $dir$EkspPar->{ExpFile}.tbr");
    system("mv  tmp.dat $dir$EkspPar->{ExpFile}.da");

}       ##ClcOptics


sub MakeStdTrb($){
    my ($cfg) = @_;
    foreach my $parfile (keys %{$cfg}){
        foreach my $number (keys %{$cfg->{$parfile}}){
            my $EkspPar = $cfg->{$parfile}{$number};
            system("mkdir -p $EkspPar->{ClcDir}");
            ClcOptics($EkspPar)     if (defined($EkspPar->{ClcOptics}));
        }
    }
    GenerateResult($cfg);
}


    my $datacfg = new AnalyzeConfig::new($ARGV[0], $ARGV[1]);
    my $colorcfg = ReadColorCfg($datacfg);
    
    foreach my $parfile (keys %{$datacfg}){
        my $EkspParHash = $datacfg->{$parfile};
        my $Color = $colorcfg->{$parfile};
        my $outBase = ClcOutBase($EkspParHash);
        ClcData($EkspParHash, $Color->{WriteChan}, "$outBase.rawWrite");
        ClcData($EkspParHash, $Color->{ColorChan}, "$outBase.rawColor");
        ClcBrigtness($EkspParHash, $Color->{WriteChan}, "$outBase.rawWrite"); #file.data file.brightness
        #ClcSmooth("$outBase.rawColor", "$outBase.rawColorS", \@ColorSmoothChan)                         if ($Color->{SmoothBefore});
        ClcOpacity($EkspParHash, $Color->{ColorChan}, "$outBase.rawColor", "$outBase.Opacity");
        ClcColor($EkspParHash, $Color->{WriteChan}, "$outBase.Opacity", "$outBase.Color");
    }
    
    