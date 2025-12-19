#' Aggregate Counts
#'
#' Aggregates count data. This sums counts across directions (and any other non-grouping columns)
#' for the same ID, time, and class.
#'
#' It attempts to intelligently aggregate by sensor by checking for a `sensor_name` column (created by `get_counts()`).
#' If `sensor_name` is missing but `name` is present, it will derive `sensor_name` from `name`.
#' If neither is present, it aggregates by the existing `id`.
#'
#' @param data A data frame of counts, typically from `get_counts()`.
#' @return A data frame with aggregated counts.
#' @importFrom dplyr group_by summarise across all_of where
#' @export
aggregate_counts <- function(data) {
    # Check if id column exists
    if (!"id" %in% names(data)) {
        stop("Data must have an 'id' column.")
    }

    # Determine grouping ID
    # Priority: sensor_name > derived from name > existing id
    if ("sensor_name" %in% names(data)) {
        data$id <- data$sensor_name
    } else if ("name" %in% names(data)) {
        data$id <- name_simplify(data$name)
    }
    
    # Determine grouping columns: id, from, to.
    # And 'class' if it exists.
    group_cols <- c("id", "from", "to")
    if ("class" %in% names(data)) {
        group_cols <- c(group_cols, "class")
    }

    # Ensure group columns exist
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
#' @return An sf object with aggregated metadata.
#' @importFrom dplyr group_by summarise rename n sym
#' @importFrom sf st_centroid st_is_empty st_combine
#' @export
aggregate_metadata <- function(metadata, centroids = TRUE) {
    # Determine grouping column
    if ("sensor_name" %in% names(metadata)) {
        grp_col <- "sensor_name"
    } else if ("name" %in% names(metadata)) {
        metadata$sensor_name <- name_simplify(metadata$name)
        grp_col <- "sensor_name"
    } else {
         stop("Metadata must have a 'sensor_name' or 'name' column.")
    }

    # Remove empty geometries to avoid unioning/centroid issues
    metadata <- metadata[!sf::st_is_empty(metadata), ]

    # Aggregate
    # We use st_combine explicitly to ensure each group results in a single 
    # multi-geometry object, avoiding row mismatch errors in some sf/dplyr versions.
    aggregated <- metadata |>
        dplyr::group_by(!!dplyr::sym(grp_col)) |> 
        dplyr::summarise(
            ids = paste(id, collapse = ","),
            names = paste(name, collapse = ","),
            n_countlines = dplyr::n(),
            geometry = sf::st_combine(geometry),
            .groups = "drop"
        )
    
    # Rename grouping column to 'id' for the output
    aggregated <- aggregated |> 
        dplyr::rename(id = !!dplyr::sym(grp_col))

    if (centroids) {
        aggregated <- sf::st_centroid(aggregated)
    }

    aggregated
}