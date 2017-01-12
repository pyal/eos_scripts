 use strict;use warnings;


#$/="\x0D\x0A";
require ClcGasd;
require GasdCfgReader;
#require AnalyzeData;
#use IO::File;
#require RegMarch;

############################################################################
sub ClcEksp     #10/21/2007 5:51
############################################################################
 {
    my ($ThePar, $TimeCoef) = @_;
    my $BaseName = $ThePar->GetOutBaseName()."_clc";
    my ($ShowE, $ShowT, $ClcLayer, $ClcTime) = $ThePar->SetStdPar;
    my $Clc = ClcGasd::new($BaseName, $ShowE, $ShowT, $ClcLayer, $ClcTime, $TimeCoef);
    return $Clc;
}   ##ClcEksp


my $ThePar = GasdCfgReader::new($ARGV[0], $ARGV[1], $ARGV[3], $ARGV[2]);
my $wrk_dir=$ThePar->GetClcDir;
system("mkdir -p $wrk_dir");
my $Clc = ClcEksp($ThePar, $ARGV[5]);
no strict 'refs';
my $call = "ClcGasd::$ARGV[4]";
&$call($Clc);
#$Clc->ClcAssembly();
#$Clc->GetAllPnt();
#$Clc->SumFiles();




