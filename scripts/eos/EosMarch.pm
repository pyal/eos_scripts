use strict;
use warnings;

require CfgReader;
package EosMarch;
use Data::Dumper;
require UrsCurve;

sub P_RE($) {
    my ($Cfg) = @_;
    print Dumper($Cfg);
    UrsCurve::Check($Cfg->{Cfg}, "R:E:Mat:Out");
    UrsCurve::RebuildBnd($Cfg->{Cfg}, "R:E");
    my $matter = join(" ", @{$Cfg->GetMatter($Cfg->{Cfg}{Mat})});
    my %rename = (P => "EOS.Pressure", R=> "Dencity", E=>"Energy", S=>"EOS.Sound", T=>"EOS.Temperature");
    my @out = map { if (defined($rename{$_})) {$rename{$_}} else { $_ } } split(":", $Cfg->{Cfg}{Out});
    my $out = join(" ", @out);
    my $num = $Cfg->{Cfg}{R}{NumDivStp} * $Cfg->{Cfg}{E}{NumDivStp};
    open(OUT, ">".CfgReader::MakeWinName($Cfg->GetOutBaseName()).".cfg");
    my $OutName = CfgReader::MakeWinName($Cfg->GetOutBaseName()).".dat";
    print OUT <<EOF 
URS_Curve {
    Variables {
        Matter  EOS_Savable { $matter }
        Dencity UrsCurve_StepClc { MinVal $Cfg->{Cfg}{R}{MinVal} MaxVal $Cfg->{Cfg}{R}{MaxVal} NumDivStp $Cfg->{Cfg}{R}{NumDivStp} LogScale $Cfg->{Cfg}{R}{LogScale} NumSame 1 Centered 0 }
        Energy  UrsCurve_StepClc { MinVal $Cfg->{Cfg}{E}{MinVal} MaxVal $Cfg->{Cfg}{E}{MaxVal} NumDivStp $Cfg->{Cfg}{E}{NumDivStp} LogScale $Cfg->{Cfg}{E}{LogScale} NumSame 1 Centered 0 }

        EOS  UrsCurve_Caloric { NameDenc Dencity NameEnergy Energy NameMatter Matter }
        
    }

    Output     URS_Curve::Output {
        FileToStore $OutName VectorOfNames {
             $out
        }
    }
    NumIter  $num
}

EOF
;   close(OUT);
}


sub Isentrope($) {
    my ($Cfg) = @_;
    print Dumper($Cfg);
    UrsCurve::Check($Cfg->{Cfg}, "R:Mat:Out:StartE:StartU");
    UrsCurve::RebuildBnd($Cfg->{Cfg}, "R");
    my $matter = join(" ", @{$Cfg->GetMatter($Cfg->{Cfg}{Mat})});
    my %rename = (P => "EOS.Pressure", R=> "Dencity", E=>"Isent.Energy", T=>"EOS.Temperature", U=>"Isent.Velocity", S=>"EOS.Sound");
    my @out = map { if (defined($rename{$_})) {$rename{$_}} else { $_ } } split(":", $Cfg->{Cfg}{Out});
    my $out = join(" ", @out);
    my $num = $Cfg->{Cfg}{R}{NumDivStp};
    open(OUT, ">".CfgReader::MakeWinName($Cfg->GetOutBaseName()).".cfg");
    my $OutName = CfgReader::MakeWinName($Cfg->GetOutBaseName()).".dat";
    print OUT <<EOF 
URS_Curve {
    Variables {
        Matter  EOS_Savable { $matter }
        Dencity UrsCurve_StepClc { MinVal $Cfg->{Cfg}{R}{MinVal} MaxVal $Cfg->{Cfg}{R}{MaxVal} NumDivStp $Cfg->{Cfg}{R}{NumDivStp} LogScale $Cfg->{Cfg}{R}{LogScale} NumSame 1 Centered 0 }

        Isent   UrsCurve_EOS_Isoentrope { NameDenc Dencity NameMatter Matter StartE $Cfg->{Cfg}{StartE} StartU $Cfg->{Cfg}{StartU} ClcU 1 } 

        EOS  UrsCurve_Caloric { NameDenc Dencity NameEnergy Isent.Energy NameMatter Matter }
        
    }

    Output     URS_Curve::Output {
        FileToStore $OutName VectorOfNames {
             $out
        }
    }
    NumIter  $num
}


EOF
;   close(OUT);
}

sub HugDenc($) {
    my ($Cfg) = @_;
    print Dumper($Cfg);
    UrsCurve::Check($Cfg->{Cfg}, "R:Mat:Out:StartE:StartR");
    UrsCurve::RebuildBnd($Cfg->{Cfg}, "R");
    my $matter = join(" ", @{$Cfg->GetMatter($Cfg->{Cfg}{Mat})});
    my %rename = (P => "EOS.Pressure", R=> "Hug.Dencity", E=>"Hug.Energy", T=>"EOS.Temperature", U=>"Hug.Velocity", S=>"EOS.Sound");
    my @out = map { if (defined($rename{$_})) {$rename{$_}} else { $_ } } split(":", $Cfg->{Cfg}{Out});
    my $out = join(" ", @out);
    my $num = $Cfg->{Cfg}{R}{NumDivStp};
    open(OUT, ">".CfgReader::MakeWinName($Cfg->GetOutBaseName()).".cfg");
    my $OutName = CfgReader::MakeWinName($Cfg->GetOutBaseName()).".dat";
    print OUT <<EOF 
URS_Curve {
    Variables {
        Matter  EOS_Savable { $matter }
        Dencity UrsCurve_StepClc { MinVal $Cfg->{Cfg}{R}{MinVal} MaxVal $Cfg->{Cfg}{R}{MaxVal} NumDivStp $Cfg->{Cfg}{R}{NumDivStp} LogScale $Cfg->{Cfg}{R}{LogScale} NumSame 1 Centered 0 }

        Hug     UrsCurve_EOS_Hugoniot {   NameDenc Dencity NameMatter Matter
                StartDenc $Cfg->{Cfg}{StartR} StartEner $Cfg->{Cfg}{StartE} StartPres 0 StartVel 0. PressureDependece 0 RecalcPres 1 } 

        EOS  UrsCurve_Caloric { NameDenc Hug.Dencity NameEnergy Hug.Energy NameMatter Matter }
        
    }

    Output     URS_Curve::Output {
        FileToStore $OutName VectorOfNames {
             $out
        }
    }
    NumIter  $num
}

EOF
;   close(OUT);
}

sub HugPres($) {
    my ($Cfg) = @_;
    print Dumper($Cfg);
    UrsCurve::Check($Cfg->{Cfg}, "P:Mat:Out:StartE:StartR");
    UrsCurve::RebuildBnd($Cfg->{Cfg}, "P");
    #my $matter = join(" ", @{$Cfg->GetMatter($Cfg->{Cfg}{Mat})});
    my $matter = $Cfg->GetMatter($Cfg->{Cfg}{Mat})->[0];
    my %rename = (P => "EOS.Pressure", R=> "Hug.Dencity", E=>"Hug.Energy", T=>"EOS.Temperature", U=>"Hug.Velocity", S=>"EOS.Sound");
    my @out = map { if (defined($rename{$_})) {$rename{$_}} else { $_ } } split(":", $Cfg->{Cfg}{Out});
    my $out = join(" ", @out);
    my $num = $Cfg->{Cfg}{P}{NumDivStp};
    open(OUT, ">".CfgReader::MakeWinName($Cfg->GetOutBaseName()).".cfg");
    my $OutName = CfgReader::MakeWinName($Cfg->GetOutBaseName()).".dat";
    print OUT <<EOF 
URS_Curve {
    Variables {
        Matter  EOS_Savable { $matter }
        Pressure UrsCurve_StepClc { MinVal $Cfg->{Cfg}{P}{MinVal} MaxVal $Cfg->{Cfg}{P}{MaxVal} NumDivStp $Cfg->{Cfg}{P}{NumDivStp} LogScale $Cfg->{Cfg}{P}{LogScale} NumSame 1 Centered 0 }

        Hug     UrsCurve_EOS_Hugoniot {   NameDenc Pressure NameMatter Matter
                StartDenc $Cfg->{Cfg}{StartR} StartEner $Cfg->{Cfg}{StartE} StartPres 0 StartVel 0. PressureDependece 1 RecalcPres 1 } 

        EOS  UrsCurve_Caloric { NameDenc Hug.Dencity NameEnergy Hug.Energy NameMatter Matter }
        
    }

    Output     URS_Curve::Output {
        FileToStore $OutName VectorOfNames {
             $out
        }
    }
    NumIter  $num
}

EOF
;   close(OUT);
}


########################33
### Adding curves
##########################

sub P_RT($) {
    my ($Cfg) = @_;
    print Dumper($Cfg);
    UrsCurve::Check($Cfg->{Cfg}, "R:T:Mat:Out");
    UrsCurve::RebuildBnd($Cfg->{Cfg}, "R:T");
    #my $matter = join(" ", @{$Cfg->GetMatter($Cfg->{Cfg}{Mat})});
    my $matter = $Cfg->GetMatter($Cfg->{Cfg}{Mat})->[0];
    my %rename = (P => "EOS.Pressure", R=> "Dencity", E=>"EOS.Energy", S=>"EOS.Sound", T=>"Temperature");
    my @out = map { if (defined($rename{$_})) {$rename{$_}} else { $_ } } split(":", $Cfg->{Cfg}{Out});
    my $out = join(" ", @out);
    my $num = $Cfg->{Cfg}{R}{NumDivStp} * $Cfg->{Cfg}{T}{NumDivStp};
    open(OUT, ">".CfgReader::MakeWinName($Cfg->GetOutBaseName()).".cfg");
    my $OutName = CfgReader::MakeWinName($Cfg->GetOutBaseName()).".dat";
    print OUT <<EOF 
URS_Curve {
    Variables {
        Matter  EOS_Savable { $matter }
        Dencity UrsCurve_StepClc { MinVal $Cfg->{Cfg}{R}{MinVal} MaxVal $Cfg->{Cfg}{R}{MaxVal} NumDivStp $Cfg->{Cfg}{R}{NumDivStp} LogScale $Cfg->{Cfg}{R}{LogScale} NumSame 1 Centered 0 }
        Temperature  UrsCurve_StepClc { MinVal $Cfg->{Cfg}{T}{MinVal} MaxVal $Cfg->{Cfg}{T}{MaxVal} NumDivStp $Cfg->{Cfg}{T}{NumDivStp} LogScale $Cfg->{Cfg}{T}{LogScale} NumSame 1 Centered 0 }

        EOS  UrsCurve_FreeE { NameDenc Dencity NameTemp Temperature NameMatter Matter }
        
    }

    Output     URS_Curve::Output {
        FileToStore $OutName VectorOfNames {
             $out
        }
    }
    NumIter  $num
}

EOF
;   close(OUT);
}

sub P_RT_Caloric($) {
    my ($Cfg) = @_;
    print Dumper($Cfg);
    UrsCurve::Check($Cfg->{Cfg}, "R:T:Mat:Out");
    UrsCurve::RebuildBnd($Cfg->{Cfg}, "R:T");
    #my $matter = join(" ", @{$Cfg->GetMatter($Cfg->{Cfg}{Mat})});
    my $matter = $Cfg->GetMatter($Cfg->{Cfg}{Mat})->[0];
    my %rename = (P => "EOS.Pressure", R=> "Dencity", E=>"Energy", S=>"EOS.Sound", T=>"EOS.Temperature");
    my @out = map { if (defined($rename{$_})) {$rename{$_}} else { $_ } } split(":", $Cfg->{Cfg}{Out});
    my $out = join(" ", @out);
    my $num = $Cfg->{Cfg}{R}{NumDivStp} * $Cfg->{Cfg}{T}{NumDivStp};
    open(OUT, ">".CfgReader::MakeWinName($Cfg->GetOutBaseName()).".cfg");
    my $OutName = CfgReader::MakeWinName($Cfg->GetOutBaseName()).".dat";
    print OUT <<EOF 
URS_Curve {
    Variables {
        Matter  EOS_Savable { $matter }
        Dencity UrsCurve_StepClc { MinVal $Cfg->{Cfg}{R}{MinVal} MaxVal $Cfg->{Cfg}{R}{MaxVal} NumDivStp $Cfg->{Cfg}{R}{NumDivStp} LogScale $Cfg->{Cfg}{R}{LogScale} NumSame 1 Centered 0 }
        Temperature  UrsCurve_StepClc { MinVal $Cfg->{Cfg}{T}{MinVal} MaxVal $Cfg->{Cfg}{T}{MaxVal} NumDivStp $Cfg->{Cfg}{T}{NumDivStp} LogScale $Cfg->{Cfg}{T}{LogScale} NumSame 1 Centered 0 }

        UrsE            UrsCurve_EOS_FindE { NameDenc Dencity NameTemp Temperature  NameMatter Matter }
        EOS             UrsCurve_Caloric  {   NameDenc Dencity NameEnergy UrsE.Energy  NameMatter Matter }
        
    }

    Output     URS_Curve::Output {
        FileToStore $OutName VectorOfNames {
             $out
        }
    }
    NumIter  $num
}

EOF
;   close(OUT);
}












sub run($) {
    my ($Cfg) = @_;
    UrsCurve::Check($Cfg->{Cfg},"Curve");
    no strict 'refs';
    my $call = "$Cfg->{Cfg}{Curve}";
    &$call($Cfg);
    my ($wDir, $cfg) = ($Cfg->{WorkDir}, CfgReader::MakeWinName($Cfg->GetOutBaseName()));
    system("cd $wDir;urs_curve $cfg.cfg");
}

1;


#URS_Curve {
#    Variables {
#        Reader  UrsCurve_FileReader { FileName Test_Dis.sarov_multiComp.exp.dat DataNames {    } DefaultValue  0 }
#        Matter  EOS_Savable { $matter }
#        Dencity UrsCurve_StepClc { MinVal $Cfg->{R}{MinVal} MaxVal $Cfg->{R}{MaxVal} NumDivStp $Cfg->{R}{NumDivStp} LogScale $Cfg->{R}{LogScale} NumSame 1 Centered 0 }
#        Energy  UrsCurve_StepClc { MinVal $Cfg->{E}{MinVal} MaxVal $Cfg->{E}{MaxVal} NumDivStp $Cfg->{E}{NumDivStp} LogScale $Cfg->{E}{LogScale} NumSame 1 Centered 0 }
#
#        Ise     UrsCurve_EOS_Isoentrope { NameDenc Dencity NameMatter Matter StartE 14.6 StartU 0 ClcU 1 }
#        EOSIse  UrsCurve_Caloric { NameDenc Dencity NameEnergy Ise.Energy NameMatter Matter }
#        
#    }
#
#    Output     URS_Curve::Output {
#        FileToStore Test_Dis.sarov_multiComp.the.dat VectorOfNames {
#             Dencity EOSIse.Pressure Ise.Energy EOSIse.Temperature Ise.Velocity EOSIse.Sound 
#        }
#    }
#    NumIter  200
#}
