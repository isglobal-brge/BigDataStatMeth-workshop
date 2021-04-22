# Dealing with big data in R workshop

The tutorials can be found here:

- [BigDataStatMeth to work on memory (`Matrix` and `DelayedArray`)](https://rpubs.com/jrgonzalezISGlobal/BigDatStatMeth_memory)
- [BigDataStatMeth to work wiht HDF5 files](https://rpubs.com/jrgonzalezISGlobal/BigDatStatMeth_hdf5)

In order to reproduce the vignette follow the instructions described in the next sections

## Quick Start

Our package needs to be installed from source code. In such cases, a collection of software (e.g. C, C++, Fortran, ...) are required, mainly for Windows users. These programs can be installed using [Rtools](https://cran.r-project.org/bin/windows/Rtools/).

Then, some required packages must be installed: 

```
# Install BiocManager (if not previously installed)
install.packages("BiocManager") 

# Install required packages
BiocManager::install(c("Matrix", "RcppEigen", "RSpectra",
                       "beachmat", "DelayedArray",
                       "HDF5Array", "rhdf5"))
```

After that, `BigDataStatMeth` is installed from our GitHub repository:

```
# Install devtools and load library (if not previously installed)
install.packages("devtools") 
library(devtools)

# Install BigDataStatMeth 
install_github("isglobal-brge/BigDataStatMeth")
```

## Practical examples

See the file 

## Exercise

Let us imaging we are interested fitting a linear model:  b

$$\mathbf{Y}=\mathbf{X}\mathbf{\beta}+\mathbf{\varepsilon}.$$  

The ordinary least square (OLS) estimate of $\mathbf{\beta}$ is 

```math
$$\widehat{\mathbf{\beta}}=[\mathbf{X}^T\mathbf{X}]^{-1}\mathbf{X}^T\mathbf{y}$$. 
```

To illustrate, let us consider the "mtcars" example, and run this regression:

```
data(mtcars)
lm(mpg ~ wt + cyl, data=mtcars)
```

Remeber that

```
Y <- mtcars$mpg
X <- model.matrix(~ wt + cyl, data=mtcars)
```

**Tasks:**
- Use functions in R to estimate model parameters using OLS.
- Use functions in `BigDataStatMeth` to estimate model parameters using OLS with on memory data.
- Use functions in `BigDataStatMeth` to estimate model parameters using OLS with a HDF5 file.






