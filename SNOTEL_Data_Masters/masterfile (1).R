#This script runs all others needed to produce a avalanche risk assessment, 
#and gives instructions for in between steps. Alternatively, comment out step 7a and use step 7b 
#to run code to test the three water infiltration through snow equations

# Suppress all warnings and errors globally
options(warn = -1)

library(reticulate)

#__________________________________________________________________________________#
#Only make edits in this section, make sure to change for correct station variables#
#__________________________________________________________________________________#

#Step 1: site variables for SNOWPACK input files

site = "Box Canyon"
snoteldata = "Box_Canyon_(836)"
start_date = "2000-10-01T00:00:00"
end_date = "2024-09-31T00:00:00"
alt = "1947"
lat = "46.14"
long = "-114.51"
epsg = "2256"

#Site variables for SNOTEL data download

elements <- c('WTEQ', 'SNWD', 'PREC', 'TAVG', 'RHUM', 'WSPDV', 'SWINV')
start_dateapi = "2000-10-01"
end_dateapi = "2025-02-03" 
station_triplet = "836:MT:SNTL" #836 for twin lakes

#running code with precip or snow height as variable in SNOWPACK?
snow_height = TRUE

#which water transport model do you want to run (BUCKET,NIED,RICHARDS)
transport = "BUCKET"

#soil water transport (bucket for bucket and nied snow models and richards for richards snow)
soiltrans = "BUCKET"

SNO

#code sources:
datadownload_path = paste0(base_dir, "snotel_api.R")
quality_control_path = paste0(base_dir, "quality_control.R")
inputfile_sd_path = paste0(base_dir, "inputfiles.R")
inputfile_precip_path = paste0(base_dir, "inputfiles_precip.R")
inicreation_path = paste0(base_dir, "ini_creation.R")
run_snowpack_path = paste0(base_dir, "run_snowpack.R")
cleaning_path = paste0(base_dir, "clean_profiles.R")
graph_path = paste0(base_dir, "graph.R")

#Remember to set up new folder in SNOWPACK inputs folder if running a new site!

#--------------------------------------------------------------------------------------------------------------------------------#


#Step 2: Download data from report generator with variables:
cat("Downloading SNOTEL data")
source(datadownload_path)


#Step 3: choose precip or snow height, take raw data, perform QC, and create SNOWPACK input files:

if (snow_height == TRUE) {
  
  cat("Creating SNOWPACK input file with Snow Height as variable")
  source(inputfile_sd_path)
  
} else {
  cat("Creating SNOWPACK input file with Precipitation as variable")
  source(inputfile_precip_path)
}
  
#Step 5: create .ini file for site for SNOWPACK use
cat("creating .ini file for site")
source(inicreation_path)

#Step 6: Run SNOWPACK
cat("Running SNOWPACK")
source(run_snowpack_path)

#step 7: run clean profiles to get outputs in a usable format
cat("cleaning SNOWPACK outputs")
source(cleaning_path)

#step 8: run "graph" script to create outputs for report
cat("Analysing SNOWPACK outputs")
source(graph_path)

#step 9: create avalanche forecast risk map and printed pdf of results
#cat("creating avalanche forcast")
#py_run_file("C:/Users/hcl-o/OneDrive - Montana State University/Desktop/RA Work/SNOWPACK inputs/master programs/avalanche_forcast.py")
