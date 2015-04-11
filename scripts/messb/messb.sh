
MakeStep() {
FROM=$1
TO=$2
NUM=$3
OUT=$4

    awk -v FROM=$FROM -v TO=$TO -v NUM=$NUM 'BEGIN{ \
        for( i = 0; i < NUM;i++) print FROM + i / (NUM - 1) * (TO - FROM)}' > $OUT
}

MakeLorentz() {
BASE=$1
AMP=$2
SHIFT=$3
SIGMA=$4
RND=$5
XCOL=$6
OUT=$7
    cat $XCOL | awk -v BASE=$BASE -v AMP=$AMP -v RND=$RND -v SHIFT=$SHIFT -v SIGMA=$SIGMA  \
        'BEGIN{srand();PII = 4.0*atan2(1.0,1.0)}{ \
            print BASE - AMP/PII*SIGMA/(($1-SHIFT)**2+SIGMA**2) + (rand() - 0.5) * RND }' > $OUT
}


MessbSimpleCfg() {
INDAT=$1
OUTDAT=$2
OUTCFG=$3
cat <<EOF > $OUTCFG
=====================  Ignore up to GeneralBegim =============
NameFrom   NameTo
GeneralBegin   $INDAT     $OUTDAT
=====================   Ignore   up   to   SetBegim   ========
Names      FrCol   ToCol   FrVel   ToVel   Col_Pnt_Val_0
SetBegin      2        3   -100        100    0
Std_appr_clc   NumIt  3 NumT  3 MinError 1e-06
sum_func 2
lorents
Ground            V  F  V       0
Intencity         V  V  V       1
Position          F  V  V       -3
Width             F  F  V       10
4-ord             F  F  F       0
lorents
Ground            F  F  F       0
Intencity         V  V  V       0
Position          F  V  V       3
Width             F  F  V       5
4-ord             F  F  F       0






SetBegim      2        3   -100        100    0
UncMin_appr_clc NumIt 3 NumT 6 FuncError 1.49012e-008 ResError 1.49012e-008 SumFuncMinim 0
minimN_LM  {
    EigenVectMinim  { ErrorLQ 1e-008 MathEps05 1.49012e-008 ZeroEig 1e-010 BreakIterStp 1.555 }
    Lambda     { CoefStart 10 DivideCoef 20 DivideVal 0.1 }
    Optimized 2
}
{ Min1D_Coef 1.2 Min1D_MaxLinSrch 5 Min1D_MaxRetry 5 }
lorents
Ground            V  F  V       0
Intencity         V  V  V       1
Position          F  V  V       -3
Width             F  F  V       10
4-ord             F  F  F       0
lorents
Ground            F  F  V       0
Intencity         V  V  V       0
Position          F  V  V       3
Width             F  F  V       5
4-ord             F  F  F       0


EOF

}

MessbCfg() {
INDAT=$1
OUTDAT=$2
OUTCFG=$3
cat <<EOF > $OUTCFG
=====================  Ignore up to GeneralBegim =============
NameFrom   NameTo
GeneralBegin   $INDAT     $OUTDAT
=====================   Ignore   up   to   SetBegim   ========
Names      FrCol   ToCol   FrVel   ToVel   Col_Pnt_Val_0
SetBegin      2        3   -100        100    0
Std_appr_clc   NumIt  3 NumT  3 MinError 1e-06
HQ_Gamma_poly
Ground              v      v      F      v   0
Intencity           F      v      F      v   10
   H                F      F      v      v   1
   QS               F      F      v      v   3
   IS               F      F      v      v   0.1
   W                F      F      F      v   1
  Teta              F      F      F      F   0
  Gamma             F      F      F      F   0
  Eta               F      F      F      F   0
  Phi               F      F      F      F   0

EOF

}

RelaxCfg() {
INDAT=$1
OUTDAT=$2
OUTCFG=$3
cat <<EOF > $OUTCFG
=====================  Ignore up to GeneralBegim =============
NameFrom   NameTo
GeneralBegin   $INDAT     $OUTDAT
=====================   Ignore   up   to   SetBegim   ========
Names      FrCol   ToCol   FrVel   ToVel   Col_Pnt_Val_0
SetBegin      2        3   -100        100    0
Std_appr_clc   NumIt  3 NumT  3 MinError 1e-06
set_func    1
CorFuncConst0  3 CorFuncExpConst   1
Num_Correlated_Par        3
4    13   -1
5    14   1
6    15   1
F_relax2
Ground              v      v      F      v   200
Intencity           F      v      F      v   -10
   H                F      F      F      F   0.
   QS               F      F      v      v   4
   IS               F      F      v      v   0
   W                F      F      v      v   0.6
  Teta              F      F      F      F   0
  Phi               F      F      F      F   0
  Eta               F      F      F      F   0
AlphH_zx1           F      F      F      F   0
AlphH_xy1           F      F      F      F   0
   H                F      F      F      F   0
   QS               F      F      F      F   -4
   IS               F      F      F      F   0
   W                F      F      F      F   0.6
  Teta              F      F      F      F   0
  Phi               F      F      F      F   0
  Eta               F      F      F      F   0
AlphH_zx2           F      F      F      F   0
AlphH_xy2           F      F      F      F   0
  T1                F      F      v      v   0.1
  T2                F      F      v      v   0.1

EOF

}


MessbCfgLow() {
INDAT=$1
OUTDAT=$2
OUTCFG=$3
cat <<EOF > $OUTCFG
=====================  Ignore up to GeneralBegim =============
NameFrom   NameTo
GeneralBegin   $INDAT     $OUTDAT
Fst 2+ T=78
Sec 3+
=====================   Ignore   up   to   SetBegim   ========
Names      FrCol   ToCol   FrVel   ToVel   Col_Pnt_Val_0
SetBegin      2        3   -100        100    0
Std_appr_clc   NumIt  3 NumT  3 MinError 1e-06
sum_func 2
HQ_Gamma_poly
Ground              v      v      F      v   0
Intencity           F      v      F      v   10
   H                F      F      v      v   0
   QS               F      F      v      v   2.2
   IS               F      F      v      v   0.83
   W                F      F      F      v   1
  Teta              F      F      F      F   0
  Gamma             F      F      F      F   0
  Eta               F      F      F      F   0
  Phi               F      F      F      F   0
HQ_Gamma_poly
Ground              v      v      F      v   0
Intencity           F      v      F      v   10
   H                F      F      v      v   1
   QS               F      F      v      v   -0.18
   IS               F      F      v      v   0.42
   W                F      F      F      v   1
  Teta              F      F      F      F   0
  Gamma             F      F      F      F   0
  Eta               F      F      F      F   0
  Phi               F      F      F      F   0
HQ_Gamma_poly
Ground              v      v      F      v   0
Intencity           F      v      F      v   10
   H                F      F      v      v   1
   QS               F      F      v      v   -0.82
   IS               F      F      v      v   0.49
   W                F      F      F      v   1
  Teta              F      F      F      F   0
  Gamma             F      F      F      F   0
  Eta               F      F      F      F   0
  Phi               F      F      F      F   0

EOF

}

MessbCfgUp() {
INDAT=$1
OUTDAT=$2
OUTCFG=$3
cat <<EOF > $OUTCFG
=====================  Ignore up to GeneralBegim =============
NameFrom   NameTo
GeneralBegin   $INDAT     $OUTDAT
Fst 2+ T=296
Sec 3+
=====================   Ignore   up   to   SetBegim   ========
Names      FrCol   ToCol   FrVel   ToVel   Col_Pnt_Val_0
SetBegin      2        3   -100        100    0
Std_appr_clc   NumIt  3 NumT  3 MinError 1e-06
sum_func 2
HQ_Gamma_poly
Ground              v      v      F      v   0
Intencity           F      v      F      v   10
   H                F      F      v      v   0
   QS               F      F      v      v   1.5
   IS               F      F      v      v   0.49
   W                F      F      F      v   1
  Teta              F      F      F      F   0
  Gamma             F      F      F      F   0
  Eta               F      F      F      F   0
  Phi               F      F      F      F   0
HQ_Gamma_poly
Ground              v      v      F      v   0
Intencity           F      v      F      v   10
   H                F      F      v      v   1
   QS               F      F      v      v   0.42
   IS               F      F      v      v   0.39
   W                F      F      F      v   1
  Teta              F      F      F      F   0
  Gamma             F      F      F      F   0
  Eta               F      F      F      F   0
  Phi               F      F      F      F   0

EOF

}
