#' Get Countline Counts
#'
#' Simple wrapper to get countline counts with class breakdown by default.
#' This is the recommended function for most use cases.
#' It automatically fetches metadata to add `name` and `sensor_name` columns,
#' enabling easier aggregation by sensor.
#'
#' @param countline_ids Vector of countline IDs.
#' @param from Start timestamp.
#' @param to End timestamp.
#' @param by_class If TRUE (default), returns counts broken down by transport
#'   class (pedestrian, cyclist, etc.) in long format. If FALSE, returns
#'   total counts only.
#' @param split_direction If TRUE (default), preserves direction information.
#'   If FALSE, sums counts across directions.
#' @param aggregate If TRUE, aggregates the results by sensor (summing directions
#'   and combining countlines belonging to the same sensor). Defaults to FALSE.
#' @param time_bucket Time bucket size (e.g. "1h", "5m"). Defaults to "24h".
#' @param wait Seconds to wait between API requests. Defaults to 1.
#' @return A data frame with columns `id`, `sensor_name`, `name`, `from`, `to`, `class`, `direction`, `count`.
#'   If `by_class` is FALSE, `class` will be "all".
#'   If `split_direction` is FALSE, `direction` column is omitted (counts are summed).
#'   If `aggregate` is TRUE, `id` column will contain the sensor name, and the `direction` and `name` columns are removed.
#' @export
get_counts <- function(countline_ids, from, to, by_class = TRUE, split_direction = TRUE, aggregate = FALSE, time_bucket = "24h", wait = 1) {
  batches <- batch_date_range(from, to, max_days = 7)

  # Fetch counts
  counts_df <- if (by_class) {
    purrr::map_df(batches, function(batch) {
      if (wait > 0) Sys.sleep(wait)
      tryCatch({
        fetch_counts_by_class_batch(countline_ids, batch$from, batch$to, time_bucket, split_direction)
      }, error = function(e) {
        message(sprintf("Error fetching batch %s to %s: %s", batch$from, batch$to, e$message))
        tibble::tibble()
      })
    })
  } else {
    purrr::map_df(batches, function(batch) {
      if (wait > 0) Sys.sleep(wait)
      tryCatch({
        res <- fetch_counts_batch(countline_ids, batch$from, batch$to, NULL, time_bucket)
        if (nrow(res) == 0) return(res)
        
        if (split_direction) {
           res |>
            dplyr::select(-count) |>
            tidyr::pivot_longer(
              cols = c("clockwise", "anti_clockwise"),
              names_to = "direction",
              values_to = "count"
            ) |>
            dplyr::mutate(class = "all") |>
            dplyr::select(id, from, to, class, direction, count)
        } else {
          # Sum directions (which count already is) and add class=all
          res |>
            dplyr::select(-clockwise, -anti_clockwise) |>
            dplyr::mutate(class = "all")
        }
      }, error = function(e) {
        message(sprintf("Error fetching batch %s to %s: %s", batch$from, batch$to, e$message))
        tibble::tibble()
      })
    })
  }

  # Fetch and join metadata to get name and sensor_name
  if (nrow(counts_df) > 0) {
      meta <- tryCatch({
          get_countline_metadata()
      }, error = function(e) {
          message("Warning: Failed to fetch metadata to populate sensor names: ", e$message)
          NULL
      })

      if (!is.null(meta)) {
          meta_df <- meta |> 
              sf::st_drop_geometry() |> 
              dplyr::select(id, name) |> 
              dplyr::mutate(sensor_name = name_simplify(name))
          
          # Join and reorder
          counts_df <- counts_df |>
              dplyr::left_join(meta_df, by = "id") |>
              dplyr::relocate(sensor_name, name, .after = id)
      }
  }
  
  # Aggregate if requested
  if (aggregate && nrow(counts_df) > 0) {
      counts_df <- aggregate_counts(counts_df)
  }

  return(counts_df)
}

# Get Countline Counts (original function for backward compatibility)
#'
#' @param countline_ids Vector of countline IDs.
#' @param from Start timestamp.
#' @param to End timestamp.
#' @param classes Vector of classes to include.
#' @param time_bucket Time bucket size (e.g. "1h", "5m"). Defaults to "24h".
#' @param wait Seconds to wait between API requests. Defaults to 1.
#' @return Data frame of counts.
#' @export
get_countline_counts <- function(countline_ids, from, to, classes = NULL, time_bucket = "24h", wait = 1) {
  # Split into 7-day batches to respect API limits
  batches <- batch_date_range(from, to, max_days = 7)

  # Fetch each batch and combine
  purrr::map_df(batches, function(batch) {
    if (wait > 0) Sys.sleep(wait)
    tryCatch({
      fetch_counts_batch(countline_ids, batch$from, batch$to, classes, time_bucket)
    }, error = function(e) {
      message(sprintf("Error fetching batch %s to %s: %s", batch$from, batch$to, e$message))
      tibble::tibble()
    })
  })
}

#' Internal function to fetch a single batch of counts
#' @noRd
fetch_counts_batch <- function(countline_ids, from, to, classes = NULL, time_bucket = "24h") {
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
#' @param time_bucket Time bucket size (e.g. "1h", "5m"). Defaults to "24h".
#' @param wait Seconds to wait between API requests. Defaults to 1.
#' @return Data frame with counts by class in long format.
#' @export
get_countline_counts_by_class <- function(countline_ids, from, to, time_bucket = "24h", wait = 1) {
  # We delegate to get_counts with split_direction=FALSE to maintain backward compatibility (summing directions)
  get_counts(countline_ids, from, to, by_class = TRUE, split_direction = FALSE, time_bucket = time_bucket, wait = wait)
}

#' Internal function to fetch a single batch of counts by class
#' @noRd
fetch_counts_by_class_batch <- function(countline_ids, from, to, time_bucket = "24h", split_direction = TRUE) {
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

    base_df <- tibble::tibble(
      id = id,
      from = as.POSIXct(records$from, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC"),
      to = as.POSIXct(records$to, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")
    )
    
    if (split_direction) {
        # Helper to process a direction
        process_direction <- function(dir_name) {
          if (!dir_name %in% names(records) || !is.data.frame(records[[dir_name]])) {
            return(NULL)
          }
          
          dir_data <- records[[dir_name]]
          # Exclude non-numeric columns if any
          dir_data <- dplyr::select(dir_data, dplyr::where(is.numeric))
          
          if (ncol(dir_data) == 0) return(NULL)
          
          # Combine base_df and dir_data
          combined <- dplyr::bind_cols(base_df, dir_data)
          combined$direction <- dir_name
          
          # Pivot
          combined |>
            tidyr::pivot_longer(
                cols = dplyr::all_of(names(dir_data)), 
                names_to = "class", 
                values_to = "count"
            )
        }
    
        cw_df <- process_direction("clockwise")
        acw_df <- process_direction("anti_clockwise")
        
        dplyr::bind_rows(cw_df, acw_df)
    } else {
        # Old logic: sum directions
        
        # Get class names from clockwise
        class_names <- character(0)
        if ("clockwise" %in% names(records) && is.data.frame(records$clockwise)) {
          class_names <- names(records$clockwise)
        }
        # And anti_clockwise
        if ("anti_clockwise" %in% names(records) && is.data.frame(records$anti_clockwise)) {
           class_names <- unique(c(class_names, names(records$anti_clockwise)))
        }
    
        # Add each class column
        result <- base_df
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
    }
  })
}
