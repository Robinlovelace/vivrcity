#' Convert input time to Vivacity ISO8601 string
#'
#' @param x A PostIXct, Date, or character object.
#' @return A character string in ISO8601 format (UTC).
#' @noRd
to_vivacity_date <- function(x) {
  if (inherits(x, c("POSIXt", "Date"))) {
    format(as.POSIXct(x), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  } else {
    as.character(x)
  }
}

#' Split a date range into batches of max_days
#'
#' The Vivacity API limits requests to 7 days. This helper splits longer
#' date ranges into chunks that respect this limit.
#'
#' @param from Start POSIXct
#' @param to End POSIXct
#' @param max_days Maximum days per batch (default 7)
#' @return A list of list(from, to) pairs
#' @noRd
batch_date_range <- function(from, to, max_days = 7) {
  from <- as.POSIXct(from, tz = "UTC")
  to <- as.POSIXct(to, tz = "UTC")

  max_seconds <- max_days * 24 * 60 * 60
  total_seconds <- as.numeric(difftime(to, from, units = "secs"))

  if (total_seconds <= max_seconds) {
    return(list(list(from = from, to = to)))
  }

  batches <- list()
  current_from <- from


  while (current_from < to) {
    current_to <- min(current_from + max_seconds, to)
    batches <- c(batches, list(list(from = current_from, to = current_to)))
    current_from <- current_to
  }

  batches
}
