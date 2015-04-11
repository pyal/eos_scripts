use strict;
use warnings;
package IvlCmp;
use IO::File;

############################################################################
sub new     #01.09.2005 13:04
############################################################################
 {
    my ($TempFile, $VolFile, $PresFile, $EnerFile) = @_;
    my ($vol, $temp) = (Read1DFile($VolFile), Read1DFile($TempFile));
    my ($pres, $ener) = (Read2DFile($PresFile, $temp, $vol), Read2DFile($EnerFile, $temp, $vol));
    my $Params = {vol=>$vol, temp=>$temp, pres =>$pres, ener => $ener};
    bless $Params, "IvlCmp";
    return $Params;
}   ##new

sub Read2DFile($$$) {
    my ($file, $x, $y) = @_;
    my $yNum = int(@$y);
    my @data = <$file>;
    die("bad dims x", int(@{$x}), "2D_x ", int(@data), "\n")  if (int(@{$x}) != int(@data));
    for(my $i = 0; $i < int(@data); $i++) {
        my @l = split(" ", $data[$i]);
        $data[$i] = \@l;
        die("bad y[$i] dim[", int(@l), " not equal to y dim($yNum)\n")   if (int(@l) != $yNum);
    }
}
sub Read1DFile($) {
    my ($file) = @_;
    my @data = <$file>;
    return \@data;
}
sub GetIsotherm($$) {
    my ($this, $temps) = @_;
    my $i = 0;
    for(my $i = 0; $i < int(@$temps); $i++) {
        
    }
}
 