

lseq <- function(from=1, to=100000, length.out=6) {
  exp(seq(log(from), log(to), length.out = length.out))
}
T<-seq(from=100, to=5000, by=100)
R<-lseq(from=1e-8, to=1, length.out=20)


source("ideal.R")
#CvId 1.5 NMol 2 Zero 0 HiT 0  Tvib 6390 Trot 170.8 Zero 216
#id1 <- IdealGas(MolVeight = 2, Trot = 170.8, Tvib = 6390, Lm = 0, Sm = 0, SameNuclear = TRUE, ZeroE = 0, HiT = 0)
id1 <- IdealGas(MolVeight = 4, Trot = 85.4, Tvib = 6390,Lm = 0, Sm = 0, SameNuclear = FALSE, ZeroE = 0, HiT = 0)
#id2 <- IdealGas(MolVeight = 1, Trot = 0, Tvib = 0, Lm = 0, Sm = 0.5, SameNuclear = FALSE, ZeroE = 216, HiT = 0)
id2 <- IdealGas(MolVeight = 2, Trot = 0, Tvib = 0, Lm = 0, Sm = 0.5, SameNuclear = FALSE, ZeroE = 216, HiT = 0)
# H - H = 104 kcal/mol = a cal = 4.186 j - > 217
compose <- Compose(list(id1,id2))

temp=8000
y1=FreeE(id1, R, temp)
y2=FreeE(id2, R, temp)
y3=FreeE(compose, 0.5, R, temp)
a1=FreeE(compose, 0.01, R, temp)
a9=FreeE(compose, 0.99, R, temp)
alphas=c()
masmol=c()
y4=c()
for(dd in R) {
  alphaOpt<-function(x) {FreeEInt.Compose(compose, x, dd, temp)}
  res<-optimise(alphaOpt, interval=c(0, 1), maximum=FALSE)
  alphas<-append(alphas, (res$minimum))
  masmol<-append(masmol, res$minimum * id1$MolVeight / 
                   (res$minimum * id1$MolVeight + (1 - res$minimum) * id2$MolVeight))
  y4<-append(y4, alphaOpt(res$minimum))
}
alpha=c()
prs=c()
for(dd in R) {
  aa=Alpha.Compose(compose, dd, temp)
  pp=Pressure.Compose(compose, dd, temp)
  alpha<-append(alpha, aa)
  prs<-append(prs, pp)
}
#alphaOpt<-function(x) {FreeE(compose, x, R, temp)}
#optimize(revenue, interval=c(50, 150), maximum=TRUE)
#optimise(alphaOpt, interval=c(0, 1), maximum=FALSE)
bnd=range(c(y1,y2,y3,y4))
plot(R,y4,log="x",type = "o", ylim=bnd, col="cyan")
par(new = TRUE)
plot(R,y1,log="x",type="l", ylim=bnd, axes = FALSE, xlab = "", ylab = "", col="blue")
par(new = TRUE)
plot(R,y2,log="x",type="l", ylim=bnd, axes = FALSE, xlab = "", ylab = "", col="red")
par(new = TRUE)
plot(R,y3,log="x",type = "l", ylim=bnd, axes = FALSE, xlab = "", ylab = "")
#par(new = TRUE)
#plot(R,a1,log="x",type = "l", ylim=bnd, axes = FALSE, xlab = "", ylab = "")
#par(new = TRUE)
#plot(R,a9,log="x",type = "l", ylim=bnd, axes = FALSE, xlab = "", ylab = "")

#plot(prs,alphas,log="x",type="l", col="blue")
#plot(R, prs,log="x",type="l", col="blue")

h2_dis <- matrix(c(R,masmol,y1,y2,y4),ncol=5,byrow=FALSE)
colnames(h2_dis) <- c("Density", "Alpha", "F_mol", "F_atom", "F_compose" )
write.table(h2_dis, "/Users/pyal/work/master/run_eos/scripts/run/H2DissIdeal/compose.model", row.names = FALSE)

h2_id <- matrix(c(R,y1),ncol=2,byrow=FALSE)
colnames(h2_id) <- c("Density", "FreeE")
write.table(h2_id, "/Users/pyal/work/master/run_eos/scripts/run/H2Ideal/h2ideal.model", row.names = FALSE)

h_id <- matrix(c(R,y2),ncol=2,byrow=FALSE)
colnames(h_id) <- c("Density", "FreeE")
write.table(h_id, "/Users/pyal/work/master/run_eos/scripts/run/HIdeal/hideal.model", row.names = FALSE)

