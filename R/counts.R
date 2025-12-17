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
  # Split into 7-day batches to respect API limits
  batches <- batch_date_range(from, to, max_days = 7)

  # Fetch each batch and combine
  purrr::map_df(batches, function(batch) {
    fetch_counts_batch(countline_ids, batch$from, batch$to, classes, time_bucket)
  })
}

#' Internal function to fetch a single batch of counts
#' @noRd
fetch_counts_batch <- function(countline_ids, from, to, classes = NULL, time_bucket = "1h") {
  req <- vivacity_req("countline/counts") |>
    httr2::req_url_query(
      countline_ids = paste(countline_ids, collapse = ","),
      from = to_vivacity_date(from),
      to = to_vivacity_date(to),
      classes = if (!is.null(classes)) paste(classes, collapse = ",") else NULL,
      time_bucket = time_bucket
    )

  resp <- perform_request(req)

  # Parse response into a tibble
  purrr::map_df(names(resp), function(id) {
    records <- resp[[id]]
    if (length(records) == 0) {
      return(tibble::tibble())
    }

    # If records is a list (simplifyVector failed or inconsistent), use map_df
    if (!is.data.frame(records)) {
      return(purrr::map_df(records, function(rec) {
        cw <- if (!is.null(rec$clockwise$total)) rec$clockwise$total else 0
        acw <- if (!is.null(rec$anti_clockwise$total)) rec$anti_clockwise$total else 0
        tibble::tibble(
          id = id,
          from = as.POSIXct(rec$from, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC"),
          to = as.POSIXct(rec$to, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC"),
          clockwise = cw,
          anti_clockwise = acw,
          count = cw + acw
        )
      }))
    }

    # If records IS a dataframe (simplifyVector succeeded)
    get_total <- function(col_data) {
      if (is.data.frame(col_data)) {
        if ("total" %in% names(col_data)) {
          return(col_data$total)
        }
        rowSums(dplyr::select(col_data, dplyr::where(is.numeric)), na.rm = TRUE)
      } else if (is.vector(col_data) || is.null(col_data)) {
        return(0)
      } else {
        0
      }
    }

    cw <- if ("clockwise" %in% names(records)) get_total(records$clockwise) else 0
    acw <- if ("anti_clockwise" %in% names(records)) get_total(records$anti_clockwise) else 0

    tibble::tibble(
      id = id,
      from = as.POSIXct(records$from, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC"),
      to = as.POSIXct(records$to, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC"),
      clockwise = cw,
      anti_clockwise = acw,
      count = cw + acw
    )
  })
}

#' Get Countline Counts by Class/Mode
#'
#' Returns counts broken down by transport class (pedestrian, cyclist, etc.)
#'
#' @param countline_ids Vector of countline IDs.
#' @param from Start timestamp.
#' @param to End timestamp.
#' @param time_bucket Time bucket size (e.g. "1h", "5m"). Defaults to "1h".
#' @return Data frame with counts by class in long format.
#' @export
get_countline_counts_by_class <- function(countline_ids, from, to, time_bucket = "1h") {
  batches <- batch_date_range(from, to, max_days = 7)

  purrr::map_df(batches, function(batch) {
    fetch_counts_by_class_batch(countline_ids, batch$from, batch$to, time_bucket)
  })
}

#' Internal function to fetch a single batch of counts by class
#' @noRd
fetch_counts_by_class_batch <- function(countline_ids, from, to, time_bucket = "1h") {
  req <- vivacity_req("countline/counts") |>
    httr2::req_url_query(
      countline_ids = paste(countline_ids, collapse = ","),
      from = to_vivacity_date(from),
      to = to_vivacity_date(to),
      time_bucket = time_bucket
    )

  resp <- perform_request(req)

  purrr::map_df(names(resp), function(id) {
    records <- resp[[id]]
    if (length(records) == 0 || !is.data.frame(records)) {
      return(tibble::tibble())
    }

    # Extract class columns from clockwise and anti_clockwise
    result <- tibble::tibble(
      id = id,
      from = as.POSIXct(records$from, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC"),
      to = as.POSIXct(records$to, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")
    )

    # Get class names from clockwise (they should be the same in anti_clockwise)
    class_names <- character(0)
    if ("clockwise" %in% names(records) && is.data.frame(records$clockwise)) {
      class_names <- names(records$clockwise)
    }

    # Add each class column
    for (cls in class_names) {
      cw_val <- if ("clockwise" %in% names(records) && cls %in% names(records$clockwise)) {
        records$clockwise[[cls]]
      } else {
        0
      }
      acw_val <- if ("anti_clockwise" %in% names(records) && cls %in% names(records$anti_clockwise)) {
        records$anti_clockwise[[cls]]
      } else {
        0
      }
      # Replace NA with 0 and sum
      cw_val[is.na(cw_val)] <- 0
      acw_val[is.na(acw_val)] <- 0
      result[[cls]] <- cw_val + acw_val
    }

    # Pivot to long format
    if (length(class_names) > 0) {
      result |>
        tidyr::pivot_longer(
          cols = dplyr::all_of(class_names),
          names_to = "class",
          values_to = "count"
        )
    } else {
      result
    }
  })
}
