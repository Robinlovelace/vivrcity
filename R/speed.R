#' Get Countline Speeds
#'
#' @param countline_ids Vector of countline IDs.
#' @param from Start timestamp.
#' @param to End timestamp.
#' @return Data frame of speeds.
#' @export
get_countline_speed <- function(countline_ids, from, to) {
  req <- vivacity_req("countline/speed") |>
    httr2::req_url_query(
      countline_ids = paste(countline_ids, collapse = ","),
      from = from,
      to = to
    )
  perform_request(req)
}
