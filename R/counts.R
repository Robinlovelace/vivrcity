# Get Countline Counts
#'
#' @param countline_ids Vector of countline IDs.
#' @param from Start timestamp.
#' @param to End timestamp.
#' @param classes Vector of classes to include.
#' @param time_bucket Time bucket size (e.g. "1h", "5m"). Defaults to "1h".
#' @return Data frame of counts.
#' @export
get_countline_counts <- function(countline_ids, from, to, classes = NULL, time_bucket = "1h") {
  req <- vivacity_req("countline/counts") |>
    httr2::req_url_query(
      countline_ids = paste(countline_ids, collapse = ","),
      from = from,
      to = to,
      classes = if (!is.null(classes)) paste(classes, collapse = ",") else NULL,
      time_bucket = time_bucket
    )
  perform_request(req)
}
