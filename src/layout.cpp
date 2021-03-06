#include <Rcpp.h>
#include <vector>
#include <string>
#include "Readabel/layout.h"

static void add_string_columns(SEXP xp, SEXP list_of_columns, SEXP row_indices, SEXP row_order, SEXP column_indices);
static void add_numeric_columns(SEXP xp, SEXP list_of_columns, SEXP row_indices, SEXP row_order, SEXP column_indices);

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

RcppExport SEXP rcpp_columns(SEXP xp, SEXP list_of_columns, SEXP row_indices, SEXP row_order, SEXP column_indices)
{
    add_string_columns(xp, list_of_columns, row_indices, row_order, column_indices);
    add_numeric_columns(xp, list_of_columns, row_indices, row_order, column_indices);

    return list_of_columns;
}

static void add_string_columns(SEXP xp, SEXP list_of_columns, SEXP row_indices, SEXP row_order, SEXP column_indices)
{
    Rcpp::XPtr<Readabel::Layout> ptr(xp);
    Rcpp::List list_of_columns_(list_of_columns);
    Rcpp::IntegerVector column_indices_(column_indices);
    std::vector<int> row_indices_ = Rcpp::as<std::vector<int> >(row_indices);
    std::vector<int> row_order_ = Rcpp::as<std::vector<int> >(row_order);
    // Convert to 0-based indices.
    for (int i = 0; i < row_indices_.size(); i++) {
        row_indices_[i] -= 1;
        row_order_[i] -= 1;
    }
    for (int i = 0; i < list_of_columns_.size(); i++)
        if (column_indices_[i] == 1)
            list_of_columns_[i] = Rcpp::wrap(*ptr->trait_column(row_indices_, row_order_));
        else if (column_indices_[i] == 2)
            list_of_columns_[i] = Rcpp::wrap(*ptr->snp_column(row_indices_, row_order_));
}

static void add_numeric_columns(SEXP xp, SEXP list_of_columns, SEXP row_indices, SEXP row_order, SEXP column_indices)
{
    Rcpp::XPtr<Readabel::Layout> ptr(xp);
    Rcpp::List list_of_columns_(list_of_columns);
    Rcpp::IntegerVector column_indices_(column_indices);
    std::vector<int> row_indices_ = Rcpp::as<std::vector<int> >(row_indices);
    std::vector<int> row_order_ = Rcpp::as<std::vector<int> >(row_order);
    // Convert to 0-based indices.
    for (int i = 0; i < row_indices_.size(); i++) {
        row_indices_[i] -= 1;
        row_order_[i] -= 1;
    }
    std::vector<double*> columns;
    std::vector<int> numeric_columns;
    for (int i = 0; i < list_of_columns_.size(); i++) {
        // Subtract 2 leading non-numeric columns and convert 1-based
        // R indices to 0-based C++ indices: - 2 - 1 = - 3.
        int column_index = column_indices_[i] - 3;
        if (column_index >= 0) {
            numeric_columns.push_back(column_index);
            Rcpp::NumericVector column(row_indices_.size());
            list_of_columns_[i] = column;
            columns.push_back(&column[0]);
        }
    }
    ptr->columns(numeric_columns, columns, row_indices_, row_order_);
}
