use strict;
use warnings;
require AnalyzeData;
package MakeCurves;
use IO::File;
###########################################################################
sub new     #01.09.2005 13:04
############################################################################
 {
    my ($Temp, $Hug, $Matter, $MinDenc, $MaxDenc, $MinPres, $MaxPres, $NumPnt, $OutPrefix) = @_;
    my $Curves = PackParams($Temp, $Hug, $Matter, $MinDenc, $MaxDenc, $MinPres, $MaxPres, $NumPnt);
    my $Params = {Curves=>$Curves, OutPrefix=>$OutPrefix};
    bless $Params, "MakeCurves";
    return $Params;
}   ##new

############################################################################
sub PackParams       #11/06/2007 12:05
############################################################################
 {
    my ($Temp, $Hug, $Matter, $MinDenc, $MaxDenc, $MinPres, $MaxPres, $NumPnt) = @_;
    my $Curves = [];
    for(my $i = 0;$i<int(@{$Temp});$i++){
        $Curves->[$i] = {Mat=>$Matter, T=>$Temp->[$i], MinD=>$MinDenc, MaxD=>$MaxDenc, Num=>$NumPnt, Curve=>"Temp"};
    }
    for(my $i = 0;$i<int(@{$Hug});$i++){
        my $p = int(@{$Curves});
        $Curves->[$p] = {Mat=>$Matter, MinP=>$MinPres, MaxP=>$MaxPres, Num=>$NumPnt,
            BegD=>$Hug->[$i]{Denc}, BegE=>$Hug->[$i]{Ener}, Curve=>"Hug"};
        $Curves->[$p]{Pres} = $Hug->[$i]{Pres}     if (defined($Hug->[$i]{Pres}));
    }
    return $Curves;
}   ##PackParams

############################################################################
sub MakeTmpName     #11/06/2007 12:45
############################################################################
 {
    my ($Curve) = @_;
    my $ret = "tmp_$Curve->{Curve}";
    $ret = "$ret\_$Curve->{T}"                       if ($Curve->{Curve} eq "Temp");
    $ret = "$ret\_$Curve->{BegD}_$Curve->{BegE}"     if ($Curve->{Curve} eq "Hug");
    return $ret;
}   ##MakeTmpName
############################################################################
sub MakeStr($$)        #11/06/2007 12:39
############################################################################
 {
    my ($Curve, $this) = @_;
    my $ret;
    my $out = MakeTmpName($Curve);
    if ( $Curve->{Curve} eq "Temp" ) {
        $ret = sprintf <<EOF
URS_Curve {
    Variables {

        Matter          EOS_Savable { $Curve->{Mat}  }

        Dencity         UrsCurve_StepClc { MinVal $Curve->{MinD} MaxVal $Curve->{MaxD}  NumDivStp $Curve->{Num}  LogScale 1 NumSame 1  Centered 0 }
        Temperature     UrsCurve_StepClc { MinVal $Curve->{T} MaxVal $Curve->{T}  NumDivStp 1  LogScale 0 NumSame 1  Centered 0 }

        Urs             UrsCurve_FreeE { NameDenc Dencity NameTemp Temperature  NameMatter Matter }
    }
    Output   URS_Curve::Output {
           FileToStore $out.res  VectorOfNames {
                Dencity Urs.Pressure
          }
    }
NumIter  $Curve->{Num} }

EOF
   ;
   if (defined($this->{CaloricUrs})) {
print "CaloricUrs\n";
        $ret = sprintf <<EOF

URS_Curve {
    Variables {

        Matter          EOS_Savable { $Curve->{Mat}  }

        Dencity         UrsCurve_StepClc { MinVal $Curve->{MinD} MaxVal $Curve->{MaxD}  NumDivStp $Curve->{Num}  LogScale 1 NumSame 1  Centered 0 }
        Temperature     UrsCurve_StepClc { MinVal $Curve->{T} MaxVal $Curve->{T}  NumDivStp 1  LogScale 0 NumSame 1  Centered 0 }

        UrsE            UrsCurve_EOS_FindE { NameDenc Dencity NameTemp Temperature  NameMatter Matter }
        Urs             UrsCurve_Caloric  {   NameDenc Dencity NameEnergy UrsE.Energy  NameMatter Matter }


    }
    Output   URS_Curve::Output {
           FileToStore $out.res  VectorOfNames {
                Dencity Urs.Pressure
          }
    }
NumIter  $Curve->{Num} }

EOF
   ;
   }



   } else {
        my ($StartP, $RecalcPres) = (0, 1);
        ($StartP, $RecalcPres) = ($Curve->{Pres}, 0)        if (defined($Curve->{Pres}));
        $ret = sprintf <<EOF
URS_Curve {
    Variables {

        Matter          EOS_Savable { $Curve->{Mat}  }

        Pressure         UrsCurve_StepClc { MinVal $Curve->{MinP} MaxVal $Curve->{MaxP}  NumDivStp $Curve->{Num}  LogScale 1 NumSame 1  Centered 0 }

        Hug             UrsCurve_EOS_Hugoniot {  NameDenc Pressure NameMatter Matter StartDenc $Curve->{BegD} StartEner $Curve->{BegE} StartPres $StartP StartVel 0 PressureDependece 1 RecalcPres $RecalcPres  }
    }
    Output   URS_Curve::Output {
           FileToStore $out.res  VectorOfNames {
                Pressure Hug.Dencity
          }
    }
NumIter  $Curve->{Num} }


EOF
   ; }
    return $ret;
}   ##MakeStr

############################################################################
sub SumHug      #12/05/2007 2:12
############################################################################
 {
    my ($InFiles, $OutFile, $Header) = @_;
    my @inF = split(" ", $InFiles);
    my (@files, $i, @fh);
    open OUT1, "> $OutFile"     or die "Could not open outfile file $OutFile:$!\n";
    for ( $i=0;$i<int(@inF);$i++ ) {
        $files[$i]{fh} = new IO::File;
        $files[$i]{fh}->open("< $inF[$i]")      or die "Could not open file $inF[$i]:$!\n";
    }
    my $n = "\x0D\x0A";
    my $l;
    print OUT1 $Header                  if (defined($Header));
    while ( defined($files[0]{fh}) && defined($l=$files[0]{fh}->getline()) ) {
        my @l = split(" ",$l);
        if ( AnalyzeData::IsNumber($l[0] ) ){
            my $Line = "$l[1] $l[0]";
            for ( $i=1;$i<int(@files);$i++ ) {
                my @add = split(" ",$files[$i]{fh}->getline());
                $Line = "$Line  $add[1]  $add[0]";
            }
            print OUT1 $Line,"$n";
        }

    }
    foreach my $fh ( @files ) { $fh->{fh}->close	if (defined($fh->{fh})); }
    close OUT1;
}   ##SumHug
############################################################################
sub MakeClc        #11/06/2007 12:39
############################################################################
 {
    my ($Params, $rawResult) = @_;
    my $file = new IO::File;
    my ($FilesTemp, $FilesHug, $TempHead, $HugHead, $TmpFiles) = ("", "", "Denc(g_cm3)/Pres(GPa)", "Pres(GPa)/Denc(g_cm3)", "");
    $HugHead = "";
    my $Curves = $Params->{Curves};
    for(my $i = 0;$i<int(@{$Curves});$i++){
        my $name = MakeTmpName($Curves->[$i]);
        $file->open("> $name.cfg" )        or die "Could not open out file $name.cfg:$!\n";
        $file->print(MakeStr($Curves->[$i], $Params));
        system("urs_curve $name.cfg");
        $TmpFiles = "$TmpFiles $name.cfg $name.res";
        $FilesTemp = "$FilesTemp $name.res",$TempHead = "$TempHead $Curves->[$i]{T}"
                        if ($Curves->[$i]{Curve} eq "Temp");
        $FilesHug = "$FilesHug $name.res",$HugHead = "$HugHead $Curves->[$i]{BegD}\_$Curves->[$i]{BegE}\_Denc $Curves->[$i]{BegD}\_$Curves->[$i]{BegE}\_Pres"
                        if ($Curves->[$i]{Curve} eq "Hug");
        $file->close;
    }
    if (!defined($rawResult) || $rawResult) {
      AnalyzeData::SumSortedFiles($FilesTemp, "$Params->{OutPrefix}.temp", $TempHead."\n");
      SumHug($FilesHug, "$Params->{OutPrefix}.hug", $HugHead."\n");
      system("rm $TmpFiles");
    }
}   ##MakeClc

############################################################################
sub GetNextWord     #11/06/2007 3:37
############################################################################
 {
    my ($file, $buf) = @_;
    return shift(@{$buf})    if ( int(@{$buf})>0 );
    my $l = $file->getline();
    return ""       if (!defined($l));
    @{$buf} = split(" ",$l);
    return GetNextWord($file, $buf);
}   ##GetNextWord
############################################################################
sub GetStrToDelim       #11/06/2007 3:40
############################################################################
 {
    my ($file, $buf, $delim) = @_;
    my @l;
    while(1){
        my $p = int(@l);
        $l[$p] = GetNextWord($file, $buf);
        return join(" ",@l)             if ( ($l[$p] eq "") || ($l[$p] eq $delim) );
    }
}   ##GetStrToDelim
############################################################################
sub ReadMatter      #11/06/2007 3:32
############################################################################
 {
    my ($Mat2PhaseFile, $Mat2PhaseName) = @_;
    my $file = new IO::File;
    $file->open("< $Mat2PhaseFile")     or die "Could not open file $Mat2PhaseFile:$!\n";
    my @l;
    while(1){
        my $l = $file->getline();
        die "Did not find $Mat2PhaseName in file $Mat2PhaseFile\n"      if (!defined($l));
        @l = split(" ", $l);
        last    if ( defined($l[0]) && (lc($l[0]) eq lc($Mat2PhaseName)) );
    }
    shift(@l);
    GetNextWord($file, \@l);
    my $MatSol = GetStrToDelim($file,\@l,"}");
    GetNextWord($file, \@l);
    my $MatLiq = GetStrToDelim($file,\@l,"}");
    my $Bnd = GetStrToDelim($file,\@l,"}");
    my @Bnd = split(" ",$Bnd);
    my $OutName = $Bnd[$#Bnd-1];
    return ($MatSol, $MatLiq, $OutName);
}   ##ReadMatter
############################################################################
sub Make2PhaseBnd       #11/06/2007 3:00
############################################################################
 {
    my ($Mat2PhaseFile, $Mat2PhaseName, $MinT, $MaxT, $MinD, $MaxD, $MinP, $MaxP, $StartP, $Err, $Num) = @_;
    my ($MatSol, $MatLiq, $OutName) = ReadMatter($Mat2PhaseFile, $Mat2PhaseName);
    my $file = new IO::File;
    $file->open("> tmp.cfg")     or die "Could not open out file tmp.cfg:$!\n";
    my $str = sprintf <<EEOF
URS_Curve {
    Variables {
        MatSol  EOS_Savable { MatterFreeE { $MatSol } }
        MatLiq  EOS_Savable { MatterFreeE { $MatLiq } }

        Temperature     UrsCurve_StepClc { MinVal $MinT MaxVal $MaxT  NumDivStp $Num  LogScale 1 NumSame 1  Centered 0 }

        BndMat  UrsCurve_PT_Bnd_Constructor { NameTemp Temperature NameMatterHghP MatLiq NameMatterLowP MatSol ClcError $Err FindPDencFrom $MinD FindPDencTo $MaxD FindGLowPres $MinP FindGHghPres $MaxP StartPres $StartP }
        BinGen  UrsCurve_PT_Bnd_Binary { NameTemp Temperature NameHghD BndMat.DencityHghP_T NameLowD BndMat.DencityLowP_T NameFileToGenerate $OutName ClcError 1e-6 }

    }

    Output   URS_Curve::Output {
        FileToStore $OutName.dat VectorOfNames {
              BinGen BndMat.Pressure_T
        }

    }
NumIter  $Num   }
EEOF
    ;
    $file->print($str);
    system("urs_curve tmp.cfg");

}   ##Make2PhaseBnd













#######################################################################
####################### Clc Single curves   ###########################
#######################################################################

#######################################################################
sub ClcIsentrope($$$$$$) {
#######################################################################
   my ($NumPnt, $FromE, $FromDenc, $ToDenc, $OutPrefix, $Matter) = @_;
   print `cat >tmp.cfg <<EOF

URS_Curve {
    Variables {
        Matter  EOS_Savable { $Matter }
        Dencity UrsCurve_StepClc { MinVal $FromDenc MaxVal $ToDenc NumDivStp $NumPnt LogScale 1 NumSame 1 Centered 0 }

        Ise     UrsCurve_EOS_Isoentrope { NameDenc Dencity NameMatter Matter StartE $FromE StartU 0 ClcU 1 }
        EOSIse  UrsCurve_Caloric { NameDenc Dencity NameEnergy Ise.Energy NameMatter Matter }
        
    }

    Output     URS_Curve::Output {
        FileToStore $OutPrefix.isentrope.$FromDenc VectorOfNames {
             Dencity EOSIse.Pressure Ise.Energy EOSIse.Temperature Ise.Velocity EOSIse.Sound 
        }
    }
    NumIter  $NumPnt
}
EOF
urs_curve tmp.cfg`;
  
}

#######################################################################
sub ClcIsotherm($$$$$$) {
#######################################################################
   my ($NumPnt, $Temp, $FromDenc, $ToDenc, $OutPrefix, $Matter) = @_;
   #my $cfg = sprintf <<EOF
   print `cat >tmp.cfg <<EOF
URS_Curve {
    Variables {
        Matter       EOS_Savable { $Matter }
        Dencity      UrsCurve_StepClc { MinVal $FromDenc MaxVal $ToDenc NumDivStp $NumPnt LogScale 1 NumSame 1 Centered 0 }
        Temperature  UrsCurve_StepClc { MinVal $Temp MaxVal $Temp NumDivStp 1 LogScale 1 NumSame $NumPnt Centered 0 }
        IsoT         UrsCurve_FreeE { NameDenc Dencity NameTemp Temperature NameMatter Matter }
        
    }

    Output     URS_Curve::Output {
        FileToStore $OutPrefix.isotherm.$Temp VectorOfNames {
             Dencity IsoT.Pressure IsoT.Energy IsoT.Sound Temperature 
        }
    }
    NumIter  $NumPnt
}

EOF
urs_curve.exe tmp.cfg`;
  
}

#######################################################################
sub ClcIsothermCaloric($$$$$$) {
#######################################################################
   my ($NumPnt, $Temp, $FromDenc, $ToDenc, $OutPrefix, $Matter) = @_;
   #my $cfg = sprintf <<EOF
   print `cat >tmp.cfg <<EOF

URS_Curve {
    Variables {
        Matter       EOS_Savable { $Matter }
        Dencity      UrsCurve_StepClc { MinVal $FromDenc MaxVal $ToDenc NumDivStp $NumPnt LogScale 1 NumSame 1 Centered 0 }
        Temperature  UrsCurve_StepClc { MinVal $Temp MaxVal $Temp NumDivStp 1 LogScale 1 NumSame $NumPnt Centered 0 }

        UrsE         UrsCurve_EOS_FindE { NameDenc Dencity NameTemp Temperature  NameMatter Matter }
        Urs          UrsCurve_Caloric  {   NameDenc Dencity NameEnergy UrsE.Energy  NameMatter Matter }
        
    }

    Output     URS_Curve::Output {
        FileToStore $OutPrefix.isotherm_caloric.$Temp VectorOfNames {
             Dencity Urs.Pressure UrsE.Energy Urs.Sound Urs.Temperature 
        }
    }
    NumIter  $NumPnt
}


EOF
urs_curve.exe tmp.cfg`;
  
}

#######################################################################
sub ClcHugoniot($$$$$$$$) {
#######################################################################
   my ($NumPnt, $StartDenc, $StartEner, $StartPres, $FromPres, $ToPres, $OutPrefix, $Matter) = @_;
   #my $cfg = sprintf <<EOF
   print `cat >tmp.cfg <<EOF

URS_Curve {
    Variables {
        Matter       EOS_Savable { $Matter }
        Pressure     UrsCurve_StepClc { MinVal $FromPres MaxVal $ToPres  NumDivStp $NumPnt  LogScale 1 NumSame 1  Centered 0 }
        Hug          UrsCurve_EOS_Hugoniot {  NameDenc Pressure NameMatter Matter StartDenc $StartDenc StartEner $StartEner StartPres $StartPres StartVel 0 PressureDependece 1 RecalcPres 1  }
        Urs          UrsCurve_Caloric  {   NameDenc Hug.Dencity NameEnergy Hug.Energy  NameMatter Matter }
        
    }

    Output     URS_Curve::Output {
        FileToStore $OutPrefix.hugoniot.$StartDenc VectorOfNames {
            Pressure Hug.Dencity  Hug.Energy Urs.Sound Urs.Temperature Urs.Pressure
        }
    }
    NumIter  $NumPnt
}


EOF
urs_curve.exe tmp.cfg`;
  
}










#
#perl -e '
#use strict;
#use warnings;
#require MakeCurves;
#
#
#
#my ($InFile) = ($ARGV[0]);
#
#my $Temp = [5];
#my $Hug = [{Denc=>0.1223, Ener=>0, Pres=>0}];
#$Temp = [];
##$Hug = [];
#
#my $Matter1 = " MatterFreeE { FreeEIdeal { Material_File mat.he Substance HeIdeal } } ";
#my $Matter = " MatterFreeE { FreeESpl { HeOCP.spl   } } ";
#my $OutPrefix= "he_curves";
#my $NumPnt = 500;
#my $T = 5;
#
#my ($MinDenc, $MaxDenc, $MinPres, $MaxPres)=(1.1e-3, 3,1e-3,200);
#my $Curves = MakeCurves::new($Temp, $Hug, $Matter1, $MinDenc, $MaxDenc, $MinPres, $MaxPres, $NumPnt, $OutPrefix);
#$Curves->{CaloricUrs} = 1;
#$Curves->MakeClc();
#
#
##MakeCurves::ClcIsentrope($NumPnt, $FromE(FromT), $FromDenc, $ToDenc, $OutPrefix, $Matter);
#
#
#MakeCurves::ClcIsotherm(100, $T, 0.01, 2, $OutPrefix, $Matter1);
##MakeCurves::ClcIsothermCaloric(100, $T, 0.01, 2, $OutPrefix, $Matter);
##MakeCurves::ClcIsentrope(100, 0.22, 0.8, 5, $OutPrefix, $Matter);
#
#
#'
#
1;
