#' Proxy of a binary OmicABEL output file.
#'
#' @slot pointer External pointer to a C++ object.
setClass("Readabel",
    slots = list(
        pointer = "externalptr",
        cache = "environment"))

setGeneric("names")

#' Return column names.
#'
#' @param x An object of class Readabel.
#' @export
setMethod("names", "Readabel", function(x) {
    .Call("rcpp_names", x@pointer, PACKAGE = "Readabel")
})

#' Return a new Readabel object.
#'
#' @param x An uninitialized object of class Readabel
#' @param layout_file Path to layout file
#' @param data_file Path to data file
setMethod("initialize", "Readabel", function(.Object, layout_file, data_file) {
    .Object@pointer <- .Call("rcpp_new", layout_file, data_file, PACKAGE = "Readabel")
    .Object@cache <- new.env(parent = emptyenv())
    .Object
})

#' Read a binary OmicABEL file.
#'
#' @param layout_file Path to layout file.
#' @param data_file Path to data file.
#' @export
read_omicabel <- function(layout_file, data_file) {
    new("Readabel", layout_file, data_file)
}

setGeneric("nrow")

#' Return number of rows.
#'
#' @param x An object of class Readabel
#' @export
setMethod("nrow", "Readabel", function(x) {
    .Call("rcpp_nrow", x@pointer, PACKAGE = "Readabel")
})

setGeneric("ncol")

#' Return number of columns.
#'
#' @param x An object of class Readabel
#' @export
setMethod("ncol", "Readabel", function(x) {
    length(names(x))
})

setGeneric("dim")

#' Return dimensions
#'
#' @param x An object of class Readabel
#' @export
setMethod("dim", "Readabel", function(x) {
    c(nrow(x), ncol(x))
})

setGeneric("snpNames", function(x) standardGeneric("snpNames"))

#' Return snp labels
#'
#' @param x An object of class Readabel
#' @export
setMethod("snpNames", "Readabel", function(x) {
    .Call("rcpp_snpNames", x@pointer, PACKAGE = "Readabel")
})

setGeneric("traitNames", function(x) standardGeneric("traitNames"))

#' Return trait labels
#'
#' @param x An object of class Readabel
#' @export
setMethod("traitNames", "Readabel", function(x) {
    .Call("rcpp_traitNames", x@pointer, PACKAGE = "Readabel")
})

setGeneric("[[")

#' Return a given column
#'
#' @param x An object of class Readabel
#' @param i Column name or column index
#' @export
setMethod("[[", "Readabel", function(x, i) {
    column_name <- find_column_names(x, i)
    column_index <- find_column_indices(x, i)
    row_indices <- seq_len(nrow(x))
    row_order <- row_indices
    if (is_in_cache(x, column_name))
        return(find_in_cache(x, column_name)[[1L]])
    column <- .Call("rcpp_columns", x@pointer,
        vector(mode = "list", length = 1L),
        row_indices, row_order, column_index,
        PACKAGE = "Readabel")[[1L]]
    add_to_cache(x, column_name, column)
    column
})

find_column_names <- function(x, i) {
    if (is.character(i)) {
        if (any(invalid_columns <- ! i %in% names(x)))
            stop("invalid columns: ", paste(i[invalid_columns], collapse = ", "))
        return(i)
    }
    if (is.logical(i))
        return(names(x)[i])
    if (any(invalid_columns <- i < 1L | i > ncol(x)))
        stop("invalid columns: ", paste(i[invalid_columns], collapse = ", "))
    return(names(x)[i])
}

find_column_indices <- function(x, i) {
    if (is.numeric(i)) {
        if (any(invalid_columns <- i < 1L | i > ncol(x)))
            stop("invalid columns: ", paste(i[invalid_columns], collapse = ", "))
        return(i)
    }
    if (is.logical(i))
        return(which(rep_len(i, length(names(x)))))
    if (any(invalid_columns <- ! i %in% names(x)))
        stop("invalid columns: ", paste(i[invalid_columns], collapse = ", "))
    return(match(i, names(x)))
}

is_in_cache <- function(x, names) {
    vapply(names, exists, logical(1L), envir = x@cache, inherits = FALSE)
}

find_in_cache <- function(x, names) {
    lapply(names, get, envir = x@cache, inherits = FALSE)
}

add_to_cache <- function(x, name, object) {
    assign(name, object, envir = x@cache)
}

clear_cache <- function(x) {
    cached_objects <- ls(envir = x@cache)
    remove(list = cached_objects, envir = x@cache)
}

setGeneric("$")

#' Return a given column
#'
#' @param x An object of class Readabel
#' @param name A column name
#' @export
setMethod("$", "Readabel", function(x, name) {
    x[[name]]
})

setGeneric("[")

#' Extract a subset of rows and columns
#'
#' @param x An object of class Readabel
#' @param i Row name or row index (logical or numeric)
#' @param j Column name or column index (logical or numeric)
#' @param drop If TRUE (default) the result will be coerced to the
#'             lowest possible dimension.  Otherwise the result will
#'             be a data frame.
#' @export
setMethod("[", "Readabel", function(x, i, j, drop = TRUE) {
    # Detect calls like x[cols] where i plays the role of j.
    cll <- sys.call(-1)
    if (length(cll) == 3L && cll[[3L]] != "") {
        j <- i
        i <- seq_len(nrow(x))
    }
    column_names <- if (missing(j)) names(x) else find_column_names(x, j)
    column_indices <- find_column_indices(x, column_names)
    row_names <- if (missing(i)) seq_len(nrow(x)) else find_row_indices(x, i)
    row_indices <- find_row_indices(x, row_names)
    row_order <- order(row_indices)
    cached <- is_in_cache(x, column_names)
    column_indices[cached] <- 0L
    if (length(column_names) == 1L && drop)
        return(x[[column_names]][row_indices])
    d <- .Call("rcpp_columns", x@pointer,
        vector(mode = "list", length = length(column_indices)),
        sort(row_indices), row_order, column_indices, PACKAGE = "Readabel")
    names(d) <- uniqify(column_names)
    if (any(!cached) && identical(row_indices, seq_len(nrow(x)))) {
        for (column in column_names[!cached])
            add_to_cache(x, column, d[[column]])
    }
    d[which(cached)] <- lapply(find_in_cache(x, column_names[cached]), `[`, row_indices)
    attr(d, "row.names") <- uniqify(row_names)
    class(d) <- "data.frame"
    d
})

find_row_indices <- function(x, i) {
    switch(typeof(i),
        integer = {
            if (all(i < 0L))
                i <- seq_len(nrow(x))[i]
            i
        },
        double = {
            find_row_indices(x, as.integer(i))
        },
        logical = {
            if (length(i) < nrow(x))
                i <- rep_len(i, nrow(x))
            which(i)
        },
        character = seq_len(nrow(x)))
}

uniqify <- function(x) {
    if (!anyDuplicated(x))
        return(x)
    x <- as.character(x)
    duplicates <- duplicated(x)
    x[duplicates] <- ave(x[duplicates], x[duplicates],
        FUN = function(x) {
            paste0(x, ".", seq_along(x))
        })
    x
}

setGeneric("head")

#' Return the first few rows of a Readabel object
#'
#' @param x An object of class Readabel
#' @param n Number of rows to return
#' @export
setMethod("head", "Readabel", function(x, n = 6L) {
    x[seq_len(n), ]
})

setGeneric("tail")

#' Return the last few rows of a Readabel object
#'
#' @param x An object of class Readabel
#' @param n Number of rows to return
#' @export
setMethod("tail", "Readabel", function(x, n = 6L) {
    x[-seq_len(nrow(x) - n), ]
})

setGeneric("colnames")

#' Return the column names of a Readabel object
#'
#' @param x An object of class Readabel
#' @export
setMethod("colnames", "Readabel", function(x) {
    names(x)
})

setGeneric("rownames")

#' Return the row names of a Readabel object
#'
#' @param x An object of class Readabel
#' @export
setMethod("rownames", "Readabel", function(x) {
    as.character(seq_len(nrow(x)))
})

setGeneric("row.names")

#' Return the row names of a Readabel object
#'
#' @param x An object of class Readabel
#' @export
setMethod("row.names", "Readabel", function(x) {
    rownames(x)
})

setGeneric("dimnames")

#' Return set of dimnames of a Readabel object
#'
#' @param x An object of class Readabel
#' @export
setMethod("dimnames", "Readabel", function(x) {
    list(rownames(x), colnames(x))
})

setGeneric("print")

#' Print representation of a Readabel object
#'
#' @param x An object of class Readabel
#' @export
setMethod("print", "Readabel", function(x) {
    number_of_traits <- length(traitNames(x))
    number_of_snps <- length(snpNames(x))
    covariates <- sub("beta_", "", grep("^beta", names(x), ignore.case = TRUE, value = TRUE), ignore.case = TRUE)
    cat("traits: ", number_of_traits, "  ",
        "snps: ", number_of_snps, "  ",
        "covariates: ", paste(covariates, collapse = " "),
        "\n", sep = "")
})

setGeneric("show")

#' Print representation of a Readabel object
#'
#' @param object An object of class Readabel
#' @export
setMethod("show", "Readabel", function(object) {
    print(object)
})

setGeneric("as.data.frame")

#' Coerce a Readabel object into a data.frame
#'
#' @param x An object of class Readabel
#' @export
setMethod("as.data.frame", "Readabel", function(x) {
    x[]
})
