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
