//// Script Information ////

// Team 105
// predict_forest.cpp

// A small library of functions to predict using a list-on-list random forest
// originally derived in Python into a fast, reliable R implementation. This
// file contains functions for predicting trees, predicting forests, and finding
// the mode (most common value) in a vector.

#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
List predict_tree(List tree, List input) {
  // Predicts the result for one record for one tree
  
  String col = tree[0];
  double val = tree[1];
  if (col == "-1") {
    return List::create(val);
  }
  
  double i = input[col];
  
  if (i <= val) {
    return predict_tree(tree[2], input);
  } else {
    return predict_tree(tree[3], input);
  }
  
}

// [[Rcpp::export]]
List predict_forest(List forest, List input) {
  // Iterates over all values in the input data and predicts
  
  int r = input.size();
  int n = forest.size();
  List out(r);
  
  for (int i = 0; i < r; ++i) {
    
    NumericVector cla(n);
    List record = input[i];
    
    for (int j = 0; j < n; ++j) {
      cla[j] = predict_tree(forest[j], record)[0];
    }
    
    out[i] = table(cla);
    
  }
  
  return out;
  
}