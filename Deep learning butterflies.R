#butterfly citizen science data for deep learning
usethis::use_git()
library(rinat)#for retrieving records
library(sf)

#use a script made by Dr Sanderson that makes a download images func
source("download_images.R")
#get simple GB map
gb_ll <- readRDS("gb_simple.RDS")

#lets get some brimstone butterfly images from inat (iNaturalist)
#select only research quality, within GB
brimstone_recs <-  get_inat_obs(taxon_name  = "Gonepteryx rhamni",
                                bounds = gb_ll,
                                quality = "research",
                                # month=6,   # Month can be set.
                                # year=2018, # Year can be set.
                                maxresults = 600)
#download the images
download_images(spp_recs = brimstone_recs, spp_folder = "brimstone")
#do the same for two more butterfly sp
# Holly blue; Celastrina argiolus
hollyblue_recs <-  get_inat_obs(taxon_name  = "Celastrina argiolus",
                                bounds = gb_ll,
                                quality = "research",
                                maxresults = 600)


# Orange tip; Anthocharis cardamines
orangetip_recs <-  get_inat_obs(taxon_name  = "Anthocharis cardamines",
                                bounds = gb_ll,
                                quality = "research",
                                maxresults = 600)
download_images(spp_recs = hollyblue_recs, spp_folder = "hollyblue")
download_images(spp_recs = orangetip_recs, spp_folder = "orangetip")

#we want to separate the last 100 photos from each sp into folders for testing the model later
image_files_path <- "images" # path to folder with photos
# list of spp to model; these names must match folder names
spp_list <- dir(image_files_path) # Automatically pick up names
# number of spp classes (i.e. 3 species in this example)
output_n <- length(spp_list)
# Create test, and species sub-folders
for(folder in 1:output_n){
  dir.create(paste("test", spp_list[folder], sep="/"), recursive=TRUE)}
# Now copy over spp_501.jpg to spp_600.jpg using two loops, deleting the photos
# from the original images folder after the copy
for(folder in 1:output_n){
  for(image in 501:600){
    src_image  <- paste0("images/", spp_list[folder], "/spp_", image, ".jpg")
    dest_image <- paste0("test/"  , spp_list[folder], "/spp_", image, ".jpg")
    file.copy(src_image, dest_image)
    file.remove(src_image)}}
