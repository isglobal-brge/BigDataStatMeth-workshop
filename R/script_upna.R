# ##########################
# Script UPNA
# ##########################

library(BigDataStatMeth)
library(rhdf5)
library(microbenchmark)

setwd("c:/tmp/")

n <- 1e3  # Note: working on memory with 10^4 is highly time-consuming


# Let us imagine we aim to compute A%*%W%*%t(A) with A and W matrices nxn 

A <- matrix(runif(n^2), nrow = n)
W <- matrix(runif(n^2), nrow = n)


############################################
##
## Option 1: Working on memory 
##
############################################


AWtA <- tCrossprod_Weighted(A, W, paral = TRUE, block_size = 256, threads = 3)
R <- A%*%W%*%t(A)
all.equal(AWtA[[1]], R)


res <- microbenchmark(R = A%*%W%*%t(A),
                      cores_1 = tCrossprod_Weighted(A, W, paral = FALSE), 
                      cores_2 = tCrossprod_Weighted(A, W, paral = TRUE, 
                                                    block_size = 256, threads = 2),
                      cores_3 = tCrossprod_Weighted(A, W, paral = TRUE, 
                                                    block_size = 256, threads = 3),
                      cores_4 = tCrossprod_Weighted(A, W, paral = TRUE, 
                                                    block_size = 256, threads = 4),
                      times = 3 )
res
plot(res)





## #########################################
##    Option 2 a
##         
##       Generate data and store as HDF5
##
##  NOTE: maybe one matrix is not producing memory overflow but creating more matrices
##        with the same size crashes the system
##


# Create hdf5 data file with A matrix
Create_HDF5_matrix_file(object = A, 
                        filename="BigMatrixCalc.hdf5", 
                        group = "INPUT", 
                        dataset = "A",
                        transp = FALSE) # for omic data!!!

# output 0 is fine

rm(A)
gc() # to alleviate memory


# Add W matrix dataset to previous file
Add_HDF5_matrix(object = W, 
                filename = "BigMatrixCalc.hdf5", 
                group = "INPUT", 
                dataset = "W")
rm(W)
gc()

# Let us see the info
h5ls("BigMatrixCalc.hdf5")

# see also in hdfview (https://www.hdfgroup.org/downloads/hdfview/)
# NOTE: in R data are view in transpose mode!!!!


##             COMMON PROCEDURE
##          
##    Working with hdf5 data file
##    


# -- tCrossProduct -- 
# 
#       A %*% W %*% t(A)
#       

# First part ( A%*%W )
blockmult_hdf5(filename = "BigMatrixCalc.hdf5",
               group = "INPUT", a = "A", b = "W",
               outgroup = "OUTPUT")  # default value

# name of the created object: A_x_W

# Second part ( (A%*%W)%*%t(A) ) in parallel
tCrossprod_hdf5(filename = "BigMatrixCalc.hdf5",
                group = "OUTPUT", A = "A_x_W", 
                groupB = "INPUT", B = "A", paral = TRUE, threads = 4 )

# name of the created object tCrossProd_A_x_WxA

# Let us see the info
h5ls("BigMatrixCalc.hdf5")


#  -- CrossProduct --
# 
#       t(A) %*% W %*% A
# 
# 
# # First part ( t(A)%*%B )
# Crossprod_hdf5("BigMatrixtCrossProd.hdf5", "INPUT","A", "INPUT","W", outgroup = "INPUT",  paral = TRUE, threads = 2 )
# 
# # Second part ( (t(A)%*%B) %*% A )
# blockmult_hdf5("BigMatrixtCrossProd.hdf5", "INPUT","CrossProd_AxW","A")


# Examine hierarchy before open file
h5ls("BigMatrixCalc.hdf5")

# Open file to get acces to the data (only the required one!!!)

h5fdelay <- H5Fopen("BigMatrixCalc.hdf5")

# Show hdf5 hierarchy (groups)
h5fdelay

h5fdelay$INPUT$A[1:10,1:10]
h5fdelay$INPUT$W

# Get Matrix subsets
FirstProduct <- h5fdelay$OUTPUT$A_x_W
tCrossProd<- h5fdelay$OUTPUT$tCrossProd_A_x_WxA

# Close delayed.hdf5 file   (important ... in previous functions it is not necessary)
H5Fclose(h5fdelay)     


# Test if equal
tcrossprodR <- A%*%W%*%t(A)
all.equal(tcrossprodR, tCrossProd)

#
# VERY IMPORTANT: yo do not need to re-compute the product
#




## #########################################
##    Option 2b :
##       
##       Matrix imported from data in text file format


# Create matrix and store to text file.After that, import to an hdf5 data file
A <- matrix(runif(n^2), nrow = n)
write.table(A, file="matrixA.txt", row.names = FALSE, col.names = FALSE, sep="\t") # remove the rownames
rm(A)

# Create a new datafile and remove previous version if exists
Import_text_to_HDF5(filename = "matrixA.txt", 
                    outputfile = "BigMatrixtCrossProd.hdf5", 
                    outGroup = "INPUT", outDataset = "A", 
                    overwrite = TRUE)  # <---------


# W matrix

W <- matrix(runif(n^2), nrow = n)
write.table(W, file="matrixW.txt", row.names = FALSE, col.names = FALSE,  sep="\t") # remove the rownames
rm(W)

# Add to an existing hdf5 data file
Import_text_to_HDF5(filename = "matrixW.txt", 
                    outputfile = "BigMatrixtCrossProd.hdf5", 
                    outGroup = "INPUT", outDataset = "W", 
                    overwrite = FALSE) # <---------
h5ls("BigMatrixtCrossProd.hdf5")


# Let us do  (A%*%W)%*%t(A)  in parallel

blockmult_hdf5(filename = "BigMatrixtCrossProd.hdf5",
               group = "INPUT", a = "A", b = "W",
               outgroup = "OUTPUT", paral = TRUE, threads = 3)  

tCrossprod_hdf5(filename = "BigMatrixtCrossProd.hdf5",
                group = "OUTPUT", A = "A_x_W", 
                groupB = "INPUT", B = "A", paral = TRUE, threads = 3)

h5ls("BigMatrixtCrossProd.hdf5")