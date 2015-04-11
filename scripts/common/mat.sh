
GetExtFile() {
INFILE=$1
EXT=$2
    cat $INFILE | perl -e '
        use strict;use warnings;
        my @ext = map {"$_" } split(":", $ARGV[0]);
        while(<STDIN>) {
            my @l = split;
            foreach my $ext (@ext) {
                foreach my $w (@l) {
                    print "$w\n"     if ($w =~ /$ext$/);
                }
            }
        }
    ' $EXT | gsort -u
}
