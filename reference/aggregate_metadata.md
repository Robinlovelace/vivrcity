# Aggregate Metadata

Aggregates countline metadata by simplifying the countline names
(extracting the sensor ID) and returning one row per sensor. It combines
original IDs and names into comma-separated strings and counts the
number of countlines per sensor.

## Usage

``` r
aggregate_metadata(metadata, centroids = TRUE)
```

## Arguments

- metadata:

  An sf object of countline metadata, typically from
  [`get_countline_metadata()`](https://robinlovelace.github.io/vivrcity/reference/get_countline_metadata.md).

- centroids:

  Logical. If TRUE (default), converts the aggregated geometry to
  centroids.

## Value

An sf object with aggregated metadata.
