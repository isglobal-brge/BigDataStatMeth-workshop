
###############################################
#
# Solve linear regression with least squares
#
# y = Xb
#
# b = (X'X)-1 X' Y' ----> R-1 Qt y 
#
# where X = QR
#
###############################################
library(BigDataStatMeth)
library(rhdf5)

data(mtcars)
lm(mpg ~ wt + cyl, data=mtcars)

Y <- as.matrix(mtcars$mpg)
X <- model.matrix(~ wt + cyl, data=mtcars)


QR.1 <- qr(X)
R.1 <- qr.R(QR.1)
Q.1 <- qr.Q(QR.1)
tcrossprod(solve(R.1), Q.1) %*% Y



QR.2 <- bdQR(X, thin = TRUE)
blockmult(bdtCrossprod(bdpseudoinv(QR.2$R), QR.2$Q), Y)





