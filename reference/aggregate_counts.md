# Aggregate Counts

Aggregates count data. This sums counts across directions (and any other
non-grouping columns) for the same ID, time, and class.

## Usage

``` r
aggregate_counts(data)
```

## Arguments

- data:

  A data frame of counts, typically from
  [`get_counts()`](https://robinlovelace.github.io/vivrcity/reference/get_counts.md).

## Value

A data frame with aggregated counts.

## Details

It attempts to intelligently aggregate by sensor by checking for a
`sensor_name` column (created by
[`get_counts()`](https://robinlovelace.github.io/vivrcity/reference/get_counts.md)).
If `sensor_name` is missing but `name` is present, it will derive
`sensor_name` from `name`. If neither is present, it aggregates by the
existing `id`.
