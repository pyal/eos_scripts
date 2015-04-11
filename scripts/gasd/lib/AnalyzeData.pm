use strict;
use warnings;
package AnalyzeData;
###########################################################################
sub new     #01.09.2005 13:04
############################################################################
 {
#    my () = @_;
    my $Params = {};
#    my $Head = geobase_head::new(); my ($r) = { "Head" =>$Head };
    bless $Params, "AnalyzeData";
    return $Params;
}   ##new


sub PrintHash		#09/18/2007 7:04
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
          $max = $foo if IsNumber($foo) && (!IsNumber($max) || $max < $foo);
      }
      $max = 0      if (!IsNumber($max));
      $max;
  }
 sub min {
      my $min = pop(@_);
      foreach my $foo (@_) {
          $min = $foo if IsNumber($foo) && (!IsNumber($min) || $min > $foo);
      }
      $min = 0      if (!IsNumber($min));
      $min;
  }





############################################################################
sub ShiftMullCol     #10/21/2007 11:22
############################################################################
 {
    my ($name, $nameout, $Shift, $Mull, $Col ) = @_;
    $Mull = 1        if (!defined($Mull));
    $Col = 0         if (!defined($Col));
    my $n = "\x0D\x0A";
    open IN1, "< $name"            or die "ShiftMullCol Could not open input file $name:$!\n";
    open OUT1, "> $nameout"            or die "ShiftMullCol Could not open output file $nameout:$!\n";
    while(<IN1>){
        my @l = split;
        print OUT1 ($_), next        if (!IsNumber($l[0]));
        $l[$Col]+=$Shift;
		$l[$Col]*=$Mull;
        print OUT1  join(" ",@l), "$n";
    }
    close IN1;close OUT1;

}   ##ShiftMullTime
############################################################################
sub GatherData		#10/18/2007 4:32
############################################################################
 {
	my ($data, $val) = @_;
    return      if ( !ClcGasd::IsNumber($val) );
    $data->{Max} = ClcGasd::max($data->{Max}, $val);
    $data->{Min} = ClcGasd::min($data->{Min}, $val);
	$data->{Sum} += $val;
	$data->{Num}++;
	$data->{Sum2} += $val*$val;
}	##GatherData

############################################################################
sub GatherFileStat		#10/22/2007 2:08
############################################################################
 {
    my ($name, $stat, $Col ) = @_;
	$stat = [];
	$stat = {}				if (defined($Col));
    open IN1, "< $name"            or die "ShiftMullCol Could not open input file $name:$!\n";
	my $i;
	while(<IN1>){
		my @l = split;
		next			if (!IsNumber($l[0]));
		if ( !defined($Col) ) {
			for ( $i = 0;$i<int(@l);$i++ ) {
				$stat->[$i] = {}			if ( !defined($stat->[$i]) );
				GatherData($stat->[$i],$l[$i]);
			}
		} else {
			GatherData($stat,$l[$Col]);
		}
	}
	if ( !defined($Col) ) {
		for ( $i = 0;$i<int(@{$stat});$i++ ) {
            $stat->[$i]{Mean} = $stat->[$i]{Sum}/max($stat->[$i]{Num},1);
			$stat->[$i]{Mis2} = $stat->[$i]{Sum2}-$stat->[$i]{Num}*$stat->[$i]{Mean}*$stat->[$i]{Mean};
            $stat->[$i]{Mis} = ($stat->[$i]{Mis2}/max($stat->[$i]{Num},1))**0.5;
		}
	} else {
        $stat->{Mean} = $stat->{Sum}/max($stat->{Num},1);
		$stat->{Mis2} = $stat->{Sum2}-$stat->{Num}*$stat->{Mean}*$stat->{Mean};
        $stat->{Mis} = ($stat->{Mis2}/max($stat->{Num},1))**0.5;
	}

}	##GatherFileStat
############################################################################
sub StoreArray		#10/22/2007 2:24
############################################################################
 {
    my ($name, $Col ) = @_;
	my $data = [];
    open IN1, "< $name"            or die "ShiftMullCol Could not open input file $name:$!\n";
	my $n = 0;
	while(<IN1>){
		my @l = split;
		next			if (!IsNumber($l[0]));
		if ( !defined($Col) ) {
			for ( my $i = 0;$i<int(@l);$i++ ) {
				$data->[$i][$n] = $l[$i];
			}
		} else {
			$data->[$n] = $l[$Col];
		}
		$n++;
	}
	return $data;
}	##StoreCol

############################################################################
sub GatherArrayStat		#10/22/2007 2:08
############################################################################
 {
    my ($data, $RowFrom, $RowTo ) = @_;
	my $stat = {};
	my $i;
	my $l = int(@{$data});
	if (!IsNumber($data->[0])){
		$stat = [];
		$l = int(@{$data->[0]});
	}
	$RowFrom = 0			if (!defined($RowFrom));
	$RowTo = $l				if (!defined($RowTo));
    for ( my $n=$RowFrom;$n<$RowTo;$n++ ) {
#       next                    if ($n<$RowFrom || $n>$RowTo);
		if (!IsNumber($data->[0])) {
			for ( $i = 0;$i<int(@{$data});$i++ ) {
				$stat->[$i] = {}			if ( !defined($stat->[$i]) );
				GatherData($stat->[$i],$data->[$i][$n]);
			}
		} else {
			GatherData($stat,$data->[$n]);
		}
	}
	if (!IsNumber($data->[0])) {
		for ( $i = 0;$i<int(@{$stat});$i++ ) {
            $stat->[$i]{Mean} = $stat->[$i]{Sum}/max($stat->[$i]{Num},1);
			$stat->[$i]{Mis2} = $stat->[$i]{Sum2}-$stat->[$i]{Num}*$stat->[$i]{Mean}*$stat->[$i]{Mean};
            $stat->[$i]{Mis} = ($stat->[$i]{Mis2}/max($stat->[$i]{Num},1))**0.5;
		}
	} else {
		$stat->{Mean} = $stat->{Sum}/max(1,$stat->{Num});
		$stat->{Mis2} = $stat->{Sum2}-$stat->{Num}*$stat->{Mean}*$stat->{Mean};
        $stat->{Mis} = ($stat->{Mis2}/max(1,$stat->{Num}))**0.5;
	}
my ($numIn, $numOut, $minV, $maxV) = (0,0,$stat->{Mean}-3*$stat->{Mis},$stat->{Mean}+3*$stat->{Mis});
for ( my $n=$RowFrom;$n<$RowTo;$n++ ) { if ( $data->[$n]<$maxV && $data->[$n]>$minV ) { $numIn++; } else { $numOut++;}}
$stat->{NumIn} = $numIn;
$stat->{numOut} = $numOut;
	return $stat;

}	##GatherFileStat


############################################################################
# Go while data in lim ($Min,$Max) - drop if in last $NumToCheck pnt we have more then $BadCount violations.
sub LookStableDrop		#10/22/2007 3:10
############################################################################
{
	my ($data1, $ChFr, $MinV, $MaxV, $NumToCheck, $BadCount, $Backward) = @_;
	$Backward = 0					if (!defined($Backward));
	my ($data, $i, $j) = ([],0,0);
	if ( $Backward ) {
		for ( $i = int(@{$data1}); $i>=0; $i-- ) {
			$data->[int(@{$data1})-$i] = $data1->[$i];
		}
		$ChFr = int(@{$data1})-$ChFr;
	} else {
		for ( $i = 0; $i<int(@{$data1}); $i++ ) {
			$data->[$i] = $data1->[$i];
		}
	}
	for ( $i = $ChFr; $i<int(@{$data}); $i++ ) {
		next			if ($data->[$i]<$MaxV && $data->[$i]>$MinV);
		my $bad = 0;
		for ( $j = 1; $j<$NumToCheck-1 && $j+$i<int(@{$data}); $j++ ) {
			$bad++		if (!($data->[$i+$j]<$MaxV && $data->[$i+$j]>$MinV));
		}
		if ($bad>=$BadCount){
			return $i				if (!$Backward);
			return int(@{$data1})-$i;
		}
		$i+=$j;
	}
	return int(@{$data})			if (!$Backward);
	return 0;

}	##LookStableDrop
############################################################################
# divide region in $StartDiv parts. Find part with min Sigma. Extend part left and right in lim $SigmaCoef...
sub FindStableRegion        #
############################################################################
 {
	my ($data,$ChFr,$ChTo, $SigmaCoef, $StartDiv) = @_;
	my $IterCount = ($ChTo - $ChFr)/$StartDiv;
	my ($stat, $i) = ([], 0);
	for ( $i = 0; $i<$StartDiv; $i++ ) {
		$stat->[$i] = GatherArrayStat($data, $IterCount*$i+$ChFr, $IterCount*($i+1)+$ChFr);
#print "Interval $i Fr ",$IterCount*$i+$ChFr, " To ", $IterCount*($i+1)+$ChFr, ":\n";
#print PrintHash($stat->[$i]),"\n";
	}
	my ($MinS, $MinC, $Mean) = (1e5,0, 0);
	for ( $i = 0; $i < $StartDiv; $i++ ) {
		($MinS, $MinC, $Mean) = ($stat->[$i]{Mis}, $i,$stat->[$i]{Mean})		if ( $stat->[$i]{Mis}<$MinS);
	}
#print "Extending region!!!!!!!!!!!!!!!!!!!!!!!!!!!!11\n";
#				               ($data1, $ChFr,                   $MinV,                  $MaxV,          $LimVal, $NumToCheck, $BadCount, $Backward) = @_;
	my $FoundFr = LookStableDrop($data, $IterCount*$MinC+$ChFr , $Mean-$SigmaCoef*$MinS, $Mean+$SigmaCoef*$MinS, 20, 5, 1);
	my $FoundTo = LookStableDrop($data, $IterCount*($MinC+1)+$ChFr , $Mean-$SigmaCoef*$MinS, $Mean+$SigmaCoef*$MinS, 20, 5, 0);
#    $stat = GatherArrayStat($data, $FoundFr, $FoundTo);
#    ($MinS, $Mean) = ($stat->{Mis},$stat->{Mean});
#    $FoundFr = LookStableDrop($data, $IterCount*$MinC+$ChFr , $Mean-$SigmaCoef*$MinS, $Mean+$SigmaCoef*$MinS, 20, 5, 1);
#    $FoundTo = LookStableDrop($data, $IterCount*($MinC+1)+$ChFr , $Mean-$SigmaCoef*$MinS, $Mean+$SigmaCoef*$MinS, 20, 5, 0);


	$FoundFr = int($FoundFr);
	$FoundTo = int($FoundTo);
#print "Found Fr $FoundFr FoundTo $FoundTo  Mean $Mean  SigmaCoef  $SigmaCoef  MinS   $MinS  \n";
	return ($FoundFr, $FoundTo);
}	##FindStableRegion
############################################################################
sub FindGoodRegions      #10/30/2007 12:27
############################################################################
 {
    my ($data,$ChFr,$ChTo, $SigmaCoef, $SigmaValCoef, $StartDiv) = @_;
    my $IterCount = ($ChTo - $ChFr)/$StartDiv;
    my ($stat, $i, $j) = ([], 0 , 0);
    for ( $i = 0; $i<$StartDiv; $i++ ) {
        $stat->[$i] = GatherArrayStat($data, $IterCount*$i+$ChFr, $IterCount*($i+1)+$ChFr);
    }
    my ($MinS, $MinNum) = (1e5);
    for ( $i = 0; $i < $StartDiv; $i++ ) {
        ($MinS,$MinNum) = ($stat->[$i]{Mis},$stat->[$i]{Num})        if ( $stat->[$i]{Mis}<$MinS);
    }
    my @regions;
    for ( $i = 0; $i < $StartDiv; $i++ ) {
        next            if ( $MinS*$SigmaCoef<$stat->[$i]{Mis} );
        my %reg = (Start=>$i);
        my @bad;
        my $Val = $stat->[$i]{Mean};
        my $Sum2 = $stat->[$i]{Sum2};
        my $NumPnt = $stat->[$i]{Num};
        for ( $j = $i+1; $j < $StartDiv; $j++ ) {
            last        if (abs($stat->[$j]{Mean}-$Val/($j-$i-int(@bad)))>$MinS*$MinNum**0.5/$stat->[$j]{Num}**0.5*$SigmaValCoef);
            $bad[int(@bad)]=[$IterCount*$j+$ChFr, $IterCount*($j+1)+$ChFr], next            if ( $MinS*$SigmaCoef<$stat->[$i]{Mis} );
            $Val += $stat->[$j]{Mean};
            $Sum2 += $stat->[$j]{Sum2};
            $NumPnt += $stat->[$j]{Num};
        }
        $reg{StartPnt} = $IterCount*$i+$ChFr;
        $reg{FinalPnt} = $IterCount*$j+$ChFr;
        $reg{End}=$j;
        $reg{Bad}=\@bad;
        $reg{NumSubReg} = ($j-$i-int(@bad));
        $reg{Mean} = $Val/$reg{NumSubReg};
        $reg{Sum2} = $Sum2;
        $reg{NumPnt} = $NumPnt;
        $reg{Mis2} = $Sum2-$NumPnt*$reg{Mean}*$reg{Mean};
        $reg{Mis} = $reg{Mis2}/$NumPnt**0.5;
        $regions[int(@regions)] = \%reg;
        $i = $j;
    }
    return @regions;
}   ##FindGoodRegions



use IO::File;
#use FileHandle;

###########################################################################
sub MakeFindReturn		#10/23/2007 10:51
############################################################################
 {
	my ($file, $time) = @_;
 	return "\"\"" 			if ( !defined($file->{Line}) );
	my @l2 = @{$file->{Line}};
	my $t2 = shift(@l2);
	my ($res,$i) = ("",0);
 	return "\"\"" 			if ( !defined($t2) );
 	if ($time==$t2){
 		return join(" ",@l2);
 	}
 	if ( !defined($file->{LinePrev}) || $t2<$time ){
 		for($i = 0;$i<int(@l2);$i++){
 			$res = "$res \"\"";
 		}
 		return $res;
 	}
	my @l1 = @{$file->{LinePrev}};
	my $t1 = shift(@l1);
 	for($i = 0;$i<int(@l2);$i++){
 		$res = "$res ".($l1[$i]+($l2[$i]-$l1[$i])/($t2-$t1)*($time-$t1));
 	}
#print "$t1 $time $t2\n$l1[0]  $res  $l2[0]\n";
	return $res;
}	##MakeFindReturn
############################################################################
sub FindTime		#10/23/2007 10:18
############################################################################
 {
	my ($file, $time) = @_;
#	my @l;
	return "\"\""					if ( defined($file->{Line}) && !defined($file->{Line}[0]) );
#	MakeFindReturn($file, $time)	if ( defined($file->{Line}) && defined($file->{LinePrev}) && $time<=$file->{Line}[0] );
	return MakeFindReturn($file, $time)	if ( defined($file->{Line}) && $time<=$file->{Line}[0] );
	my $l;
	while(defined($l= $file->{fh}->getline())){
		my @l = split(" ",$l);
#print join(" ",@l), " Time $time line <",defined($file->{Line}), "> lineP <",defined($file->{LinePrev}),">\n";
		next			if (!IsNumber($l[0]));
		$file->{LinePrev} = $file->{Line}		if (defined($file->{Line}));
#,print("setting prev time $time line ",join(" ",@l)," prevL ",join(" ",@{$file->{Line}}),"\n")
		$file->{Line} = \@l;
		last			if ($l[0]>=$time);
	}
#	MakeFindReturn($file, $time)	if (!IsNumber($l[0]) || $l[0]<$time);
	return MakeFindReturn($file, $time);
}	##FindTime

############################################################################
sub SumSortedFiles        #10/23/2007 1:28
############################################################################
 {
    my ($InFiles, $OutFile, $Header) = @_;
    my @inF = split(" ", $InFiles);
    return              if (int(@inF) == 0);
	my (@files, $i, @fh);
	open OUT1, "> $OutFile"		or die "Could not open outfile file $OutFile:$!\n";
	for ( $i=0;$i<int(@inF);$i++ ) {
		$files[$i]{fh} = new IO::File;
    	$files[$i]{fh}->open("< $inF[$i]")		or die "Could not open file $inF[$i]:$!\n";
    }
	my $n = "\x0D\x0A";
	my $l;
	print OUT1 $Header 					if (defined($Header));
	while ( defined($l=$files[0]{fh}->getline()) ) {
		my @l = split(" ",$l);
		my $Line = join(" ",@l);
		if ( IsNumber($l[0] ) ){
			for ( $i=1;$i<int(@files);$i++ ) {
				$Line = "$Line ".FindTime($files[$i], $l[0]);
			}
			print OUT1 $Line,"$n";
		}

	}
	foreach my $fh ( @files ) { $fh->{fh}->close; }
	close OUT1;
}   ##SumFiles

############################################################################
sub ShortenData		#10/23/2007 2:38
############################################################################
 {
    my ($nameIn, $nameOut, $TimeFrom, $TimeTo, $Col) = @_;    #$col==-1 - use rows, not times...
	$Col = 0		if (!defined($Col));
	open IN1, "< $nameIn"		or die "Could not open file $nameIn:$!\n";
	open OU1, "> $nameOut"		or die "Could not open out file $nameOut:$!\n";
	my $n = 0;
	while(<IN1>){
        my $l = $_;
        my @l = split(" ",$l);
        print( OU1 $l), next    if (!IsNumber($l[0]));
		if ( $Col==-1 ) {
			next		if ($n<$TimeFrom);
			last		if ($n>$TimeTo);
			$n++;
			print OU1 $_;
			next;
		}
        print(OU1 $l) , next    if (!IsNumber($l[$Col]));
        next           if ($l[$Col]<$TimeFrom);
		last		 	if ($l[$Col]>$TimeTo);
		print OU1 $_;
	}
}	##Shortendata
1;
