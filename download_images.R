my_packages <- c("RCurl", "stringr", "imager")   # Specify extra packages
not_installed <- my_packages[!(my_packages %in% installed.packages()[ , "Package"])]    # Extract not installed packages
if(length(not_installed)) install.packages(not_installed)       
library(imager)
library(stringr)
library(RCurl)

# Function to download images and save them to files
download_images <- function(spp_recs = NULL, image_folder = "images", spp_folder = NULL) {
  dir.create(image_folder, showWarnings=FALSE)
  if(is.null(spp_recs) | is.null(spp_folder)){
    print("Please set spp_recs and spp_folder")
    return()
  }  
  dir.create(paste0(image_folder, "/", spp_folder))
  for(image in 1:nrow(spp_recs)){
    print(paste("Processing image number...", image))
    spp_url <- spp_recs$image_url[image]
    spp_q <- str_locate(spp_url, "\\?")
    spp_clean <- str_sub(spp_url, 1, spp_q[1]-1)
    if(!is.na(spp_clean)){
      download.file(spp_clean,
                    destfile=paste0(image_folder, "/", spp_folder, "/spp_", image, ".jpg"),
                    method ="libcurl",
                    mode = "wb")
    }
  }
}
