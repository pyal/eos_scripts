use strict;
use warnings;
package ClcGasd;
use IO::File;
###########################################################################
sub new     #01.09.2005 13:04
############################################################################
 {
    my ($ClcName, $ShowE, $ShowT, $ClcLayer, $ClcTime, $TimeCoef) = @_;
    my $Params = PackParams($ClcName, $ShowE, $ShowT, $ClcLayer, $ClcTime, $TimeCoef);
#    my $Head = geobase_head::new(); my ($r) = { "Head" =>$Head };
    bless $Params, "ClcGasd";
    return $Params;
}   ##new

############################################################################
sub ClcAssemblyConfig       #09/19/2007 11:07
############################################################################
 {
    my ($Par) = @_;

    my @ClcLayer = @{$Par->{ClcLayer}};
    my $ClcTime = $Par->{ClcTime};
    my $EnergyInput = $ClcTime->{EnergyInput};
    $EnergyInput =~ s/:/ /g;
    my @Bnd;
    $Bnd[0] = 0;
    my $Matter_Boundaries="";
    my $Matters="";
    my $Parameters="";
    for(my $it=0;$it<int(@ClcLayer);$it++){
PrintHash($ClcLayer[$it]);
        $Bnd[$it+1] = $Bnd[$it] + $ClcLayer[$it]{N};
        $Matter_Boundaries = $Matter_Boundaries."  ".$Bnd[$it+1]    if ($it!=int(@ClcLayer)-1);
        $Matters = $Matters."\n"                if ($it>0);
        $Matters = $Matters.$ClcLayer[$it]{M};
        my $t = $it+1;
        $Parameters = $Parameters." P[$t]   $ClcLayer[$it]{P}  D[$t] $ClcLayer[$it]{D}     E[$t]  $ClcLayer[$it]{E}    V[$t]  $ClcLayer[$it]{V} Length[$t] $ClcLayer[$it]{L}\n";
    }
    my ($TimeStp, $TimeWrite, $EndTime) = ( $ClcTime->{TimeStp}/$Par->{TimeCoef}, $ClcTime->{TimeWrite}/$Par->{TimeCoef}, $ClcTime->{EndTime}/$Par->{TimeCoef} );
        open(OUT,">$Par->{ClcName}")            or die "Could not open file $Par->{ClcName}:$!\n";
    print OUT <<EOF
BegTime 0 TimeStp $TimeStp TimeWrite $TimeWrite PresDerivCoef 0.7 EndTime $EndTime $EnergyInput
NumPnt   $Bnd[$#Bnd]  LftPnt   0  RgtPnt   1  NumIntPar $ClcTime->{NumIntPar}
LftBnd_Free 1 RgtBnd_Free 1 TimeStability $ClcTime->{TimeStability}
Viscouse 0.7  SecondVisc 0
NumMatters $#Bnd Matter_Boundaries $Matter_Boundaries
$Matters
bad
Parameters
$Parameters
EOF
}   ##ClcAssemblyConfig

############################################################################
sub ClcAssembly       #09/19/2007 11:07
############################################################################
 {
    my ($Par) = @_;
    ClcAssemblyConfig($Par);

    system("cell_dat.exe $Par->{ClcName} $Par->{ClcName}.ck /l ");
    system("cell_kru.exe $Par->{ClcName}.ck $Par->{ClcName}.dat ");
}   ##ClcAssembly

############################################################################
sub ClcAssemblyPolyTest       #09/19/2007 11:07
############################################################################
 {
    my ($Par, $marcher) = @_;
    ClcAssemblyConfig($Par);
    print "Executing:\npoly_test config Topology $Par->{ClcName}  Config $Par->{ClcName}.wil\n";
    system("poly_test config Topology $Par->{ClcName}  Config $Par->{ClcName}.wil $marcher");
    print "Executing:\npoly_test march Config $Par->{ClcName}.wil\n";
    system("poly_test march Config $Par->{ClcName}.wil ");
}   ##ClcAssemblyWilkins

############################################################################
sub ClcAssemblyWilkins       #09/19/2007 11:07
############################################################################
 {
    my ($Par, $marcher) = @_;
    ClcAssemblyPolyTest($Par, "Marcher Wilkins");
}   ##ClcAssemblyWilkins


############################################################################
sub ClcAssemblyIntegral       #09/19/2007 11:07
############################################################################
 {
    my ($Par) = @_;
    ClcAssemblyPolyTest($Par, "Marcher Integral");
}   ##ClcAssemblyIntegral

############################################################################
sub GetPntE		#09/19/2007 11:11
############################################################################
 {
    my ($Par, $PntNum) = @_;
	my ($tmp_name, $conf_name, $res_name) = ("tmp.dat", "show.cfg", "show_pnt_dat");
#	my $IntStr = "";
#	for(my $i = 0;$i<$Par->{ClcTime}{NumIntPar};$i++){
#		$IntStr = "$IntStr Name1 Velocity  Color1 13 Show 1\n";
#	}
#	my $NumCurve = 5 + $Par->{ClcTime}{NumIntPar};
#	open(OUT,">$conf_name");
#	print OUT <<EOF
#NumCurve $NumCurve XCurve  1
#x_min  0  x_max  11 y_min  0  y_max  10
#Name1 Pos  Color1 10 Show 1
#Name1 Pressure  Color1 10 Show 1
#Name1 Dencity  Color1 11 Show 1
#Name1 Energy  Color1 12 Show 1
#Name1 Velocity  Color1 13 Show 1
#$IntStr
#EOF
#	;unlink($tmp_name);
#	rename("$Par->{ClcName}.dat", $tmp_name);
#	system("show.exe $tmp_name $conf_name /g$PntNum");
#    rename($tmp_name, "$Par->{ClcName}.dat");
   system("ivl_cvt.exe show \"In $Par->{ClcName}.dat Out $res_name Pnt $PntNum\" ");
    if (!defined($Par->{TimeCoef})){
        rename("$res_name.$PntNum", "$Par->{ClcName}.$PntNum");
    } else {
        open II, "<$res_name.$PntNum"           or die "Could not open in file $res_name.$PntNum:$!\n";
        open OO, ">$Par->{ClcName}.$PntNum"           or die "Could not open out file $Par->{ClcName}.$PntNum:$!\n";
        my $n = "\x0D\x0A";
        my $tmp;
        while(defined($tmp=<II>)){
            my @l = split(" ",$tmp);
            if (!IsNumber($l[0])){
                print OO $tmp;
                next;
            }
            $l[0]*=$Par->{TimeCoef};
            print OO join("\t ",@l),"$n";
        }
        close OO;close II;
        #unlink("$res_name.$PntNum");
    }
#die;
}	##GetPntE

############################################################################
sub GetPntT		#09/19/2007 11:32
############################################################################
 {
    my ($Par, $PntNum, $MatterName) = @_;
    GetPntE($Par, $PntNum);
	open(IN,"<$Par->{ClcName}.$PntNum")		or die "Could not open file $Par->{ClcName}.$PntNum : $!\n";
	my $NumPnt=0;
	while(<IN>){$NumPnt++;}
#print "$NumPnt\n";
    $NumPnt--;
	my ($IntPar, $ReaderIntPar) = ("", "");
	for(my $i = 0;$i<$Par->{ClcTime}{NumIntPar};$i++){
		$IntPar = "$IntPar IntPar$i";
		$ReaderIntPar = "$ReaderIntPar Reader.IntPar$i";
	}
	my ($conf_name) = ("urs.cfg");
	open(OUT,">$conf_name");
	print OUT <<EOF
 URS_Curve {
    Variables {
        Mat       EOS_Savable         { $MatterName }
        IsoE      UrsCurve_Caloric    { NameDenc Reader.Denc NameEnergy Reader.Ener  NameMatter Mat }

        Reader    UrsCurve_FileReader { FileName $Par->{ClcName}.$PntNum
			DataNames {  Time Pos Pres Denc Ener Vel $IntPar } DefaultValue  0
		}
    }

    Output      URS_Curve::Output {
        FileToStore $Par->{ClcName}.$PntNum.t  VectorOfNames {
             Reader.Time  Reader.Pos Reader.Pres Reader.Denc IsoE.Temperature Reader.Ener IsoE.Sound Reader.Vel $ReaderIntPar
        }
    }
NumIter  $NumPnt    }

EOF
	;system("urs_curve.exe $conf_name");
    unlink("$Par->{ClcName}.$PntNum");
}	##GetPntT

############################################################################
sub GetPntTInt		#09/19/2007 11:32
############################################################################
 {
    my ($Par, $PntNum, $MatterName, $IntNames) = @_;
    GetPntE($Par, $PntNum);
	open(IN,"<$Par->{ClcName}.$PntNum")		or die "Could not open file $Par->{ClcName}.$PntNum : $!\n";
	my $NumPnt=0;
	while(<IN>){$NumPnt++;}
#print "$NumPnt\n";
    $NumPnt--;
	my ($IntPar, $ReaderIntPar, $IntMap) = ("", "", "" );
	for(my $i = 0;$i<$Par->{ClcTime}{NumIntPar};$i++){
		$IntPar = "$IntPar IntPar$i";
		$ReaderIntPar = "$ReaderIntPar Reader.IntPar$i";
		$IntMap = "$IntMap Reader.IntPar$i $IntNames->[$i]"
	}
	my ($conf_name) = ("urs.cfg");
	open(OUT,">$conf_name");
	print OUT <<EOF
 URS_Curve {
    Variables {
        Mat       EOS_Savable         { $MatterName }
        IsoE      UrsCurve_InOut    { NameMatter Mat Input_Mat2Clc_Name ( Reader.Denc Dencity Reader.Ener  Energy  $IntMap ) }

        Reader    UrsCurve_FileReader { FileName $Par->{ClcName}.$PntNum
			DataNames {  Time Pos Pres Denc Ener Vel $IntPar } DefaultValue  0
		}
    }

    Output      URS_Curve::Output {
        FileToStore $Par->{ClcName}.$PntNum.t  VectorOfNames {
             Reader.Time  Reader.Pos Reader.Pres Reader.Denc IsoE.Temperature Reader.Ener IsoE.Sound Reader.Vel $ReaderIntPar
        }
    }
NumIter  $NumPnt    }

EOF
	;system("urs_curve.exe $conf_name");
    unlink("$Par->{ClcName}.$PntNum");
}	##GetPntTInt

############################################################################
sub ClcPntNum		#09/19/2007 1:24
############################################################################
 {
	my ($Par, $Layer, $PntNum) = @_;
	$Layer--;
	my @ClcLayer = @{$Par->{ClcLayer}};
	die "Bad Layer ".($Layer+1).". Max Layer is ".int(@ClcLayer)."\n"	if ($Layer>=int(@ClcLayer) || $Layer<0);
	my $s = 0;
	for(my $it=0;$it<$Layer;$it++){
		$s += $ClcLayer[$it]{N};
	}
	$PntNum = $ClcLayer[$Layer]{N} + $PntNum		if ($PntNum<0);
	return ($s+$PntNum, $ClcLayer[$Layer]{M});

}	##ClcPntNum
############################################################################
sub GetAllPnt		#09/19/2007 1:17
############################################################################
 {
    my ($Par, $IntMatLayer, $IntMatName, $IntNames) = @_;
	my @PntE = @{$Par->{ShowE}};
	my @PntT = @{$Par->{ShowT}};
	for(my $it=0;$it<int(@PntT);$it+=2){
		my @NumMatter = ClcPntNum($Par, $PntT[$it], $PntT[$it+1]);
		if ( !defined($IntMatLayer) || $IntMatLayer!=$PntT[$it] ){
            GetPntT($Par, $NumMatter[0], $NumMatter[1]);
		} else {
            GetPntTInt($Par, $NumMatter[0], $IntMatName, $IntNames);
		}
	}
    for(my $it=0;$it<int(@PntE);$it+=2){
        my @NumMatter = ClcPntNum($Par, $PntE[$it], $PntE[$it+1]);
        GetPntE($Par, $NumMatter[0]);
    }
}	##GetAllPnt
############################################################################
sub GetAllPntNums       #10/31/2007 5:00
############################################################################
 {
    my ($Par, $Pnt) = @_;
    my $ret = [];
    for(my $it=0;$it<int(@{$Pnt});$it+=2){
        my @a = ClcPntNum($Par, $Pnt->[$it], $Pnt->[$it+1]);
        $ret->[int(@{$ret})] = $a[0];
    }
    return $ret;
}   ##GetAllPntNums
############################################################################
sub PackParams		#09/19/2007 12:37
############################################################################
 {
    my ($ClcName, $ShowE, $ShowT, $ClcLayer, $ClcTime, $TimeCoef) = @_;
	my %Par;
    #my $modClcName = $ClcName;
    $ClcName =~ s/\/cygdrive\/(.)/$1\:/g;
	$Par{ClcName} = $ClcName;
	$Par{ClcLayer} = $ClcLayer;
	$Par{ShowE} = $ShowE;
	$Par{ShowT} = $ShowT;
	$Par{ClcTime} = $ClcTime;
	$Par{ClcTime}{NumIntPar} = 0			if (!defined($Par{ClcTime}{NumIntPar}));
    $Par{TimeCoef} = 1;
    $Par{TimeCoef} = $TimeCoef              if (defined($TimeCoef));
	return \%Par;
}	##PackParams


############################################################################
sub SumFiles_        #10/31/2007 2:29
############################################################################
 {
    my ($in_par, $res_name) = @_;
    my @files;
    my ($i, $it);
    my $n = "\x0D\x0A";
    my $out = new IO::File;
    $out->open("> $res_name")      or die "Could not open out file $res_name:$!\n";
    $out->print("Time/Pnt ");
    for( $i=0;$i<int(@{$in_par});$i++ ) {
       $files[$i] = new IO::File;
       $files[$i]->open("< $in_par->[$i]{InName}")      or die "Could not open in file $in_par->[$i]{InName}:$!\n";
       $out->print("   $in_par->[$i]{Header}");
    }
    $out->print("$n");
    while(1){
        #my ($l,@l) = (0,());
        my ($l,@l);
        my $NextLine = 1;
        for ( $it=0;$it<int(@files);$it++ ) {
            my $get_col = $in_par->[$it]{Column};
            last                        if (!defined($l=$files[$it]->getline()));
            @l = split(" ", $l);
            last                        if (int(@l)==0);
            if ( $it==0 && !AnalyzeData::IsNumber($l[0]) ) {
                for (my $it1=1;$it1<int(@files);$it1++ ) {$files[$it1]->getline();}
                $NextLine = 0;
                last;
            }
            $out->print( "$l[0]   " )       if ($it==0);
            my $x = "\"\"";
            $x = $l[$get_col]                  if (defined($l[$get_col]));
            $out->print("$x   ");
        }
        last        if (!defined($l));
        $out->print( "$n")                  if ($NextLine);
    }
    for ( $it=0;$it<int(@files);$it++ ) { $files[$it]->close(); }
    $out->close;
}   ##SumFiles_
############################################################################
sub SumFiles        #10/31/2007 6:26
############################################################################
 {
    my ($Par) = @_;
    my $BaseName = $Par->{ClcName};
    my $ShowE = $Par->GetAllPntNums($Par->{ShowE});
    my $ShowT = $Par->GetAllPntNums($Par->{ShowT});
    my ($temp, $pres, $denc, $ener, $vel, $pos) = ([], [], [], [], [], [], []);
    my $i;
    foreach $i (@{$ShowT}) {
        $pres->[int(@{$pres})] = {InName=>"$BaseName.$i.t", Header=>$i, Column=>2};
        $denc->[int(@{$denc})] = {InName=>"$BaseName.$i.t", Header=>$i, Column=>3};
        $temp->[int(@{$temp})] = {InName=>"$BaseName.$i.t", Header=>$i, Column=>4};
        $ener->[int(@{$ener})] = {InName=>"$BaseName.$i.t", Header=>$i, Column=>5};
        $vel->[int(@{$vel})] = {InName=>"$BaseName.$i.t", Header=>$i, Column=>7};
        $pos->[int(@{$pos})] = {InName=>"$BaseName.$i.t", Header=>$i, Column=>1};
    }
    foreach $i (@{$ShowE}) {
        $pres->[int(@{$pres})] = {InName=>"$BaseName.$i", Header=>$i, Column=>2};
        $denc->[int(@{$denc})] = {InName=>"$BaseName.$i", Header=>$i, Column=>3};
        $ener->[int(@{$ener})] = {InName=>"$BaseName.$i", Header=>$i, Column=>4};
        $vel->[int(@{$vel})] = {InName=>"$BaseName.$i", Header=>$i, Column=>5};
        $pos->[int(@{$pos})] = {InName=>"$BaseName.$i", Header=>$i, Column=>1};
    }
    @{$pres} = sort { $a->{Header} <=> $b->{Header} } @{$pres};
    @{$temp} = sort { $a->{Header} <=> $b->{Header} } @{$temp};
    @{$denc} = sort { $a->{Header} <=> $b->{Header} } @{$denc};
    @{$ener} = sort { $a->{Header} <=> $b->{Header} } @{$ener};
    @{$vel} = sort { $a->{Header} <=> $b->{Header} } @{$vel};
    @{$pos} = sort { $a->{Header} <=> $b->{Header} } @{$pos};
    SumFiles_($pres, "$BaseName.Pressure");
    SumFiles_($temp, "$BaseName.Temperature");
    SumFiles_($denc, "$BaseName.Density");
    SumFiles_($ener, "$BaseName.Energy");
    SumFiles_($vel, "$BaseName.Velocity");
    SumFiles_($pos, "$BaseName.Position");
 }



############################################################################
sub PrintHash		#09/18/2007 7:04
############################################################################
 {
	my ($h) = @_;
	my $Res="";
	for my $key (sort keys(%{$h}) ) {
		my $val = $h->{$key};
#	while ( my ($key, $val) = each(%{$h}) ) {
		$Res = $Res."<$key> => <$val>\n";
	}
	return $Res;
}	##PrintHash

sub IsNumber {
        return 0                if (!defined($_[0]));
        $_[0] =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/;
}
 sub max {
      my $max = pop(@_);
      foreach my $foo (@_) {
          $max = $foo if IsNumber($foo) && $max < $foo;
      }
      $max;
  }
 sub min {
      my $min = pop(@_);
      foreach my $foo (@_) {
          $min = $foo if IsNumber($foo) && $min > $foo;
      }
      $min;
  }


############################################################################
sub SolveDenc  #09/18/2007 6:38
############################################################################
 {
# $Mat = FreeEIdeal   {  Material_File material.cfg Substance  FreeEIdealHe   }
 my ($Phe, $Mat, $Temp, $NumPnt) = @_;
 $Temp = 290                            if (!defined($Temp));
 $NumPnt = 1000                         if (!defined($NumPnt));
 open(OUT,">urs.cfg");
# my $NumPnt = 1000;
 print OUT <<EOF

 URS_Curve {
    Variables {

        Mat       EOS_Savable {   MatterFreeE {  $Mat  }   }

        IdeG      UrsCurve_PT_clc {  NameTemp Temp NamePres Pres NameMatter Mat MinDenc 1e-005 MaxDenc 10.1 ClcError 1e-006  }

         Pres           UrsCurve_StepClc { MinVal $Phe  MaxVal $Phe  NumDivStp  1  LogScale 0 NumSame 1  Centered 0  }
         Temp           UrsCurve_StepClc { MinVal $Temp MaxVal $Temp NumDivStp  1  LogScale 0 NumSame 1  Centered 0   }

    }

    Output      URS_Curve::Output {
        FileToStore urs_pt.res  VectorOfNames {
    IdeG.Dencity IdeG.Eneregy
        }
    }
NumIter  1    }


EOF
 ; system("urs_curve urs.cfg");
 open(IN,"<urs_pt.res");
 <IN>;
 my $l = <IN>;
 my @l = split(" ",$l);
# $Par->{DenHe} = $l[0];
# $Par->{EneHe} = $l[1];
# print "Mat $Mat \n Pressure $Phe Temperature $Temp Dencity $l[0]  Energy $l[1]\n";
# die;
 return ($l[0], $l[1]);
} ##SolveHeDenc


#		Matter NumPnt Length Vel  Denc Ener Pres
#my $ClcLayer = [
#	{X=>1,M=>"MatterABu  { Material_File material.cfg Substance Steel-Tern  }",
#		N=>100, L=>1.51, V=>5.335 , D=>0, E=>0, P=>0},
#	{X=>2,M=>"MatterABu  { Material_File material.cfg Substance Steel-Tern  }",
#		N=>100, L=>1.51, V=>0 , D=>0, E=>0, P=>0},
#	{X=>3,M=>"MatterSpl  { he_ros_e.spl  }",
#		N=>100, L=>6.51, V=>0 , D=>1e-3, E=>0.1, P=>0},
#	{X=>4,M=>"MatterABu  { Material_File material.cfg Substance Z-sapphir  }",
#		N=>100, L=>5.51, V=>0 , D=>0, E=>0, P=>0}
#	];

#my $ClcTime = { TimeStp=> 1e-3, TimeWrite=> 5, EndTime=> 2000, TimeStability=>0.01, NumIntPar=>0 };

#my $ShowE = [
#	4, 5 ,
#	4,-5 ,
#	2,-5
#	];
#my $ShowT = [
#	3, 5 ,
#	3,-5 ,
#	3,50
#	];


#my $Par = PackParams("isent", $ShowE, $ShowT, $ClcLayer, $ClcTime);
#ClcAssemblyConfig($Par);
#GetAllPnt($Par);


1;





