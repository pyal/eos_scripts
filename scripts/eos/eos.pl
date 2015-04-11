 use strict;use warnings;


#$/="\x0D\x0A";
require EosMarch;
require CfgReader;
use Data::Dumper;

#############################################################################
#sub ClcEksp     #10/21/2007 5:51
#############################################################################
# {
#    my ($ThePar, $TimeCoef) = @_;
#    my $BaseName = $ThePar->GetOutBaseName()."_clc";
#    my ($ShowE, $ShowT, $ClcLayer, $ClcTime) = $ThePar->SetStdPar;
#    my $Clc = ClcGasd::new($BaseName, $ShowE, $ShowT, $ClcLayer, $ClcTime, $TimeCoef);
#    return $Clc;
#}   ##ClcEksp


my ($workDir, $cfgFile, $matterName, $baseCfg, $resultDirName) = @ARGV;
my $Cfg = CfgReader::new($workDir, $cfgFile, $baseCfg, $matterName, $resultDirName);
my $wrk_dir=$Cfg->GetClcDir;
#die "was $wrk_dir got ".CfgReader::MakeWinName($wrk_dir)."\n";
system("mkdir -p $wrk_dir");
print Dumper($Cfg);
EosMarch::run($Cfg);




