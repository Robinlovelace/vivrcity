#' Get Journey Times
#'
#' @param origin_id Origin countline ID.
#' @param dest_id Destination countline ID.
#' @param from Start timestamp.
#' @param to End timestamp.
#' @return Data frame of journey times.
#' @export
get_journey_times <- function(origin_id, dest_id, from, to) {
  req <- vivacity_req("countline/journey_times") |>
    httr2::req_url_query(
      origin_countline_id = origin_id,
      destination_countline_id = dest_id,
      origin_countline_direction = "both",
      destination_countline_direction = "in",
      from = from,
      to = to
    )
  perform_request(req)
}
