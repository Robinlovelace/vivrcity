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
    httr2::req_user_agent("vivrcity R package")
}

perform_request <- function(req) {
  # We use tryCatch to catch the error thrown by req_perform
  # and try to extract the body if its an HTTP error
  tryCatch(
    {
      resp <- httr2::req_perform(req)
      httr2::resp_body_json(resp, simplifyVector = TRUE)
    },
    error = function(e) {
      if (inherits(e, "httr2_http_error")) {
        body <- try(httr2::resp_body_string(e$response), silent = TRUE)
        if (!inherits(body, "try-error") && nzchar(body)) {
          stop(sprintf(
            "API Error (%s): %s\nBody: %s",
            httr2::resp_status(e$response),
            e$message,
            body
          ), call. = FALSE)
        }
      }
      stop(e)
    }
  )
}
