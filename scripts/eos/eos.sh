#!/bin/bash -exv

##!/bin/bash -exv -o igncr

WORKDIR=$(pwd)

SingleJob() {
  local CFGFILE=$1
  local MATTERNAME=$2
  local BASECFG=$3
  local RESULTDIR=$4

  perl -e '
    use strict;use warnings;
    
    #$/="\x0D\x0A";
    require EosMarch;
    require CfgReader;
    use Data::Dumper;
    
    my ($workDir, $cfgFile, $matterName, $baseCfg, $resultDirName) = @ARGV;
    my $Cfg = CfgReader::new($workDir, $cfgFile, $baseCfg, $matterName, $resultDirName);
    my $wrk_dir=$Cfg->GetClcDir;
    #die "was $wrk_dir got ".CfgReader::MakeWinName($wrk_dir)."\n";
    system("mkdir -p $wrk_dir");
    print Dumper($Cfg);
    EosMarch::run($Cfg);
  ' $WORKDIR $CFGFILE $MATTERNAME $BASECFG $RESULTDIR
}

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


MultiJob() {
  local CFGFILE=$1
  local MATTERNAME=$2
  local RESULTDIR=$3
  
  perl $DIR/eos.pl $WORKDIR $CFGFILE $MATTERNAME $RESULTDIR 2>stderr
    
}

ShowDat() {
  local CFGFILE=$1
  cat $CFGFILE | grep '	' | sed 's|	|,|g' > $CFGFILE.sep
  N=$(cat $CFGFILE.sep | awk -F "," '{if (s < NF) s=NF}END{print s}')
  cat $CFGFILE.sep | awk -F "," -v n=$N '{s="";for(i=NF;i<n;i++)s=s",";print $0,s}' > $CFGFILE.fsep
  export SEP='","'
  export LINESTYLE=" with linespoints "
  data.sh $CFGFILE.fsep - || true && true
  rm -f $CFGFILE.{fsep,sep}
}

DatSh() {
  if [[ "x$2" == "x" ]] ; then 
    if [[ "x$DELIM" == "x" ]] ; then 
      qtshow show file "$1"  
    else
      qtshow show file "$1" FieldDelim $DELIM
    fi
  else
    qtshow show file "$1"  gasd 1 CurTimeFirst $2
  fi
}
