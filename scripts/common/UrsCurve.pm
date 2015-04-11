
use strict;
use warnings;
use Data::Dumper;
require CfgReader;

package UrsCurve;

sub Check($$) {
    my ($Cfg, $params) = @_;
    my @params = split(":", $params);
    foreach my $par (@params) {
        print(Data::Dumper::Dumper($Cfg)), die("Have to define $par\n")  if (!defined($Cfg->{$par}));
    }
}
sub RebuildBnd($$) {
    my ($Cfg, $names) = @_;
    my @names = split(":", $names);
    foreach my $n (split(":", $names)) {
        my ($min, $max, $num, $logS) = split(":", $Cfg->{$n});
        $max = $min if (!defined($max));
        $num = 1 if (!defined($num));
        $logS = 0 if (!defined($logS));
        $Cfg->{$n} = {"MinVal" => $min, "MaxVal" => $max, "NumDivStp" => $num,  "LogScale" => $logS};
    }
}

sub SplClc($) {
    my ($Cfg) = @_;
    print Data::Dumper::Dumper($Cfg);
    Check($Cfg->{Cfg}, "X:SplDat:SplNum:SplMis");
    RebuildBnd($Cfg->{Cfg}, "X");
    my $num = $Cfg->{Cfg}{X}{NumDivStp};
    open(OUT, ">".CfgReader::MakeWinName($Cfg->GetOutBaseName()).".cfg");
    my $OutName = CfgReader::MakeWinName($Cfg->GetOutBaseName()).".dat";
    print OUT <<EOF 
URS_Curve {
    Variables {
        X UrsCurve_StepClc { MinVal $Cfg->{Cfg}{X}{MinVal} MaxVal $Cfg->{Cfg}{X}{MaxVal} NumDivStp $Cfg->{Cfg}{X}{NumDivStp} LogScale $Cfg->{Cfg}{X}{LogScale} NumSame 1 Centered 0 }

       Spl UrsCurve_ManyVarFunction { 
          InputVal_Var:Clc { X:X } ManyVarFunction  Spl2DGenerator  { 
              SplineFile  $Cfg->{Cfg}{SplDat} GenerateSpline 2 SplineDescr Spline SplineClass CurveSpline GenNumX $Cfg->{Cfg}{SplNum}  GenMisf $Cfg->{Cfg}{SplMis}
          } 
       } 
        
    }

    Output   URS_Curve::Output {
        FileToStore $OutName VectorOfNames {
             X Spl.Y
        }
    }
    NumIter $num
}

EOF
;   close(OUT);
}


1;