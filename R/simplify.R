#' Simplify Countline ID
#'
#' Extracts the unique sensor identifier from a compound countline ID.
#' Assumes the format "SensorID_Specifics".
#'
#' @param id A character vector of countline IDs.
#' @return A character vector of simplified IDs.
#' @export
#' @examples
#' id_simplify("S38_in")
#' id_simplify("S38_out")
id_simplify <- function(id) {
    # Convert to character if needed
    id <- as.character(id)
    # Extract everything before the first underscore
    # If no underscore, return the original string
    sub("^([^_]+)_.*$", "\\1", id)
}

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

#' Aggregate Counts by Simplified ID
#'
#' Aggregates count data by simplifying the countline IDs and summing the counts.
#' This is useful when you have multiple countlines for the same sensor (e.g. "S38_in" and "S38_out")
#' and want to analyze the total traffic for the sensor.
#'
#' @param data A data frame of counts, typically from `get_counts()`.
#' @param simplify_fn A function to simplify the IDs. Defaults to `id_simplify`.
#'   Can also be `name_simplify` if the ID column contains names.
#' @return A data frame with aggregated counts.
#' @importFrom dplyr group_by summarise across all_of where
#' @export
aggregate_counts <- function(data, simplify_fn = id_simplify) {
    # Check if id column exists
    if (!"id" %in% names(data)) {
        stop("Data must have an 'id' column.")
    }

    # Apply simplification
    data$id <- simplify_fn(data$id)

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

#' Aggregate Metadata by Simplified ID
#'
#' Aggregates countline metadata by simplifying the IDs and returning one row per sensor.
#' Detailed attributes that vary within a sensor group (like specific countline IDs) are dropped,
#' keeping only the simplified ID and the unioned geometry.
#'
#' @param metadata An sf object of countline metadata, typically from `get_countline_metadata()`.
#' @param simplify_fn A function to simplify the IDs. Defaults to `id_simplify`.
#'   If `name_simplify` is used, the function will look for a "name" column.
#'   Otherwise it uses the "id" column.
#' @param centroids Logical. If TRUE (default), converts the aggregated geometry to centroids.
#' @return An sf object with aggregated metadata.
#' @importFrom dplyr group_by summarise slice
#' @importFrom sf st_union st_centroid
#' @export
aggregate_meta <- function(metadata, simplify_fn = id_simplify, centroids = TRUE) {
    # Determine target column based on simplify_fn
    target_col <- "id"
    # Check if the passed function is identical to name_simplify
    # Note: This relies on the user passing the function object from the package
    if (identical(simplify_fn, name_simplify)) {
        target_col <- "name"
    }

    # Check if target column exists
    if (!target_col %in% names(metadata)) {
        stop(sprintf("Metadata must have a '%s' column.", target_col))
    }

    # Apply simplification to a new column to allow grouping
    # We use the target column's Simplified value as the new ID
    metadata$id <- simplify_fn(metadata[[target_col]])

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
