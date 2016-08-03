use strict;
use warnings;

package GasdCfgReader;
require AnalyzeData;
use IO::File;

###########################################################################
sub new     #01.09.2005 13:04
############################################################################
 {
    my ($work_dir, $clc_file, $clc_name, $matter_file) = @_;
    my $Params = {ClcFile=>$clc_file, ClcName=>$clc_name, MatterFile=>$matter_file, WorkDir=>$work_dir};
    bless $Params, "GasdCfgReader";
    return $Params;
}   ##new


############################################################################
sub CheckSet        #10/31/2007 12:08
############################################################################
 {
    my ($data, $name, $val, $die_line) = @_;
    $data->{$name} = $val, return 1     if (defined($data->{$name}));
    die $die_line                       if (defined($die_line));
    return 0;
}   ##CheckSet

############################################################################
sub GetMatter       #10/31/2007 11:53
############################################################################
 {
    my ($ThePar, $name) = @_;
    my $inp = new IO::File;
    my $The_MatterName = $ThePar->{MatterFile};
    $inp->open(" <$The_MatterName")      or die "Could not open input file $The_MatterName:$!\n";
    my $l;
    while($l=$inp->getline){
        my @l = split(" ",$l);
        next            if (!defined($l[0]) || $l[0] ne $name);
        shift(@l);
        my $l = join(" ",@l);
        @l = split("\;",$l);
        return \@l;
    }
    die "Could not find matter $name in file $The_MatterName\n";
}   ##GetMatter
############################################################################
sub NormalizeLayer      #10/31/2007 11:45
############################################################################
 {
    my ($ThePar, $Layer, $LayerNum) = @_;
    $Layer->{V} = $Layer->{U};$Layer->{D} = $Layer->{R};
    delete($Layer->{U});delete($Layer->{R});
    die "Layer Matter is not defined\n"       if ($Layer->{Mat} eq "");
    if ( $Layer->{T}>0 ) {
        die "Defined T $Layer->{T} but not defined P - do not know how to clc denc-ener\n"  if ($Layer->{P}==0);
        $Layer->{P} *= 1e-4;
        ($Layer->{D},$Layer->{E}) = ClcGasd::SolveDenc($Layer->{P}, $ThePar->GetMatter($Layer->{Mat})->[1], $Layer->{T});
    }
    $Layer->{M} = $ThePar->GetMatter($Layer->{Mat})->[0];
    $Layer->{X} = $LayerNum;
}   ##NormalizeLayer
############################################################################
sub GetLayer        #10/31/2007 11:23
############################################################################
 {
    my ($ThePar, $line, $LayerNum) = @_;
#print join(" ",@{$line}),"\n";
    my $Layer = { Mat=>"", P=>0, T=>0, L=>1, N=>100, U=>0, R=>0, E=>0, Ecoef=>1};
    my ($ShowE,$ShowT) = ([], []);
    for ( my $i = 0;$i<int(@{$line});$i++ ) {
        my $name = $line->[$i];
        $i++, next                          if (CheckSet($Layer, $name, $line->[$i+1]));
        my @arr;
        die "Unknown name in the layer <$name>\n"       if ($name ne "PntE" && $name ne "PntT");
        for($i++;$i<int(@{$line});$i++){
            last        if (! AnalyzeData::IsNumber( $line->[$i] ));
            $arr[int(@arr)] = $LayerNum;
            $arr[int(@arr)] = $line->[$i];
        }
        $i--;
        $ShowE = \(@{$ShowE}, @arr)         if ($name eq "PntE");
        $ShowT = \(@{$ShowT}, @arr)         if ($name eq "PntT");
    }
#print "GetLayer\nShowE: ",join(" ",@{$ShowE}),"\n","ShowT: ",join(" ",@{$ShowT}),"\n";
    $ThePar->NormalizeLayer($Layer, $LayerNum);
    return {Par=>$Layer, PntE=>$ShowE, PntT=>$ShowT};
}   ##GetLayer
############################################################################
sub SetStdPar_       #09/19/2007 3:20
############################################################################
 {
    my ($ThePar, $line) = @_;
    my (@ShowE, @ShowT);
    my $ClcLayer = [];
    my @line = @{$line};
    my @reg;
    my $ClcTime = { NumIntPar=>0, TimeStp=> 1e-3, TimeWrite=> 5, EndTime=> 2000, TimeStability=>0.02, EnergyInput=>"" };
    for ( my $i=0;$i<int(@line);$i++ ) {
        CheckSet($ClcTime, $line[$i], $line[$i+1],"Unkown name <$line[$i]>\n"), $i++, next     if ($line[$i] ne "(");
        my $FoundEnd = 0;
        @reg=();
        for($i++;$i<int(@line);$i++){
            $FoundEnd = 1, last                     if ($line[$i] eq ")");
            $reg[int(@reg)] = $line[$i];
        }
        die "Very bad for the layer ",int(@{$ClcLayer}),"end symbol <)> - not found\n"   if (!$FoundEnd);
        my $Layer = $ThePar->GetLayer(\@reg, 1+int(@{$ClcLayer}));
        $ClcLayer->[int(@{$ClcLayer})] = $Layer->{Par};
        @ShowE = (@ShowE, @{$Layer->{PntE}});
        @ShowT = (@ShowT, @{$Layer->{PntT}});
    }
#    die;
    return (\@ShowE, \@ShowT, $ClcLayer, $ClcTime);
}   ##SetStdPar_

# To be used outside....

############################################################################
sub SetStdPar     #10/18/2007 8:14
############################################################################
 {
    my ($ThePar) = @_;
    my ($clc_file, $clc_name, $matter_file) = ($ThePar->{ClcFile}, $ThePar->{ClcName}, $ThePar->{MatterFile});
    my $inp = new IO::File;
    $inp->open(" <$clc_file")      or die "Could not open input file $clc_file:$!\n";
    my @line;
    my $EndFound = 0;
    my $l;
    while($l = $inp->getline()){
        my @l = split(" ",$l);
        next        if (int(@l) == 0 || lc($l[0]) ne lc($clc_name) || $l[1] ne "{");
        shift(@l);shift(@l);
        @line = @l;
        $EndFound = 0;
        while(($l=$inp->getline()) && !$EndFound){
            @l = split(" ",$l);
            for(my $i = 0;$i<int(@l);$i++){
                $EndFound = 1, last     if ($l[$i] eq "}");
                $line[int(@line)] = $l[$i];
            }
        }
        die "Very bad in file $clc_file not found endSymbol <}> for the clc_name $clc_name\n"   if (!$EndFound);
    }
    die "Very bad in file $clc_file not found clc_name $clc_name\n"   if (!$EndFound);
    $inp->close();
#    ($ShowE, $ShowT, $ClcLayer, $ClcTime)
#print "ShowE: ",join(" ",@{$ShowE}),"\n","ShowT: ",join(" ",@{$ShowT}),"\n";
    return $ThePar->SetStdPar_(\@line);
}   ##SetStdPar

# GetWorkDir
sub GetClcDir {
#    return "$_[0]{ExpName}/$_[0]{ClcDir}";
    return "$_[0]{WorkDir}/$_[0]{ClcName}";
}   ##GetWorkDir
sub GetOutBaseName {
    return "$_[0]{WorkDir}/$_[0]{ClcName}/$_[0]{ClcName}";
}   ##GetOutName


1;




