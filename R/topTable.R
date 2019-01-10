#' Show table of results for top clusters or cluster-marker combinations
#' 
#' Show table of results for top (most highly significant) clusters or cluster-marker
#' combinations
#' 
#' Summary function to display table of results for top (most highly significant) detected
#' clusters or cluster-marker combinations.
#' 
#' The differential testing functions return results in the form of p-values and adjusted
#' p-values for each cluster (DA tests) or cluster-marker combination (DS tests), which
#' can be used to rank the clusters or cluster-marker combinations by their evidence for
#' differential abundance or differential states. The p-values and adjusted p-values are
#' stored in the \code{rowData} of the output \code{\link{SummarizedExperiment}} object
#' generated by the testing functions.
#' 
#' This function displays a summary table of results in a more readable format. By
#' default, the \code{top_n} clusters or cluster-marker combinations are shown, ordered by
#' adjusted p-values. Optionally, cluster counts or proportions can also be included.
#' 
#' 
#' @param res Output object from either the \code{\link{diffcyt}} wrapper function or one
#'   of the individual differential testing functions (\code{\link{testDA_edgeR}},
#'   \code{\link{testDA_voom}}, \code{\link{testDA_GLMM}}, \code{\link{testDS_limma}}, or
#'   \code{\link{testDS_LMM}}). If the output object is from the wrapper function, the
#'   objects \code{res} and \code{d_counts} will be automatically extracted.
#'   Alternatively, these can be provided directly.
#' 
#' @param d_counts (Optional) \code{\link{SummarizedExperiment}} object containing cluster
#'   cell counts, from \code{\link{calcCounts}}. (If the output object from the wrapper
#'   function is provided, this will be be automatically extracted.)
#' 
#' @param order Whether to order results by values in column \code{order_by} (default:
#'   column \code{p_adj} containing adjusted p-values). Default = TRUE.
#' 
#' @param order_by Name of column to use to order rows by values, if \code{order = TRUE}.
#'   Default = \code{"p_adj"} (adjusted p-values); other options include \code{"p_val"},
#'   \code{"cluster_id"}, and \code{"marker_id"}.
#' 
#' @param all Whether to display all clusters or cluster-marker combinations (instead of
#'   top \code{top_n}). Default = FALSE.
#' 
#' @param top_n Number of clusters or cluster-marker combinations to display (if \code{all
#'   = FALSE}). Default = 20.
#' 
#' @param show_counts Whether to display cluster cell counts by sample (from
#'   \code{d_counts}). Default = FALSE.
#' 
#' @param show_props Whether to display cluster cell count proportions by sample
#'   (calculated from \code{d_counts}). Default = FALSE.
#' 
#' @param format_vals Whether to display p-values and adjusted p-values using scientific
#'   notation. This improves readability when displaying a table of values, but converts
#'   the numeric values to character strings, so should be disabled if the values are used
#'   for subsequent steps (e.g. plotting). Default = TRUE.
#' 
#' @param digits Number of decimal places to show, if \code{format_vals = TRUE}. Default =
#'   2.
#' 
#' 
#' @return Returns a \code{\link{DataFrame}} table of results for the \code{top_n}
#'   clusters or cluster-marker combinations, ordered by values in column \code{order_by}
#'   (default: adjusted p-values). Optionally, cluster counts or proportions are also
#'   included.
#' 
#' 
#' @importFrom SummarizedExperiment rowData
#' @importFrom utils head
#' 
#' @export
#' 
#' @examples
#' # For a complete workflow example demonstrating each step in the 'diffcyt' pipeline, 
#' # see the package vignette.
#' 
#' # Function to create random data (one sample)
#' d_random <- function(n = 20000, mean = 0, sd = 1, ncol = 20, cofactor = 5) {
#'   d <- sinh(matrix(rnorm(n, mean, sd), ncol = ncol)) * cofactor
#'   colnames(d) <- paste0("marker", sprintf("%02d", 1:ncol))
#'   d
#' }
#' 
#' # Create random data (without differential signal)
#' set.seed(123)
#' d_input <- list(
#'   sample1 = d_random(), 
#'   sample2 = d_random(), 
#'   sample3 = d_random(), 
#'   sample4 = d_random()
#' )
#' 
#' # Add differential abundance (DA) signal
#' ix_DA <- 801:900
#' ix_cols_type <- 1:10
#' d_input[[3]][ix_DA, ix_cols_type] <- d_random(n = 1000, mean = 2, ncol = 10)
#' d_input[[4]][ix_DA, ix_cols_type] <- d_random(n = 1000, mean = 2, ncol = 10)
#' 
#' # Add differential states (DS) signal
#' ix_DS <- 901:1000
#' ix_cols_DS <- 19:20
#' d_input[[1]][ix_DS, ix_cols_type] <- d_random(n = 1000, mean = 3, ncol = 10)
#' d_input[[2]][ix_DS, ix_cols_type] <- d_random(n = 1000, mean = 3, ncol = 10)
#' d_input[[3]][ix_DS, c(ix_cols_type, ix_cols_DS)] <- d_random(n = 1200, mean = 3, ncol = 12)
#' d_input[[4]][ix_DS, c(ix_cols_type, ix_cols_DS)] <- d_random(n = 1200, mean = 3, ncol = 12)
#' 
#' experiment_info <- data.frame(
#'   sample_id = factor(paste0("sample", 1:4)), 
#'   group_id = factor(c("group1", "group1", "group2", "group2")), 
#'   stringsAsFactors = FALSE
#' )
#' 
#' marker_info <- data.frame(
#'   channel_name = paste0("channel", sprintf("%03d", 1:20)), 
#'   marker_name = paste0("marker", sprintf("%02d", 1:20)), 
#'   marker_class = factor(c(rep("type", 10), rep("state", 10)), 
#'                         levels = c("type", "state", "none")), 
#'   stringsAsFactors = FALSE
#' )
#' 
#' # Create design matrix
#' design <- createDesignMatrix(experiment_info, cols_design = 2)
#' 
#' # Create contrast matrix
#' contrast <- createContrast(c(0, 1))
#' 
#' # Test for differential abundance (DA) of clusters (using default method 'diffcyt-DA-edgeR')
#' out_DA <- diffcyt(d_input, experiment_info, marker_info, 
#'                   design = design, contrast = contrast, 
#'                   analysis_type = "DA", method_DA = "diffcyt-DA-edgeR", 
#'                   seed_clustering = 123, verbose = FALSE)
#' 
#' # Test for differential states (DS) within clusters (using default method 'diffcyt-DS-limma')
#' out_DS <- diffcyt(d_input, experiment_info, marker_info, 
#'                   design = design, contrast = contrast, 
#'                   analysis_type = "DS", method_DS = "diffcyt-DS-limma", 
#'                   seed_clustering = 123, plot = FALSE, verbose = FALSE)
#' 
#' # Display results for top DA clusters
#' topTable(out_DA)
#' 
#' # Display results for top DS cluster-marker combinations
#' topTable(out_DS)
#' 
topTable <- function(res, d_counts = NULL, order = TRUE, order_by = "p_adj", 
                     all = FALSE, top_n = 20, 
                     show_counts = FALSE, show_props = FALSE, 
                     format_vals = TRUE, digits = 2) {
  
  # if output is from wrapper function, extract 'res' and 'd_counts' objects
  if (all(c("res", "d_counts") %in% names(res))) {
    d_counts <- res$d_counts
    res <- res$res
  }
  
  out <- rowData(res)
  
  # include cluster cell counts and/or proportions
  if (show_counts | show_props) {
    out_counts <- assay(d_counts)
    out_props <- t(t(out_counts) / colSums(out_counts)) * 100
    n_rep <- nrow(out) / nrow(out_counts)
    if (!all(out$cluster_id[seq_len(nrow(out_counts))] == rownames(out_counts))) {
      stop("Cluster IDs in 'res' and 'd_counts' do not match")
    }
    if (!(nrow(out) == n_rep * nrow(out_counts))) {
      stop("Cluster IDs in 'res' and 'd_counts' do not match")
    }
    out_counts <- do.call("rbind", replicate(n_rep, out_counts, simplify = FALSE))
    out_props <- do.call("rbind", replicate(n_rep, out_props, simplify = FALSE))
    colnames(out_counts) <- paste("counts", colnames(out_counts), sep = "_")
    colnames(out_props) <- paste("props", colnames(out_props), sep = "_")
  }
  
  if (show_counts) {
    stopifnot(nrow(out) == nrow(out_counts))
    out <- cbind(out, out_counts)
  }
  if (show_props) {
    stopifnot(nrow(out) == nrow(out_props))
    out <- cbind(out, out_props)
  }
  
  # order rows
  if (order & !(order_by %in% colnames(out))) {
    stop("column 'order_by' not found in column names of output object")
  }
  if (order) {
    out <- out[order(out[, order_by]), , drop = FALSE]
  }
  
  # if output is from DS tests, keep additional column 'marker'
  if ("marker_id" %in% colnames(out)) {
    out <- out[, c("cluster_id", "marker_id", "p_val", "p_adj"), drop = FALSE]
    if (format_vals) {
      out[, c("p_val")] <- formatC(out[, c("p_val")], format = "e", digits = digits)
      out[, c("p_adj")] <- formatC(out[, c("p_adj")], format = "e", digits = digits)
    }
  } else {
    out <- out[, c("cluster_id", "p_val", "p_adj"), drop = FALSE]
    if (format_vals) {
      out[, c("p_val")] <- formatC(out[, c("p_val")], format = "e", digits = digits)
      out[, c("p_adj")] <- formatC(out[, c("p_adj")], format = "e", digits = digits)
    }
  }
  
  if (all) {
    out <- out
  } else {
    out <- head(out, top_n)
  }
  
  out
}

