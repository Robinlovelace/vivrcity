# Get Countline Metadata
#'
#' @importFrom sf st_linestring st_sfc st_sf
#' @importFrom purrr map
#' @importFrom dplyr bind_rows
#' @importFrom tibble tibble
#' @export
get_countline_metadata <- function() {
  raw_metadata <- perform_request(vivacity_req("countline/metadata"))

  if (length(raw_metadata) == 0) {
    return(sf::st_sf(tibble::tibble(), geometry = sf::st_sfc()))
  }

  # Prepare lists to hold attributes and geometries
  attributes_list <- vector("list", length(raw_metadata))
  geometries_list <- vector("list", length(raw_metadata))
  
  for (i in seq_along(raw_metadata)) {
    id <- names(raw_metadata)[[i]]
    item <- raw_metadata[[id]]
    coords <- item$geometry$geo_json$coordinates
    
    # Handle potentially empty or malformed coordinates
    if (is.null(coords) || length(coords) == 0 || is.null(nrow(coords)) || nrow(coords) < 2) {
      geometry <- sf::st_linestring() # Empty linestring
    } else {
      geometry <- sf::st_linestring(coords)
    }
    
    geometries_list[[i]] <- geometry
    
    attributes_list[[i]] <- tibble::tibble(
      id = id,
      name = item$name,
      description = item$description,
      direction = item$direction,
      is_dwell_times_filtering_countline = item$is_dwell_times_filtering_countline,
      is_anpr = item$is_anpr,
      is_speed = item$is_speed,
      modified_at = item$modified_at
    )
  }
  
  # Combine attributes into a data frame
  attributes_df <- dplyr::bind_rows(attributes_list)
  
  # Combine geometries into an sfc object
  sfc_geometries <- sf::st_sfc(geometries_list, crs = 4326) # Assuming WGS 84 for lat/lon

  # Create the sf object
  sf_metadata <- sf::st_sf(attributes_df, geometry = sfc_geometries)
  
  return(sf_metadata)
}

#' Get Hardware Metadata
#'
#' @export
get_hardware_metadata <- function() {
  req <- vivacity_req("hardware/metadata")
  perform_request(req)
}
