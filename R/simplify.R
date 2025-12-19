' Simplify Countline Name
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
#' @importFrom sf st_centroid
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

    # Aggregate
    # Note: summarise on sf object automatically unions geometry
    aggregated <- metadata |>
        dplyr::group_by(!!dplyr::sym(grp_col)) |> 
        dplyr::summarise(
            ids = paste(id, collapse = ","),
            names = paste(name, collapse = ","),
            n_countlines = dplyr::n(),
            .groups = "drop"
        )
    
    # Rename grouping column to 'id' for the output
    # Using rename with dynamic name requires := or similar, but rename(new = old) works with standard eval if we verify col name
    # We know the column is named whatever grp_col is.
    # Simplest way is to just set the name
    names(aggregated)[names(aggregated) == grp_col] <- "id"

    if (centroids) {
        aggregated <- sf::st_centroid(aggregated)
    }

    aggregated
}
