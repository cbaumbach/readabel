% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Readabel-class.R
\docType{methods}
\name{[,Readabel-method}
\alias{[,Readabel-method}
\title{Extract a subset of rows and columns}
\usage{
\S4method{[}{Readabel}(x, i, j, drop = TRUE)
}
\arguments{
\item{x}{An object of class Readabel}

\item{i}{Row name or row index (logical or numeric)}

\item{j}{Column name or column index (logical or numeric)}

\item{drop}{If TRUE (default) the result will be coerced to the
lowest possible dimension.  Otherwise the result will
be a data frame.}
}
\description{
Extract a subset of rows and columns
}

