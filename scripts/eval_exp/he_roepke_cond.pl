
use strict;use warnings;

#use Math::Trig ':pi';
use constant pi    => 4 * atan2(1, 1);
use constant AvogadroNum => 6.02214199e23;

my @a = (0.03064, 1.159, 0.698, 0.4876, 0.1748, 0.1, 0.258);
my @b = (0, 1.95, 2.88, 3.6);
my @c = (0, 1.5, 6.2, 0.3, 0.35, 0.1);

sub sigma($$$$$$$) {
    my ($G, $T, $A, $B, $C, $D, $temp) = @_;
    my $m1 = $a[0] * ($temp ** 1.5) * (1 + $b[1] / ($T ** 1.5));
    my $m2 = log(1 + $A + $B) * $D - $C - $b[2] / ($b[2] + $G * $T);
    #my $m2 = log((1 + $A + $B) * $D) - $C - $b[2] / ($b[2] + $G * $T);
    return $m1 * $m2 ** (-1);
}
sub A($$) {
    my ($G,$T) = @_;
    my $g2t = $T * $G ** 2;
    my $m1 = ($G ** (-3)) * (1 + $a[4] / $g2t);
    my $m2 = 1 + $a[2] / $g2t + $a[3] / $g2t ** 2;
    my $m3 = $a[1] + $c[1] * log($c[2] * $G ** 1.5 + 1);
    return $m1 / $m2 * $m3 ** 2;
}

sub B($$) {
    my ($G,$T) = @_;
    my $m1 = $b[3] * (1 + $c[3] * $T);
    my $m2 = $G * $T * (1 + $c[3] * $T ** (4./5));
    return $m1 / $m2;
}

sub C($$) {
    my ($G,$T) = @_;
    my $m1 = $c[4];
    my $m2 = log(1 + 1/$G) + $c[5] * ($G **2) * $T;
    return $m1 / $m2;
}

sub D($$) {
    my ($G,$T) = @_;
    my $m1 = $G ** 3 + $a[5] * (1 + $a[6] * $G ** 1.5);
    my $m2 = $G ** 3 + $a[5];
    return $m1 / $m2;
}

sub G($$) {
    my ($ne,$temp) = @_;
#define M_ElectronCharge    1.602176462e-19        // kulon   same F=1/(4PiEps0)*e^2/r^2
#define M_ElectricEpsilon0  8.854187817e-12              // farad/meter
#define M_Rconst    8.314472e-3               // kj/(mol K)  same
    my ($eCharge, $eps0, $Rconst, $Na) = (1.602176462e-19, 8.854187817e-12, 8.314472e-3, 6.02214199e23);
    my ($kB) = $Rconst / $Na * 1e3;

    my $m1 = ($eCharge ** 2) / (4 * pi * $eps0 * $kB * $temp);
    my $m2 = (4 * pi * $ne * 1e6 / 3) ** (1./3);
    return $m1 * $m2;
}

sub T($$) {
    my ($ne,$temp) = @_;
#define M_PlankCros_K        7.63822378788303945929e-12  // New one... Units - [Kelvin*Sec] - changed!!!
#define M_Mass_Electron_eV   510998.6258350895368494     // same
#define M_eV_K      11604.512236009364642  //same
#define M_C         2.99792458e10              // cm/c  same

    my ($plankCros, $mEl2eV, $eV2K, $c) = (7.63822378788303945929e-12, 510998.6258350895368494, 11604.512236009364642, 2.99792458e10);

    my $m1 = 2 * $mEl2eV * $eV2K * $temp / ($plankCros * $c) ** 2;
    my $m2 = (3 * pi **2 * $ne) ** (-2./3);
    return $m1 * $m2;
}

sub SigClassic($$$) {
    my ($temp, $G, $T) = @_;
    #return $a[0] * ($temp **1.5) / (log($G) ** (-3) + 0.2943 + 0.523 / ($G * $G * $T ) + 0.259 / (($G * $G * $T ) ** 2));
    #return $a[0] * ($temp **1.5) / (1 / log($G) ** 3 + 0.2943 + 0.523 / ($G * $G * $T ) + 0.259 / (($G * $G * $T ) ** 2));
    return $a[0] * ($temp **1.5) / (- 3 * log($G) + 0.2943 + 0.523 / ($G * $G * $T ) + 0.259 / (($G * $G * $T ) ** 2));
}
sub SigBorn($$$) {
    my ($temp, $G, $T) = @_;
    return $a[0] * ($temp **1.5) / (log($T/ $G) + 0.4807);
}
sub SigInter($$$) {
    my ($temp, $G, $T) = @_;
    my ($b, $c) = (1.124, 0.258);
    #return $a[0] / 2 * ($temp **1.5) / (log($G) ** (-1.5) + $b + $c * ($G/log($G)) ** 1.5);
    return $a[0] / 2 * ($temp **1.5) / (- 1.5 * log($G) + $b + $c * ($G) ** 1.5 * (-1.5) * log($G));
}
sub ClcTest {
    $_ = <STDIN>;
    chomp;
    print "$_     sigT      gT       tT\n";
    while(<STDIN>) {
        chomp;
        my @l = split;
        my $l = $_;
        print("\n"), next    if (int(@l) != 8);
        my ($G, $T, $temp, $ne) = ($l[2], $l[3], $l[0] * 1000, $l[1] * 1e19);
        #print "$l     $G $T $temp $ne        ", sigma($G, $T, A($G, $T), B($G, $T), C($G, $T), D($G, $T), $temp) / 100, "    ", G($ne, $temp) * 0.368 / 0.0053139, "     ", T($ne, $temp), "\n";
        #print "$l     $G $T $temp $ne        ", sigma($G, $T, A($G, $T), B($G, $T), C($G, $T), D($G, $T), $temp) / 100, "    ", G($ne, $temp), "     ", T($ne, $temp), "\n";
        #print "$l     $G $T $temp $ne        ", sigma(G($ne, $temp), $T, A($G, $T), B($G, $T), C($G, $T), D($G, $T), $temp) / 100, "    ", G($ne, $temp), "     ", T($ne, $temp), "\n";
        print "$l     ", sigma($G, $T, A($G, $T), B($G, $T), C($G, $T), D($G, $T), $temp) / 100, "    p=", $G*$G*$T, "   ", SigClassic($temp, $G, $T)/100, "    ", SigBorn($temp, $G, $T)/100, "    ", SigInter($temp, $G, $T)/100, "\n";
    }
}
sub ClcHe {
    $_ = <STDIN>;
    chomp;
    print "$_\tRoepke_sig\tGpar\tTpar\tElNum\n";
    while(<STDIN>) {
        chomp;
        my @l = split;
        my $l = $_;
        print("\n"), next    if (int(@l) != 7);
        my ($temp, $denc, $ionNum) = ($l[2], $l[1], $l[5]);
        my $ne = $denc * $ionNum / 4 * AvogadroNum;
        my ($G, $T) = (G($ne, $temp), T($ne, $temp));
        print "$l\t", sigma($G, $T, A($G, $T), B($G, $T), C($G, $T), D($G, $T), $temp) / 100, "\t$G\t$T\t$ne\n";
    }
}


#ClcTest;
ClcHe;
