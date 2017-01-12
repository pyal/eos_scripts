#!!!!!!!!!!!!!!!!!         Depricated       !!!!!!!!!!!!!!!!!!!!!!!!!!!!
use strict;
use warnings;
package ClcGasd;
use IO::File;

sub ClcAssemblyNew		#09/19/2007 11:07
############################################################################
 {
   my ($Par) = @_;

   my @ClcLayer = @{$Par->{ClcLayer}};
   my $ClcTime = $Par->{ClcTime};
   my $EnergyInput = $ClcTime->{EnergyInput};
   my @EnergyInput =split(/:/, $ClcTime->{EnergyInput});
   my %EnergyInput = (IntegralInt => 0, TimeDepFile => "time.24.prn", Tmax => 100, Xcenter => 0.495, Xsigma => 0.3, Ysigma => 0.8);
   for(my $i = 0;$i < int(@EnergyInput);$i+=2) {$EnergyInput{$EnergyInput[$i]} = $EnergyInput[$i + 1];}
   #print("$_ $EnergyInput{$_}\n")      foreach (keys %EnergyInput);
   
   open(OUT,">$Par->{ClcName}")            or die "Could not open file $Par->{ClcName}:$!\n";
   print OUT <<EOF
   RegionConstructor
   NPolygon::TSimpleContructor {
   
      BaseRegion  NPolygon::TSimpleContructor::TRegData {
         RegionGridSize  0
         RegionVars   list_{
         }
      
         VarName   list_{
         }
         RegDoubles   list_{
         }
         RegDoubleNames   list_{
         }
         GridVars(NameMinValMaxVal)   list_{
         }
      }

      Childs   list_{
EOF
;
   my $BndPos = 0;
   for(my $it=0;$it<int(@ClcLayer);$it++){
      my $BndPosPlus = $BndPos + $ClcLayer[$it]{L};
      #$ClcLayer[$it]{Ecoef} = 1   if (!defined($ClcLayer[$it]{Ecoef}));
      print OUT <<EOF
         NPolygon::TSimpleContructor::TRegData {
            RegionGridSize  $ClcLayer[$it]{N}
            RegionVars   list_{
              $ClcLayer[$it]{M}
            }
            VarName   list_{
               EOS
            }
            RegDoubles   list_{
               $ClcLayer[$it]{Ecoef}
            }
            RegDoubleNames   list_{
                Ecoef
            }
            GridVars(NameMinValMaxVal)   list_{
                X   $BndPos   $BndPosPlus
                Density $ClcLayer[$it]{D}   $ClcLayer[$it]{D}
                Pressure $ClcLayer[$it]{P}   $ClcLayer[$it]{P}
                Energy   $ClcLayer[$it]{E}   $ClcLayer[$it]{E}
                Sound    0  0
                Velocity $ClcLayer[$it]{V}   $ClcLayer[$it]{V}
            }
         }
EOF
;
      $BndPos = $BndPosPlus;
   }
   my ($TimeStp, $TimeWrite, $EndTime) = ( $ClcTime->{TimeStp}/$Par->{TimeCoef}, $ClcTime->{TimeWrite}/$Par->{TimeCoef}, $ClcTime->{EndTime}/$Par->{TimeCoef} );
   my $OutputTime = $TimeWrite;
   my $eSplTime = $EnergyInput{Tmax} / $Par->{TimeCoef};
   print OUT <<EOF
      }
      DataFile  NULL GridBoundarySize 1
   }



   RegionMarch NPolygon::TPolyMarchBody {
      FromTime  0  ToTime  $EndTime  MaxTimeStep  1
      OutputBounds_{   LftShift  0  RgtShift  0    }
      OutputTime  $OutputTime  ResultsFile  $Par->{ClcName}.dat  OutputNames  X:Pressure:Density:Energy:Velocity
      MarchRegion NPolygon::TPolyMarchPlusE {
         IntegralInt  $EnergyInput{IntegralInt}  TimeDepFile  $EnergyInput{TimeDepFile}  Tmin  0  Tmax $eSplTime  TsplMisfit  1e-06
         Xsigma  $EnergyInput{Xsigma}  Xcenter  $EnergyInput{Xcenter}  Ysigma  $EnergyInput{Ysigma}
         PosName  X  EnergyAddName  Energy  RegCoefName Ecoef
         MarchRegion NPolygon::TMarchWilkins { 
            MarchCourant  $ClcTime->{TimeStability}  CL  1  C0  2  MinPres  0.0001 
            EOSName  EOS  PosName  X  DencName  Density  PresName  Pressure 
            EnerName  Energy  VelName  Velocity  SoundName  Sound 
            EnergyPresCoef  0 MinPresCoef 0.001
         } 
      }
   }


   RegionMarch NPolygon::TPolyMarchBody {
      FromTime  0  ToTime  $EndTime  MaxTimeStep  0.0001
      OutputBounds_{   LftShift  0  RgtShift  0    }
      OutputTime  $OutputTime  ResultsFile  $Par->{ClcName}.dat  OutputNames  X:Pressure:Density:Energy:Velocity
      MarchRegion NPolygon::TMarchWilkins { 
         MarchCourant  0.1  CL  1  C0  2  MinPres  0.0001 
         EOSName  EOS  PosName  X  DencName  Density  PresName  Pressure 
         EnerName  Energy  VelName  Velocity  SoundName  Sound 
         EnergyPresCoef  0 MinPresCoef 0.01
      } 
   }



   RegionMarch NPolygon::TPolyMarchBody {
      FromTime  0  ToTime  $EndTime  MaxTimeStep  0.0001
      OutputBounds_{   LftShift  0  RgtShift  0    }
      OutputTime  $OutputTime  ResultsFile  $Par->{ClcName}.dat  OutputNames  X:Pressure:Density:Energy:Velocity
      MarchRegion NPolygon::TMarchWilkins { 
         MarchCourant  0.1  CL  1  C0  2  MinPres  0.0001 
         EOSName  EOS  PosName  X  DencName  Density  PresName  Pressure 
         EnerName  Energy  VelName  Velocity  SoundName  Sound 
         EnergyPresCoef  0 MinPresCoef 0.01
      } 
   }










         MarchRegion NPolygon::TPolyMarchPlusE {
            IntegralInt  0.  TimeDepFile  time.24.prn  Tmin  0  Tmax 1  TsplMisfit  1e-006
            Xsigma  1  Xcenter  1.5  Ysigma  1
            PosName  X  EnergyAddName  Energy  RegCoefName Ecoef
            MarchRegion NPolygon::TPolyMarchDriver {
               MarchFlux(FluxVar:FluxLF:FluxRI:FluxForce:FluxFlic) FluxForce  MarchCourant  0.2
               ClcBaseFlux NPolygon::TPolyMarchDriverFluxGasdLagrange {
                  Xname  X  DencName  Density  VelName  Velocity  EnerName
                  Energy  PresName  Pressure  EOSName  EOS SoundName Sound
                  LimiterVarVector(EnerName:PresName:VelName)  Energy:Density:Pressure:Velocity:Sound
                  SetBrookDencity  0  BrookFinalDencity  7.89
               }
            }
         }


EOF
   ;close(OUT);
   system("poly_test.exe march \"ConfFile $Par->{ClcName} \" "); #$Par->{ClcName} $Par->{ClcName}.ck /l ");
   #system("cell_dat.exe $Par->{ClcName} $Par->{ClcName}.ck /l ");
   #system("cell_kru.exe $Par->{ClcName}.ck $Par->{ClcName}.dat ");
}	##ClcAssembly

1;