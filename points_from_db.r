# Load required libraries
library(DBI)
library(duckdb)
library(spatstat.geom)
library(sparr)
library(terra)
# Connect to the DuckDB database
con <- dbConnect(duckdb::duckdb(), "~/indrevdiffusion/Data/patents_db.duckdb")



# Function to safely get table schema
get_table_schema <- function(con, table_name) {
  tryCatch({
    dbGetQuery(con, paste("DESCRIBE", table_name))
  }, error = function(e) {
    message(paste("Error getting schema for table", table_name, ":", e$message))
    NULL
  })
}

# Get schemas
patents_schema <- get_table_schema(con, "patents")
patentees_schema <- get_table_schema(con, "patentees")

# Construct the query
query <- "
SELECT 
    p.publication_number,
    p.publication_date,
    p.country_code,
    p.kind_code,
    p.origin,
    p.kind_codes,
    p.has_A,
    p.has_B,
    pt.loc_longitude,
    pt.loc_latitude,
    pt.person_id,
    pt.loc_city,
    pt.loc_text
FROM 
    patents p
JOIN 
    patentees pt ON p.publication_number = pt.publication_number
WHERE 
    p.publication_date <= '1900-12-31'
    AND p.country_code IN ('US', 'GB')
ORDER BY 
    p.publication_number, pt.person_id
"

# Execute the query and fetch the results
tryCatch({
  result_df <- dbGetQuery(con, query)
  
  # Print the first few rows and a summary
  
  # Optionally, save the result to a CSV file
  
}, error = function(e) {
  message("Error executing query: ", e$message)
}, finally = {
  # Close the database connection
  dbDisconnect(con)
})
points <- terra::vect(result_df, geom = c("loc_longitude", "loc_latitude"), crs = "EPSG:4326", keepgeom = FALSE)
europe <- vect("C:/Users/BADINO/Downloads/Europe_coastline_shapefile/Europe_coastline.shp")
# Reproject points to match the CRS of the Europe polygon
points <- project(points, crs(europe))

# Plot the points
plot(points)