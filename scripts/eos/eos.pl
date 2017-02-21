#use strict;use warnings;
#
##$/="\x0D\x0A";
#require EosMarch;
#require CfgReader;
#use Data::Dumper;
#
#my ($workDir, $cfgFile, $matterName, $baseCfg, $resultDirName) = @ARGV;
#my $Cfg = CfgReader::new($workDir, $cfgFile, $baseCfg, $matterName, $resultDirName);
#my $wrk_dir=$Cfg->GetClcDir;
##die "was $wrk_dir got ".CfgReader::MakeWinName($wrk_dir)."\n";
#system("mkdir -p $wrk_dir");
#print Dumper($Cfg);
#EosMarch::run($Cfg);



    #EggertData us up   data (precompressed liquid he) init dense = 3.5 ; 2.3 ; 1.8 ; 1.5 ; 1
    #Curve HugPres Mat HeTestSpl P 1e-4:100:200:1 StartR 0.4305 StartT 0.8  Out R:P  
    #Post awk 'NR>1{print $1/0.4305, $2}'
    #Curve HugPres Mat HeTestSpl P 1e-4:100:200:1 StartR 0.2829 StartE 0.8  Out U:S
    #Post awk 'NR>1{print $1/0.2829, $2}'
    #Curve HugPres Mat HeTestSpl P 1e-4:100:200:1 StartR 0.2214 StartE 0.8  Out U:S
    #Post awk 'NR>1{print $1/0.2214, $2}'    
    #Curve HugPres Mat HeTestSpl P 1e-4:100:200:1 StartR 0.1845 StartE 0.8  Out U:S
    #Post awk 'NR>1{print $1/0.1845, $2}'
    #Curve HugPres Mat HeTestSpl P 1e-4:100:200:1 StartR 0.123  StartE 0.8  Out U:S
    #Script awk 'NR>1{print $1/0.123, $2}'
    #Data  Compression ()   P (Gpa)

use strict;use warnings;

#$/="\x0D\x0A";
require EosMarch;
require CfgReader;
use Data::Dumper;

sub getNext($) {
    my ($inp) = @_;
    while(my $l = $inp->getline()) {
        my @l = split(" ",$l);
        print("GOT @l\n");
        return \@l   if (int(@l) != 0 && substr($l[0], 0, 1) ne "#");
    }
    print("GOT ()\n");
    return [];
}
sub readConfig {
    my ($configFile) = @_;
    my $inp = new IO::File;
    my $inputDataFile;
    $inp->open(" <$configFile")      or die "Could not open input file $configFile:$!\n";
    my @l = @{getNext($inp)};
    while(int(@l)!=0) {
        @l = @{getNext($inp)}, next        if ($l[0] ne "Curve" && $l[0] ne "Name" && $l[0] ne "InputFile");
        $inputDataFile = $l[1], @l = @{getNext($inp)}, next   if ($l[0] eq "InputFile");
        last;
    }
    
    my @result;
    do {
        my (%params, %single);
        my $posScript = "cat";
        my $name = int(@result);
        if ($l[0] eq "Name") {
            die("Bad format line: @l")  if(int(@l) <4);
            $name = $l[1];
            die("Bad format after Name XXXX expect: Curve ...\n Got: @l")  if ($l[2] ne "Curve");
            shift(@l);
            shift(@l);
        }
        for(my $i = 0;$i < int(@l); $i+=2) {
            $params{$l[$i]} = $l[$i + 1];
        }
        @l = @{getNext($inp)};
        if (int(@l) > 0 && $l[0] eq "Script") {
            shift(@l);
            $posScript = join(" ", @l);
            @l = @{getNext($inp)};
        }
        $single{Name} = $name;
        $single{Params} = \%params;
        $single{PostTask} = $posScript;
        $result[int(@result)] = \%single;
        print("next @l\n");
    } while(int(@l)!=0 && ($l[0] eq "Curve" || $l[0] eq "Name" ));
    #} while(int(@l)!=0 && $l[0] eq "Curve");
    return (\@result, $inputDataFile);
}
sub OutputSingleTaskList($$$$$) {
    my ($todoList, $workDir, $cfgFile, $baseCfg, $matterName) = @_;
    my $taskNum = 0;
    foreach my $task (@$todoList) {
        my $parameters = $task->{Params};
        my $postScript = $task->{PostTask};
        my $Cfg = CfgReader::newExplicit($workDir, $cfgFile, $baseCfg, $matterName, $baseCfg, $parameters);
        my $wrk_dir=$Cfg->GetClcDir;
        #die "was $wrk_dir got ".CfgReader::MakeWinName($wrk_dir)."\n";
        system("mkdir -p $wrk_dir");
        print Dumper($Cfg);
        EosMarch::run($Cfg);
        system("cat $wrk_dir/$baseCfg.dat | $postScript  > $cfgFile.$task->{Name}");
        print("cat $wrk_dir/$baseCfg.dat | $postScript  > $cfgFile.$task->{Name}");
        $taskNum += 1;
    }
    return $taskNum;
}

use File::Basename;
sub b($) {
    my ($name) = @_;
    print $name, " ", basename($name), "\n";
    return basename($name);
}
sub ExperimentTheorySum($$$) {
    my ($taskNum, $cfgFile, $todoList) = @_;
    return if ($taskNum == 0);

    system("rm -f $cfgFile.sum");
    my $numExp = 0;
    my @goodExp = ();
    my $column_names = "";
    my $file_names = "";

    for( my $i = 0; $i < $taskNum; $i++) {
        my $f = $i + 2;
        my $numPnt = `cat $cfgFile | grep '	' | cut -f1,$f | awk 'NF==2' | wc -l`;
        $goodExp[$i] = 0;
        $numExp++, $goodExp[$i] = 1  if ($numPnt > 0);
        $column_names = "$column_names, ".basename("$cfgFile\.$todoList->[$i]{Name}");
        $file_names = "$file_names "."$cfgFile\.$todoList->[$i]{Name}";
    }
    system("echo X $column_names > $cfgFile.sum");
    my $pref = "";
    for( my $i = 0; $i < $taskNum; $i++) {
        my $f = $i + 2;
        $pref = "$pref,"      if ($goodExp[$i] == 1);
        my $post = "," x ($taskNum + $numExp - length($pref) );
        system("cat $cfgFile | grep '	' | cut -f1,$f | awk 'NF==2' | awk -v pr=$pref -v po=$post '{print \$1,pr, \$2, po}' >> $cfgFile.sum")  if ($goodExp[$i] == 1);
        print STDERR "$pref $post $goodExp[$i]\n";
        $pref = "$pref,";
        $post = "," x ($taskNum + $numExp - length($pref) );
        print STDERR "$pref $post $goodExp[$i]\n";
        system("cat $cfgFile\.$todoList->[$i]{Name} | awk -v pr=$pref -v po=$post '{print \$1,pr,\$2.po}' >> $cfgFile.sum");
    }
    system("rm $file_names");
    
}
sub Convert($$) {
    my ($str, $rule) = @_;
    my $res = $str;
    for(my $i = 1; $i <= int(@$rule); $i++) {
        my $from = quotemeta("{$i}");
        $res =~ s/$from/$rule->[$i - 1]/g;
    }
    return $res;
}
sub SubstList($$) {
    my ($todoList, $rule) = @_;
    my @res;
    foreach my $todo (@$todoList) {
        my (%par, %cell);
        $cell{Name} = Convert($todo->{Name}, $rule);
        $cell{PostTask} = Convert($todo->{PostTask}, $rule);
        my %pars;
        while(my ($key,$value) = each %{$todo->{Params}}){
            $pars{Convert($key, $rule)} = Convert($value, $rule);
        };
        $cell{Params} = \%pars;
        $res[int(@res)] = \%cell;
    }
    return \@res;
}
my ($workDir, $cfgFile, $matterName, $resultDirName) = @ARGV;
my $baseCfg = "explicit";

my ($todoList, $inputDataFile) = readConfig($cfgFile);
print "ReadConfig done [ $inputDataFile ] \n", Dumper($todoList), "\n";
if (!defined($inputDataFile)) {
    my $taskNum = OutputSingleTaskList($todoList, $workDir, $cfgFile, $baseCfg, $matterName);
    ExperimentTheorySum($taskNum, $cfgFile, $todoList);
    exit 0;
}

#print STDERR "pwd ", `pwd`, "\n";
#print STDERR '($workDir, $cfgFile, $matterName, $resultDirName)', $workDir, $cfgFile, $matterName, $resultDirName, "\n";
my $configDir = `basename $cfgFile`;
my @params = `cd $resultDirName; cat $inputDataFile`;
#print STDERR "Read Parameters ", Dumper(@params), "\n";
foreach my $line (@params) {
    my @l = split(" ", $line);
    next        if (int(@l) == 0 || substr($l[0],0,1) eq "#");
    my $td = SubstList($todoList, \@l);
    #print STDERR "Got ToDo ", Dumper($td), "\n";
    OutputSingleTaskList($td, $workDir, $cfgFile, $baseCfg, $matterName);
}
