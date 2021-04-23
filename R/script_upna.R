# ##########################
# Script UPNA
# ##########################

library(BigDataStatMeth)
library(rhdf5)
library(microbenchmark)


if(!file.exists("c:/tmp"))
  dir.create("c:/tmp")

setwd("c:/tmp/")

n <- 1e3  # Note: working on memory with 10^4 is highly time-consuming


# Let us imagine we aim to compute A%*%W%*%t(A) 
# with A and W matrices nxn 

A <- matrix(runif(n^2), nrow = n)
W <- matrix(runif(n^2), nrow = n)


############################################
##
## Option 1: Working on memory 
##
############################################


AWtA <- tCrossprod_Weighted(A, W, paral = TRUE, 
                            block_size = 256, threads = 3)
R <- A%*%W%*%t(A)
all.equal(AWtA, R)


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




#####################################################
##
## Option 2a: Generate the object and store as HDF5 
##
#####################################################



# Create hdf5 data file with A matrix
Create_hdf5_matrix_file(object = A, 
                        filename="BigMatrixCalc.hdf5", 
                        group = "INPUT", 
                        dataset = "A",
                        transp = FALSE) # for omic data!!!

# output 0 is fine


# Add W matrix dataset to previous file
Add_hdf5_matrix(object = W, 
                filename = "BigMatrixCalc.hdf5", 
                group = "INPUT", 
                dataset = "W")

# Let us see the info
h5ls("BigMatrixCalc.hdf5")

# see also in hdfview (https://www.hdfgroup.org/downloads/hdfview/)
# NOTE: in R data are view in transpose mode!!!!



# Remember:  
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
                groupB = "INPUT", B = "A", 
                paral = TRUE, threads = 4 )

# name of the created object tCrossProd_A_x_WxA

# Let us see the info
h5ls("BigMatrixCalc.hdf5")


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
write.table(A, file="matrixA.txt", row.names = FALSE, col.names = FALSE, sep="\t") # remove the rownames

# Create a new datafile and remove previous version if exists
Import_text_to_hdf5(filename = "matrixA.txt", 
                    outputfile = "BigMatrixtCrossProd.hdf5", 
                    outGroup = "INPUT", outDataset = "A", 
                    overwrite = TRUE)  # <---------


# W matrix

write.table(W, file="matrixW.txt", row.names = FALSE, col.names = FALSE,  sep="\t") # remove the rownames

# Add to an existing hdf5 data file
Import_text_to_hdf5(filename = "matrixW.txt", 
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

h5fdelay <- H5Fopen("BigMatrixtCrossProd.hdf5")

# Show hdf5 hierarchy (groups)
h5fdelay

h5fdelay$INPUT$A[1:10,1:10]
h5fdelay$INPUT$W

# Get result
tCrossProd_file <- h5fdelay$OUTPUT$tCrossProd_A_x_WxA

# check
tcrossprodR <- A%*%W%*%t(A)
all.equal(tcrossprodR, tCrossProd_file)
