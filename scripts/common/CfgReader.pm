use strict;
use warnings;

package CfgReader;
use IO::File;
use Data::Dumper;

###########################################################################
sub new     #01.09.2005 13:04
############################################################################
 {
    my ($work_dir, $clc_file, $clc_name, $matter_file, $resultOutDir) = @_;
    $resultOutDir = $clc_name   if (!defined($resultOutDir));
    my $Params = {CfgFile=>$clc_file, ClcName=>$clc_name, MatterFile=>$matter_file, WorkDir=>$work_dir, ResultOutDir=>$resultOutDir};
    ReadCfg($Params);
    bless $Params, "CfgReader";
    return $Params;
}   ##new

###########################################################################
sub newExplicit     #01.09.2005 13:04
############################################################################
 {
    my ($work_dir, $clc_file, $clc_name, $matter_file, $resultOutDir, $config) = @_;
    $resultOutDir = $clc_name   if (!defined($resultOutDir));
    my $Params = {CfgFile=>$clc_file, ClcName=>$clc_name, MatterFile=>$matter_file, WorkDir=>$work_dir, ResultOutDir=>$resultOutDir};
    $Params->{Cfg} = $config;
    bless $Params, "CfgReader";
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
sub ReadCfg_       #09/19/2007 3:20
############################################################################
 {
    my ($ThePar, $line) = @_;
    my %res;
    for ( my $i=0;$i<int(@{$line});$i+=2 ) {
         $res{$line->[$i]} = $line->[$i+1];
    }
    return \%res;
}   ##ReadCfg_

# To be used outside....

############################################################################
sub ReadCfg     #10/18/2007 8:14
############################################################################
 {
    my ($ThePar) = @_;
    my ($clc_file, $clc_name) = ($ThePar->{CfgFile}, $ThePar->{ClcName});
    my $inp = new IO::File;
print "$clc_file\n";
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
    $ThePar->{Cfg} = ReadCfg_($ThePar, \@line);
}   ##SetStdPar

# GetWorkDir
sub GetClcDir {
#    return "$_[0]{ExpName}/$_[0]{ClcDir}";
    #return "$_[0]{WorkDir}/$_[0]{ClcName}";
    return "$_[0]{WorkDir}/$_[0]{ResultOutDir}";
}   ##GetWorkDir
sub GetOutBaseName {
    #return "$_[0]{WorkDir}/$_[0]{ResultOutDir}/$_[0]{ClcName}";
    return $_[0]->GetClcDir()."/$_[0]{ClcName}";
}   ##GetOutName
sub MakeWinName($) {
   my ($name) = @_;
   $name =~ s/^\/cygdrive\/(.)/$1:/;
   return $name;
}







# SolverUt.pm - ya std lib
# Static methods
sub ReadCommandLine {
    my ($name,$check) = @_;
    my %res;
    my @line = split " ",$name;
    for ( my $k = 0;$k<int(@line);$k+=2 ) {
        $res{$line[$k]} = $line[$k+1];
    }
    if ( defined($check) ) {
#        my @ch = ;
        foreach my $n ( split(" ", $check) ){
            die "Parameter $n is not defined...\n"  if (!defined($res{$n}));
        }
    }
    return \%res;
}   ##ReadCfg



sub PrintHash($) {
    my ($h) = @_;
    foreach my $it (sort { $a <=> $b; } keys %{$h}){
        print $it," ",$h->{$it},"\n";
    }
}   ##PrintHash
sub LowCase($)     #02.09.2005 13:48
 {
    my ($wrd) = @_;
    my $ret = lc($wrd);
    $ret =~ tr/À-ß¨/à-ÿ¸/;
    return $ret;
}   ##LowCase
sub max($$) {
    return 0        if (!defined($_[0]) && !defined($_[1]));
    return $_[1]    if (!defined($_[0]));
    return $_[0]    if (!defined($_[1]));
    if ($_[0]<$_[1]) {return $_[1]} else {return $_[0]};
}
sub min($$) {
    return 0        if (!defined($_[0]) && !defined($_[1]));
    return $_[1]    if (!defined($_[0]));
    return $_[0]    if (!defined($_[1]));
    if ($_[0]>$_[1]) {return $_[1]} else {return $_[0]};
}
sub ReadHash {
    my ($File, $KeyCol, $ValCol, $Delim) = @_;
    open III, "<$File"     or die "Could not open ReadHash file $File:$!\n";
    my ($kc, $vc) = (0,1);
    $kc = $KeyCol       if (defined($KeyCol));
    $vc = $ValCol       if (defined($ValCol));
    my %q;
    while(<III>){
        my @l = split;
        @l = split($Delim, $_)      if (defined($Delim));
        if ($vc>=0) {
            $q{$l[$kc]} = $l[$vc];
        } else  {
            $q{$l[$kc]} = 1;
        }
    }
    close III;
    return \%q;
}   ##ReadHash
sub ReadHash2($$$)        #01/26/2008 1:06
 {
    my ($File, $KeyCol, $ValCol) = @_;
    open III, "<$File"     or die "Could not open ReadHash file $File:$!\n";
    my ($kc, $vc) = ($KeyCol, $ValCol);
    my %q;
    while(<III>){
        my @l = split;
        $q{$l[$kc]}{$l[$vc]} = 1;
    }
    close III;
    return \%q;
}   ##ReadHash


1;




