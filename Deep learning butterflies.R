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

###training the model

#setup
#load keras
library(keras)
#scale down image sizes
img_width <- 150
img_height <- 150
target_size <- c(img_width, img_height)#set target size

# Full-colour Red Green Blue = 3 channels
channels <- 3
# Rescale colour hue from 255 to between zero and 1
train_data_gen = image_data_generator(
  rescale = 1/255,
  validation_split = 0.2)
#
#load in training and validation images
#seed of 42 is a random number generator - enures reproducibility
train_image_array_gen <- flow_images_from_directory(image_files_path, 
                                                    train_data_gen,
                                                    target_size = target_size,
                                                    class_mode = "categorical",
                                                    classes = spp_list,
                                                    subset = "training",
                                                    seed = 42)

valid_image_array_gen <- flow_images_from_directory(image_files_path, 
                                                    train_data_gen,
                                                    target_size = target_size,
                                                    class_mode = "categorical",
                                                    classes = spp_list,
                                                    subset = "validation",
                                                    seed = 42)
# Check that things seem to have been read in OK
cat("Number of images per class:")
## Number of images per class:
table(factor(train_image_array_gen$classes))
## 
##   0   1   2 
## 400 400 400
cat("Class labels vs index mapping")
## Class labels vs index mapping
train_image_array_gen$class_indices
#shows 0, 1, 2

#look at one image
plot(as.raster(train_image_array_gen[[1]][[1]][8,,,]))

#define parameters for the model
# number of training samples
train_samples <- train_image_array_gen$n
# number of validation samples
valid_samples <- valid_image_array_gen$n
# define batch size and number of epochs
batch_size <- 32 # Useful to define explicitly as we'll use it later
epochs <- 10 # How long to keep training going for

#define structure of CNN
# initialise model
model <- keras_model_sequential()

# add layers
model %>%
  layer_conv_2d(filter = 32, kernel_size = c(3,3), input_shape = c(img_width, img_height, channels), activation = "relu") %>%
  
  # Second hidden layer
  layer_conv_2d(filter = 16, kernel_size = c(3,3), activation = "relu") %>%
  
  # Use max pooling
  layer_max_pooling_2d(pool_size = c(2,2)) %>%
  layer_dropout(0.25) %>%
  
  # Flatten max filtered output into feature vector 
  # and feed into dense layer
  layer_flatten() %>%
  layer_dense(100, activation = "relu") %>%
  layer_dropout(0.5) %>%
  
  # Outputs from dense layer are projected onto output layer
  layer_dense(output_n, activation = "softmax") 

#check the structure
print(model) #looks good!

# Compile the model
model %>% compile(
  loss = "categorical_crossentropy",
  optimizer = optimizer_rmsprop(lr = 0.0001, decay = 1e-6),
  metrics = "accuracy")
###

# Train the model with fit_generator
history <- model %>% fit_generator(
  # training data
  train_image_array_gen,
  
  # epochs
  steps_per_epoch = as.integer(train_samples / batch_size), 
  epochs = epochs, 
  
  # validation data
  validation_data = valid_image_array_gen,
  validation_steps = as.integer(valid_samples / batch_size),
  
  # print progress
  verbose = 2)

#assess results
plot(history)
#plots suggest there is overtraining after about epoch 7/8, as the validation accuracy gets stuck around 55% despite training accuracy up to 75%
#however, is a small dataset, so this isn't toooo bad

#save model for future uses

# The imager package also has a save.image function, so unload it to
# avoid any confusion
detach("package:imager", unload = TRUE)

# The save.image function saves your whole R workspace
save.image("animals.RData")

# Saves only the model, with all its weights and configuration, in a special
# hdf5 file on its own. You can use load_model_hdf5 to get it back.
#model %>% save_model_hdf5("animals_simple.hdf5")

###

#test the model with test images
path_test <- "test"

test_data_gen <- image_data_generator(rescale = 1/255)

test_image_array_gen <- flow_images_from_directory(path_test,
                                                   test_data_gen,
                                                   target_size = target_size,
                                                   class_mode = "categorical",
                                                   classes = spp_list,
                                                   shuffle = FALSE, # do not shuffle the images around
                                                   batch_size = 1,  # Only 1 image at a time
                                                   seed = 123)

#runs through all the images
model %>% evaluate_generator(test_image_array_gen, steps = test_image_array_gen$n)

#gives accuracy of 52%, only slightly lower than validation dataset