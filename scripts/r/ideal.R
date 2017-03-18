
#IdealGas<-function(R, T,)
  
  PhysConst <- function() {
    #define M_Na        6.02214199e23             //same
    #define M_Rconst    8.314472e-3               // kj/(mol K)  same
    me <- list(
      Rconst = 8.314472e-3, # kj/(mol K)
      Na = 6.02214199e23,
      ProtonMass_K = 1.088818296e13, # 1.672 621 898 x 10-27kg
      h_Plank	= 6.62606876e-34, 	# joule*cek
      PlankCros_K = 7.63822378788303945929e-12, # kelvin * sec  
      C = 2.99792458e10          # cm/c
    )
    
    ## Set the name for the class
    class(me) <- append(class(me),"IdealGas")
    return(me)
    
  }
  IdealGas <- function(MolVeight = 1, Trot = 242, Tvib = 8980, Lm = 0, Sm = 0, SameNuclear = FALSE, ZeroE = 0, HiT = 0)
  {
    
    me <- list(
      MolVeight = MolVeight,
      Trot = Trot, # h_cros^2 / (2kI)
      Tvib = Tvib,
      Lm = Lm,
      Sm = Sm,
      SameNuclear = SameNuclear,
      ZeroE = ZeroE,
      HiT = HiT
    )
    
    ## Set the name for the class
    class(me) <- append(class(me),"IdealGas")
    return(me)
  }
  
  FreeE <- function(elObjeto, denc, temp)
  {
#    print("Calling FreeE")
    UseMethod("FreeE",elObjeto)
    print("Note this is not executed!")
  }
  
  FreeE.default <- function(elObjeto, denc, temp)
  {
    print("You screwed up. I do not know how to handle this object. FreeE")
    return(elObjeto)
  }
  
  
  FreeE.IdealGas <- function(ideal, denc, temp) {
#    print("FreeE.IdealGas")
    const <- PhysConst()
    kt <- const$Rconst * temp / ideal$MolVeight
    nv <- ideal$MolVeight / denc * exp(1) / const$Na
    pow_val <- const$ProtonMass_K*ideal$MolVeight /(2*pi*(const$PlankCros_K * const$C) ^2)
    ls_degenration <- (2*ideal$Lm + 1) * (2*ideal$Sm + 1)
    idealE <- - kt * log(nv * (pow_val * temp) ^1.5 * ls_degenration)
#    print(log(pow_val))
    rotE <- 0
    vibE <- 0
    if(ideal$Trot > 0.1) {
      trot <- ideal$Trot
      if(ideal$SameNuclear) trot <- trot / 2
      rotE <- - kt * (log(temp / trot))
    }
    if(ideal$Tvib > 0.1) {
      #vibE <- - kt * (log(temp / ideal$Tvib))
      vibE <- kt * log(1 - exp(-ideal$Tvib/temp))
    }
    return(idealE + rotE + vibE + ideal$ZeroE + ideal$HiT * kt)
  }
  
  Compose <- function(ideal)
  {
    
    me <- list(
      ideal = ideal
    )
    
    class(me) <- append(class(me),"Compose")
    return(me)
  }
  
  FreeE <- function(elObjeto, alpha, denc, temp)
  {
 #   print("Calling FreeE + alpha")
    UseMethod("FreeE",elObjeto)
    print("Note this is not executed!")
  }
  
  FreeE.default <- function(elObjeto, alpha, denc, temp)
  {
    print("You screwed up. I do not know how to handle this object. FreeE + alpha")
    return(elObjeto)
  }

  FreeEInt.Compose <- function(compose, alpha, denc, temp) {
#    print("FreeE.Compose")
    #print(compose)
    id1 <- compose$ideal[[1]]
    id2 <- compose$ideal[[2]]
    # denc = (al * mui1 + (1 - al) * mu2) * N 
    c1 <- alpha * id1$MolVeight / (alpha * id1$MolVeight + (1 - alpha) * id2$MolVeight)
    c2 <- (1-alpha) * id2$MolVeight / (alpha * id1$MolVeight + (1 - alpha) * id2$MolVeight)
    return(c1 * FreeE(id1, c1 * denc, temp) + c2*FreeE(id2, denc * c2, temp))
  }
  
  # denc = m/V = N*miu/V ; V = (N*miu) / denc
  # eV/N = miu / Denc 
  # d/dV = -N*miu/Denc^2 d/d(denc)
  Pressure.IdealGas <- function(ideal, denc, temp) {
    d <- denc*0.005
    deriv <- (FreeE(ideal, denc + d, temp) - FreeE(ideal, denc - d, temp)) / d / 2
    return(deriv*denc^2)
  }
  
  Energy.IdealGas <- function(ideal, denc, temp) {
    d <- temp*0.005
    deriv <-(FreeE(ideal, denc, temp+d) - FreeE(ideal, denc, temp-d)) / d / 2
    return(-deriv*temp^2)
  }
  FreeE.Compose <- function(compose, denc, temp) {
    alphaOpt<-function(x) {FreeEInt.Compose(compose, x, denc, temp)}
    res<-optimise(alphaOpt, interval=c(0, 1), maximum=FALSE)
    #    alphas<-append(alphas, (res$minimum))    
    #    prs<-append(y4, res$objective)
    #    y4<-append(y4, alphaOpt(res$minimum))
    return(res$objective)
  }
  Alpha.Compose <- function(compose, denc, temp) {
    alphaOpt<-function(x) {FreeEInt.Compose(compose, x, denc, temp)}
    res<-optimise(alphaOpt, interval=c(0, 1), maximum=FALSE)
    return(res$minimum)
  }
  Pressure.Compose <- function(compose, denc, temp) {
    d <- denc*0.005
    deriv <- (FreeE.Compose(compose, denc + d, temp) - FreeE.Compose(compose, denc - d, temp)) / d / 2
    return(deriv*denc^2)
  }
  
  