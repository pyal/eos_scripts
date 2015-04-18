#!/bin/bash 

# Generate the gnuplot script

BASENAME=$1


AppendPlot () {
    if [ -e $1 ] ; then
        #cat $1 |tr -d \015 | perl -e '
        cat $1 | perl -e '
            use strict; use warnings;
            use Scalar::Util qw(looks_like_number);
            my ($fileName, $sep, $style) = @ARGV;
            $style = ""    if (!defined($style));
            my $separator = $sep;
            $separator = " "    if (!defined($sep) || $sep eq "" );
            $separator =~ s|\"||g;
            #print STDERR "$separator  ";
            <STDIN>;
            while(<STDIN>) {
                my $l = $_;
                my @l = split /$separator/;
                @l = split(" ", $_)      if ($separator eq " ");
                my $n = 0;
                if (defined($sep) && $sep ne "") {
                    $n = int(@l);
                } else {
                    foreach(@l) {
                        $n++ if (looks_like_number($_) || $_ eq "\"\"");
                    }
                }
                #print STDERR join("-", @l), " $n \n";
                if (int(@l) == $n && $n > 1) {
                    if ($n > 1) {
                        my $pref = "";
                        print("$pref\"$fileName\" using 1:$_  $style"), $pref = ", " for(2..$n);
                    }
                    exit 0;
                }
            }
            print("\"$fileName\" using 1:2 $style");
            print STDERR "bad data\n";

        ' $1 "$SEP" "$LINESTYLE" 2>$1.err

    fi
}
WHAT=$(AppendPlot $1 )
SEPARATOR=${SEP:-whitespace}

cat <<EOF >$1.plt

set title "Graph $1"
set xlabel "X"
set ylabel "Y"
set autoscale  x
set autoscale  y

#set logscale x
#set logscale y
set style data lines

bind l "set style data lines;replot"
bind d "set style data dots;replot"
bind p "set style data points;replot"

set datafile separator  $SEPARATOR
plot $WHAT

EOF
#WHAT1=$(echo $WHAT | sed -e 's/\"/\\\"/g' | sed -e 's/\:/\\\:/g' )
WHAT1=$(echo $WHAT | sed -e 's/\//\\\//g' | sed -e 's/\:/\\\:/g' )
WHAT2="s/PLOTCOMMAND/$WHAT1/g"
sed -e  "$WHAT2" c:/gnuplot/bin/wgnuplot.mnu.orig > c:/gnuplot/bin/wgnuplot.mnu

#c:/gnuplot/bin/wgnuplot.exe $1.plt - &
c:/gnuplot/bin/wgnuplot.exe $1.plt - &

sleep 1

[ ! -s $1.err ]  &&
	echo OK &&
	rm -f $1.plt $1.err
[ -s $1.err ]  &&
	echo Very bad. Try to call &&
	#rm -f $1.err &&
	echo start c:/gnuplot/bin/wgnuplot.exe $1.plt -
