# Utils
vivacity_base_url <- function() {
  "https://api.vivacitylabs.com"
}

get_vivacity_key <- function() {
  key <- Sys.getenv("VIVACITY_API_KEY")
  if (identical(key, "")) {
    stop("VIVACITY_API_KEY environment variable is not set.", call. = FALSE)
  }
  key
}

vivacity_req <- function(endpoint) {
  httr2::request(vivacity_base_url()) |>
    httr2::req_url_path_append(endpoint) |>
    httr2::req_headers("x-vivacity-api-key" = get_vivacity_key()) |>
    httr2::req_user_agent("vivarcity R package")
}

perform_request <- function(req) {
  resp <- httr2::req_perform(req)
  if (httr2::resp_status(resp) == 200) {
    httr2::resp_body_json(resp, simplifyVector = TRUE)
  } else {
    httr2::resp_check_status(resp)
  }
}
