```
#' Simplify Countline Name
#'
#' Extracts the unique sensor component from a countline name.
#' Assumes the format "SensorID_Location_...".
#'
#' @param name A character vector of countline names.
#' @return A character vector of simplified names.
#' @export
#' @examples
#' name_simplify("S38_eastgate_crossing_lpti")
name_simplify <- function(name) {
    # Convert to character if needed
    name <- as.character(name)
    # Extract everything before the first underscore
    sub("^([^_]+)_.*$", "\\1", name)
}

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

#' Aggregate Metadata by Sensor
#'
#' Aggregates countline metadata by simplifying the countline names (extracting the sensor ID)
#' and returning one row per sensor.
#'
#' @param metadata An sf object of countline metadata, typically from `get_countline_metadata()`.
#' @param centroids Logical. If TRUE (default), converts the aggregated geometry to centroids.
#' @return An sf object with aggregated metadata.
#' @importFrom dplyr group_by summarise slice
#' @importFrom sf st_union st_centroid
#' @export
aggregate_meta <- function(metadata, centroids = TRUE) {
    # Check if name column exists
    if (!"name" %in% names(metadata)) {
        stop("Metadata must have a 'name' column.")
    }

    # Apply simplification to a new column to allow grouping
    # We use the simplified name as the new ID
    metadata$id <- name_simplify(metadata$name)

    # Aggregate
    aggregated <- metadata |>
        dplyr::group_by(id) |>
        dplyr::summarise(
            countlines = dplyr::n(),
            .groups = "drop"
        )

    if (centroids) {
        aggregated <- sf::st_centroid(aggregated)
    }

    aggregated
}

```