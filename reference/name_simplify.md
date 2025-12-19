# Simplify Countline Name

Extracts the unique sensor component from a countline name. Assumes the
format "SensorID_Location\_...".

## Usage

``` r
name_simplify(name)
```

## Arguments

- name:

  A character vector of countline names.

## Value

A character vector of simplified names.

## Examples

``` r
name_simplify("S38_eastgate_crossing_lpti")
#> [1] "S38_eastgate"
```
