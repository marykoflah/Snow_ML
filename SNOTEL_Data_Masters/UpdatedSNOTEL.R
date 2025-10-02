# ------------------------------------------------------------------------------
# SNOTEL (Midnight Only)
# 
# Author: Hayden Libby
# Modified By: Mary O'Flaherty
# Credit: Developed for snowpack analysis workflows (Montana State University)
# Created: 2025
# Description: Pulls hourly USDA SNOTEL atmospheric/snow variables using the 
# AWDB REST API and extracts only the midnight (00:00) calibrated values over a 
# 21-year period. Missing values are handled and merged into a single daily record.
# Output is saved as a CSV locally.
# ------------------------------------------------------------------------------

library(httr)        # HTTP requests to access the USDA SNOTEL API
library(tibble)      # Tidy data structures
library(dplyr)       # Data wrangling
library(purrr)       # List handling and functional operations
library(glue)        # Inline string formatting
library(lubridate)   # Date/time handling

# ------------------------------------------------------------------------------
# === USER-DEFINED PARAMETERS ===
# ------------------------------------------------------------------------------

# Station triplet for example Burnt Mountain, MT
station_triplet <- "862:MT:SNTL"

# Elements to extract from the SNOTEL API
elements <- c('WTEQ', 'SNWD', 'PREC', 'TAVG', 'RHUM', 'WSPDV', 'SWINV')

# Start and end dates of the analysis period (YEAR-MN-DY format)
start_dateapi <- #"year-mn-dy"
end_dateapi   <- #"year-mn-day"

# URL structure to access the HOURLY data from the USDA AWDB API
# Note: Each element request also includes WTEQ for consistency across all calls
url_base <- glue("https://wcc.sc.egov.usda.gov/awdbRestApi/services/v1/data?stationTriplets={station_triplet}&elements={{replace}}%2C%20WTEQ&duration=HOURLY&beginDate={start_dateapi}&endDate={end_dateapi}&periodRef=END&centralTendencyType=NONE&returnFlags=false&returnOriginalValues=false&returnSuspectData=false")

# ------------------------------------------------------------------------------
# === DOWNLOAD + FILTER MIDNIGHT VALUES ===
# ------------------------------------------------------------------------------

# Initialize a list to hold each variable's time series
data_list <- list()

# Loop through each requested element
for (element in elements) {
  # Replace {replace} in the URL with the current element name
  url <- gsub("\\{replace\\}", element, url_base)
  response <- GET(url)
  
  if (status_code(response) == 200) {
    data <- content(response, "parsed", simplifyVector = TRUE)
    
    # Check if valid data is returned
    if ("data" %in% names(data) && "values" %in% names(data$data[[1]])) {
      values_data <- data$data[[1]]$values[[1]]
      
      # Convert API datetime to POSIXct and filter to 00:00 only
      df <- tibble(
        DateTime = as.POSIXct(values_data$date, format = "%Y-%m-%d %H:%M", tz = "UTC"),
        Value = as.numeric(values_data$value)
      ) %>%
        filter(hour(DateTime) == 0) %>%     # Keep only midnight readings
        rename(!!element := Value)          # Rename column for clarity
      
      data_list[[element]] <- df
    } else {
      cat("⚠️ No 'values' field found for element:", element, "\n")
    }
  } else {
    cat("❌ API request failed for element:", element, "\n")
  }
}

# ------------------------------------------------------------------------------
# === CREATE MASTER TIME SEQUENCE + JOIN DATAFRAMES ===
# ------------------------------------------------------------------------------

# Create a daily sequence of midnight timestamps over the date range
midnight_sequence <- seq(
  from = as.POSIXct(paste0(start_dateapi, " 00:00:00"), tz = "UTC"),
  to   = as.POSIXct(paste0(end_dateapi, " 00:00:00"), tz = "UTC"),
  by   = "1 day"
)

# Join each variable's data to the master time sequence
data_list <- lapply(data_list, function(df) {
  tibble(DateTime = midnight_sequence) %>%
    left_join(df, by = "DateTime") %>%
    arrange(DateTime)
})

# Reduce all element data frames into a single tidy table
if (length(data_list) > 0) {
  final_data <- reduce(data_list, left_join, by = "DateTime")
} else {
  final_data <- tibble(DateTime = midnight_sequence)
  warning("⚠️ No data returned for any element.")
}

# ------------------------------------------------------------------------------
# === EXPORT RESULTS ===
# ------------------------------------------------------------------------------

# File path for output CSV
file_path <- #"your/path/here"

# Write the full dataset to disk
write.csv(final_data, file = file_path, row.names = FALSE)
cat("✅ File saved to:", file_path, "\n")

