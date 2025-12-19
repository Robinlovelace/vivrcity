#' Aggregate Counts
#'
#' Aggregates count data. This sums counts across directions (and any other non-grouping columns)
#' for the same ID, time, and class.
#'
#' It attempts to intelligently aggregate by sensor by checking for a `sensor_name` column (created by `get_counts()`).
#' If `sensor_name` is missing but `name` is present, it will derive `sensor_name` from `name`.
#' If neither is present, it aggregates by the existing `id` (and treats it as the sensor name).
#'
#' @param data A data frame of counts, typically from `get_counts()`.
#' @return A data frame with aggregated counts, including a `sensor_name` column.
#' @importFrom dplyr group_by summarise across all_of where mutate
#' @export
aggregate_counts <- function(data) {
    # Ensure sensor_name exists
    if (!"sensor_name" %in% names(data)) {
        if ("name" %in% names(data)) {
            data$sensor_name <- name_simplify(data$name)
        } else if ("id" %in% names(data)) {
            data$sensor_name <- data$id
        } else {
            stop("Data must have 'sensor_name', 'name', or 'id' column.")
        }
    }

    # Determine grouping columns
    # We group by sensor_name
    group_cols <- c("sensor_name", "from", "to")
    if ("class" %in% names(data)) {
        group_cols <- c(group_cols, "class")
    }

    # Ensure group columns exist (e.g. from, to)
    missing_cols <- setdiff(group_cols, names(data))
    if (length(missing_cols) > 0) {
        stop(paste("Data missing expected columns:", paste(missing_cols, collapse = ", ")))
    }

    # Aggregate
    data |>
        dplyr::group_by(dplyr::across(dplyr::all_of(group_cols))) |>
        dplyr::summarise(
            dplyr::across(dplyr::where(is.numeric), \(x) sum(x, na.rm = TRUE)),
            .groups = "drop"
        )
}

#' Aggregate Metadata
#'
#' Aggregates countline metadata by simplifying the countline names (extracting the sensor ID)
#' and returning one row per sensor.
#' It combines original IDs and names into comma-separated strings and counts the number of countlines per sensor.
#'
#' @param metadata An sf object of countline metadata, typically from `get_countline_metadata()`.
#' @param centroids Logical. If TRUE (default), converts the aggregated geometry to centroids.
#' @return An sf object with aggregated metadata, including a `sensor_name` column.
#' @importFrom dplyr group_by summarise rename n sym left_join select mutate
#' @importFrom sf st_centroid st_is_empty st_combine st_drop_geometry st_as_sf
#' @export
aggregate_metadata <- function(metadata, centroids = TRUE) {
    # Ensure sensor_name exists
    if (!"sensor_name" %in% names(metadata)) {
        if ("name" %in% names(metadata)) {
            metadata$sensor_name <- name_simplify(metadata$name)
        } else {
             stop("Metadata must have a 'sensor_name' or 'name' column.")
        }
    }

    # Remove empty geometries
    metadata <- metadata[!sf::st_is_empty(metadata), ]

    # Ensure sensor_name is character
    metadata$sensor_name <- as.character(metadata$sensor_name)

    # Aggregate attributes
    attr_df <- metadata |>
        sf::st_drop_geometry() |>
        dplyr::group_by(sensor_name) |>
        dplyr::summarise(
            ids = paste(id, collapse = ","),
            names = paste(name, collapse = ","),
            n_countlines = dplyr::n(),
            .groups = "drop"
        )
    
    # Aggregate geometry
    # Group by sensor_name
    geom_sf <- metadata |>
        dplyr::select(sensor_name) |>
        dplyr::group_by(sensor_name) |>
        dplyr::summarise(
            geometry = sf::st_combine(geometry),
            .groups = "drop"
        )
    
    # Combine
    aggregated <- dplyr::left_join(attr_df, geom_sf, by = "sensor_name") |>
        sf::st_as_sf() 
    
    if (centroids) {
        aggregated <- sf::st_centroid(aggregated)
    }

    aggregated
}