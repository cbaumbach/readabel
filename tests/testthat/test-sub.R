source("setup.R")

context("[")

# Full dataset.
d <- data.frame(lapply(names(x), function(name) x[[name]]), stringsAsFactors = FALSE)
names(d) <- names(x)

test_that("x[, \"snp\", drop = FALSE]", {
    expect_equal(d[, "snp", drop = FALSE],
                 x[, "snp", drop = FALSE])
})

test_that("x[, c(\"snp\", \"beta_snp\"), drop = FALSE]", {
    expect_equal(d[, c("snp", "beta_snp"), drop = FALSE],
                 x[, c("snp", "beta_snp"), drop = FALSE])
})

test_that("x[]", {
    expect_equal(d[], x[])
})

test_that("x[,]", {
    expect_equal(x[], x[, ])
})