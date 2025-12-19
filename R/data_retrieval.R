# Get All Countline Counts for an Annual Period
#'
#' Retrieves count data for all available countlines over a one-year period.
#' This function iterates through all countlines found in metadata and calls
#' `get_counts()` for each, combining the results into a single data frame.
#'
#' @param end_date The end date for the one-year period (POSIXct object).
#'   Defaults to the current system time.
#' @param time_bucket Time bucket size (e.g. "1h", "5m"). Defaults to "24h".
#' @return A data frame of counts.
#' @export
get_all_countline_counts_annual <- function(end_date = Sys.time(), time_bucket = "24h") {
  start_date <- end_date - as.difftime(1, units = "days") * 365 # Roughly 1 year

  metadata_sf <- get_countline_metadata()
  all_countline_ids <- metadata_sf$id

  message(paste("Fetching annual counts for", length(all_countline_ids), "countlines."))

  # Use a loop to handle errors gracefully for each countline
  all_counts_list <- list()
  for (id in all_countline_ids) {
    message(paste("  Fetching counts for ID:", id))
    tryCatch({
      counts_for_id <- get_counts(
        countline_ids = id,
        from = start_date,
        to = end_date,
        time_bucket = time_bucket
      )
      all_counts_list[[as.character(id)]] <- counts_for_id
    }, error = function(e) {
      message(paste("  Failed to get counts for ID", id, ":", e$message))
    })
  }
  
  final_df <- dplyr::bind_rows(all_counts_list)
  return(final_df)
}
