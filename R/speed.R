#' Get Countline Speeds
#'
#' @param countline_ids Vector of countline IDs.
#' @param from Start timestamp.
#' @param to End timestamp.
#' @param time_bucket Time bucket size (e.g. "1h", "5m"). Defaults to "1h".
#' @return Data frame of speeds.
#' @export
get_countline_speed <- function(countline_ids, from, to, time_bucket = "1h") {
  req <- vivacity_req("countline/speed") |>
    httr2::req_url_query(
      countline_ids = paste(countline_ids, collapse = ","),
      from = from,
      to = to,
      time_bucket = time_bucket
    )
  perform_request(req)
}
