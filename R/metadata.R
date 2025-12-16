#' Get Countline Metadata
#'
#' @export
get_countline_metadata <- function() {
  req <- vivacity_req("countline/metadata")
  perform_request(req)
}

#' Get Hardware Metadata
#'
#' @export
get_hardware_metadata <- function() {
  req <- vivacity_req("hardware/metadata")
  perform_request(req)
}
