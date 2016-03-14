#include <Rcpp.h>
#include <vector>
#include <string>
#include "Readabel/layout.h"

static void add_string_columns(SEXP xp, SEXP list_of_columns, SEXP row_indices, SEXP column_indices);
static void add_numeric_columns(SEXP xp, SEXP list_of_columns, SEXP row_indices, SEXP column_indices);

RcppExport SEXP rcpp_new(SEXP layout_file, SEXP data_file)
{
    Rcpp::XPtr<Readabel::Layout> ptr(new Readabel::Layout(Rcpp::as<std::string>(layout_file), Rcpp::as<std::string>(data_file)), true);

    return ptr;
}

RcppExport SEXP rcpp_names(SEXP xp)
{
    Rcpp::XPtr<Readabel::Layout> ptr(xp);
    Rcpp::CharacterVector trait_and_snp = Rcpp::CharacterVector::create("trait", "snp");
    Rcpp::CharacterVector beta(Rcpp::wrap(ptr->beta_labels()));
    Rcpp::CharacterVector se(Rcpp::wrap(ptr->se_labels()));
    Rcpp::CharacterVector cov(Rcpp::wrap(ptr->cov_labels()));
    int number_of_columns = trait_and_snp.size() + beta.size() + se.size() + cov.size();
    Rcpp::CharacterVector names(number_of_columns);

    int i = 0;
    for (int j = 0; j < trait_and_snp.size(); j++)
        names[i++] = trait_and_snp[j];
    for (int j = 0; j < beta.size(); j++)
        names[i++] = beta[j];
    for (int j = 0; j < se.size(); j++)
        names[i++] = se[j];
    for (int j = 0; j < cov.size(); j++)
        names[i++] = cov[j];

    return names;
}

RcppExport SEXP rcpp_nrow(SEXP xp)
{
    Rcpp::XPtr<Readabel::Layout> ptr(xp);
    int number_of_snps = ptr->number_of_snps();
    int number_of_traits = ptr->number_of_traits();

    return Rcpp::wrap(number_of_snps * number_of_traits);
}

RcppExport SEXP rcpp_snpNames(SEXP xp)
{
    Rcpp::XPtr<Readabel::Layout> ptr(xp);
    Rcpp::CharacterVector snp_labels(Rcpp::wrap(ptr->snp_labels()));

    return snp_labels;
}

RcppExport SEXP rcpp_traitNames(SEXP xp)
{
    Rcpp::XPtr<Readabel::Layout> ptr(xp);
    Rcpp::CharacterVector trait_labels(Rcpp::wrap(ptr->trait_labels()));

    return trait_labels;
}

RcppExport SEXP rcpp_columns(SEXP xp, SEXP list_of_columns, SEXP row_indices, SEXP column_indices)
{
    add_string_columns(xp, list_of_columns, row_indices, column_indices);
    add_numeric_columns(xp, list_of_columns, row_indices, column_indices);

    return list_of_columns;
}

static void add_string_columns(SEXP xp, SEXP list_of_columns, SEXP row_indices, SEXP column_indices)
{
    Rcpp::XPtr<Readabel::Layout> ptr(xp);
    Rcpp::List list_of_columns_(list_of_columns);
    Rcpp::IntegerVector column_indices_(column_indices);
    std::vector<int> row_indices_ = Rcpp::as<std::vector<int> >(row_indices);
    for (int i = 0; i < list_of_columns_.size(); i++)
        if (column_indices_[i] == 1)
            list_of_columns_[i] = Rcpp::wrap(*ptr->trait_column(row_indices_));
        else if (column_indices_[i] == 2)
            list_of_columns_[i] = Rcpp::wrap(*ptr->snp_column(row_indices_));
}

static void add_numeric_columns(SEXP xp, SEXP list_of_columns, SEXP row_indices, SEXP column_indices)
{
    Rcpp::XPtr<Readabel::Layout> ptr(xp);
    std::vector<int> indices_of_numeric_columns;
    std::vector<int> numeric_columns;
    Rcpp::IntegerVector column_indices_(column_indices);
    for (int i = 0; i < column_indices_.size(); i++) {
        if (column_indices_[i] >= 3) {
            indices_of_numeric_columns.push_back(i);
            // Adjust data column indices from R to C++: The leading
            // snp and trait columns are virtual; they exist only in
            // the R world.  In the data file, there are only numeric
            // columns.  So we subtract 2.  In addition, columns in R
            // are 1-based while in C++ they are 0-based.  Thus we
            // subtract one more, for a total of 3.
            numeric_columns.push_back(column_indices_[i] - 3);
        }
    }
    Rcpp::List list_of_columns_(list_of_columns);
    std::vector<int> row_indices_ = Rcpp::as<std::vector<int> >(row_indices);
    int number_of_rows = ptr->number_of_snps() * ptr->number_of_traits();
    std::vector<double*> columns(numeric_columns.size());
    for (int i = 0; i < indices_of_numeric_columns.size(); i++) {
        int idx = indices_of_numeric_columns[i];
        Rcpp::NumericVector column(number_of_rows);
        list_of_columns_[idx] = column;
        columns[i] = &column[0];
    }
    ptr->columns(numeric_columns, columns, row_indices_);
}
