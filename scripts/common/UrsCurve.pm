
use strict;
use warnings;
use Data::Dumper;
require CfgReader;

package UrsCurve;
##########################################################
######### Base for EosMarch               ################
######### Generating / Testing XY splines ################
##########################################################
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
        my ($min, $max, $num, $logS, $numSame) = split(":", $Cfg->{$n});
        $max = $min if (!defined($max));
        $num = 1 if (!defined($num));
        $logS = 0 if (!defined($logS));
        $numSame = 1 if (!defined($numSame));
        $Cfg->{$n} = {"MinVal" => $min, "MaxVal" => $max, "NumDivStp" => $num,  "LogScale" => $logS, "NumSamePnt" => $numSame};
    }
}

sub SplGenClc($) {
    return SplClc(@_);
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



sub SplGen($) {
    my ($Cfg) = @_;
    print Data::Dumper::Dumper($Cfg);
    
    Check($Cfg->{Cfg}, "DatFile:SplNum:SplMis:ResSpl");
    my @num = `cat $Cfg->{Cfg}{DatFile} | wc -l`;
    my $outCol = $Cfg->{Cfg}{DatColNames};
    $outCol =~ s/:/ /g;
    open(OUT, ">".CfgReader::MakeWinName($Cfg->GetOutBaseName()).".cfg");
    my $OutName = CfgReader::MakeWinName($Cfg->GetOutBaseName()).".dat";
    my $DataFile = CfgReader::MakeWinName($Cfg->{Cfg}{DatFile});
    my $SplFile = CfgReader::MakeWinName($Cfg->{Cfg}{ResSpl});
    print OUT <<EOF 
URS_Curve {
    Variables {
        Dat   UrsCurve_FileReader {  FileName  $DataFile DataNames { X Y  } DefaultValue  0  } 

        SplGen UrsCurve_ManyVarFunction { 
          InputVal_Var:Clc { Dat.X:X Dat.Y:Y } ManyVarFunction  Spl2DGenerator  { 
              SplineFile  $SplFile GenerateSpline 1 SplineDescr Spline SplineClass CurveSpline GenNumX $Cfg->{Cfg}{SplNum}  GenMisf $Cfg->{Cfg}{SplMis}
          } 
       } 
       SplTst UrsCurve_ManyVarFunction { 
          InputVal_Var:Clc { Dat.X:X } ManyVarFunction  Spl2DGenerator  { 
              SplineFile  $DataFile GenerateSpline 2 SplineDescr Spline SplineClass CurveSpline GenNumX $Cfg->{Cfg}{SplNum}  GenMisf $Cfg->{Cfg}{SplMis}
          } 
       } 
        
    }

    Output   URS_Curve::Output {
        FileToStore $OutName VectorOfNames {
            Dat.X Dat.Y SplTst.Y SplGen.NULL
        }
    }
    NumIter $num[0]
}

EOF
;   close(OUT);
}

    # Config for Spl2DGenerator:
    #   Spl2DGenerator { 
    #     SplineFile  splFile.spl GenerateSpline 0 SplineDescr Spline SplineClass
    # CurveSpline GenNumX  0  GenMisf  0 
    # } 
    # 
    #
    #Class provides help:
    #Class for generating and calculating splines. To make spline define
    # <X> <Y> <Z>? <W>?. Work in 3 modes GenerateSpline: 0 - read spline,
    # calculate points according to it (define x y?- get y z?). 1 - call
    # with defined (x,y,z?) - will memorise data, create spline in the 
    #destructor. 2 - in the SplFileName file - will be points (x,y,z?) 
    #- calculate spline accordingly, run with (x,y?) - clc y Spline will
    # not be saved.


1;