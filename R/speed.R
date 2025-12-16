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
      from = to_vivacity_date(from),
      to = to_vivacity_date(to),
      time_bucket = time_bucket
    )

  resp <- perform_request(req)

  purrr::map_df(names(resp), function(id) {
    records <- resp[[id]]
    if (length(records) == 0) {
      return(tibble::tibble())
    }

    if (!is.data.frame(records)) {
      return(purrr::map_df(records, function(rec) {
        cw_mean <- if (!is.null(rec$clockwise$total$mean)) rec$clockwise$total$mean else NA
        acw_mean <- if (!is.null(rec$anti_clockwise$total$mean)) rec$anti_clockwise$total$mean else NA

        mean_speed <- mean(c(cw_mean, acw_mean), na.rm = TRUE)
        if (is.nan(mean_speed)) mean_speed <- NA

        tibble::tibble(
          id = id,
          from = as.POSIXct(rec$from, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC"),
          to = as.POSIXct(rec$to, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC"),
          mean_speed_cw = cw_mean,
          mean_speed_acw = acw_mean,
          mean_speed = mean_speed
        )
      }))
    }

    # Handle dataframe structure
    extract_mean <- function(col_data) {
      if (is.data.frame(col_data)) {
        # Try to find 'total' df then 'mean' column, or just 'mean' column if flattened differently?
        # Typically clockwise$total is a dataframe row/col with 'mean'.
        # Inspect structure if possible, but assuming standard 'total$mean' equivalent
        if ("total" %in% names(col_data)) {
          total_obj <- col_data$total
          if (is.data.frame(total_obj)) {
            return(total_obj$mean)
          }
          if (is.list(total_obj)) {
            return(total_obj$mean)
          }
        }
        # Fallback if structure varies
        return(rep(NA, nrow(col_data)))
      }
      return(rep(NA, nrow(records)))
    }

    cw_mean <- if ("clockwise" %in% names(records)) extract_mean(records$clockwise) else rep(NA, nrow(records))
    acw_mean <- if ("anti_clockwise" %in% names(records)) extract_mean(records$anti_clockwise) else rep(NA, nrow(records))

    # Vectorized mean
    mean_speed <- rowMeans(cbind(cw_mean, acw_mean), na.rm = TRUE)
    mean_speed[is.nan(mean_speed)] <- NA

    tibble::tibble(
      id = id,
      from = as.POSIXct(records$from, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC"),
      to = as.POSIXct(records$to, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC"),
      mean_speed_cw = cw_mean,
      mean_speed_acw = acw_mean,
      mean_speed = mean_speed
    )
  })
}
