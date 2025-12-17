#' Get and Process Countline Counts
#'
#' Retrieves raw countline counts and processes them into a tidy data frame
#' with separate columns for each vehicle class and direction.
#'
#' @param countline_ids Vector of countline IDs.
#' @param from Start timestamp (ISO 8601 string or POSIXct).
#' @param to End timestamp (ISO 8601 string or POSIXct).
#' @param classes Vector of classes to include. Defaults to all classes.
#' @param time_bucket Time bucket size (e.g. "1h", "5m"). Defaults to "24h".
#' @param wait Seconds to wait between API requests. Defaults to 1.
#' @return A data frame with `id`, `from`, `to`, `class`, `direction`, `count` columns.
#' @export
#' @importFrom dplyr bind_rows mutate select
#' @importFrom tidyr pivot_longer
get_counts <- function(countline_ids, from, to, classes = NULL, time_bucket = "24h", wait = 1) {
  # Ensure times are in UTC and correct format
  if (inherits(from, "POSIXct")) from <- format(from, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  if (inherits(to, "POSIXct")) to <- format(to, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

  raw_counts_df <- get_countline_counts(
    countline_ids = countline_ids,
    from = from,
    to = to,
    classes = classes,
    time_bucket = time_bucket,
    wait = wait
  )

  if (nrow(raw_counts_df) == 0) {
    return(tibble::tibble(
      id = character(), from = character(), to = character(),
      class = character(), direction = character(), count = numeric()
    ))
  }

  # Process the dataframe into a tidy format
  # get_countline_counts returns: id, from, to, clockwise, anti_clockwise, count
  # We drop the existing 'count' (total) column to avoid collision with values_to="count"
  processed_df <- raw_counts_df |>
    dplyr::select(-count) |>
    tidyr::pivot_longer(
      cols = c("clockwise", "anti_clockwise"),
      names_to = "direction",
      values_to = "count"
    ) |>
    dplyr::mutate(class = "all") |>
    dplyr::select(id, from, to, class, direction, count)

  return(processed_df)
}
