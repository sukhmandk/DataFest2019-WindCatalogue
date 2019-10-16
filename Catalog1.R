library(dplyr)
library(tesseract)
library(magick)
library(tidyr)
library(stringi)

#read the image and use tesseract
image<-image_read("Catalog1.jpg")
eng <- tesseract("eng")
#without any cropping or filter
text<-ocr_data(image)
#separate the bbox
text<-separate(text,bbox,c("xstart","ystart","xend","yend"))

# crop the image in to left col and right col
left_case_xend<-as.numeric(min(pull(text[which(text$word=="Case"),5])))+24
right_no_ystart<-as.numeric(min(pull(text[which(text$word=="N0."),4])))-14
#right image after cropping
right_image<-image_crop(image,geometry_area(0,0,left_case_xend,right_no_ystart))
#left image after cropping
left_image<-image_chop(image,geometry_area(left_case_xend,0,left_case_xend,0))
#text from the left image
left_text1<-ocr_data(left_image)
left_text1<-separate(left_text1,bbox,c("xstart","ystart","xend","yend"))
#get rid of the top and left edge of the left image

left_no_xstart<-as.numeric(pull(left_text1[which(left_text1$word=="No."),3]))-10
left_no_ystart<-as.numeric(pull(left_text1[which(left_text1$word=="No."),4]))-10
left_image<-image_crop(left_image,geometry_point(left_no_xstart,left_no_ystart))
################################################################################

#tesseract read the cropped left and right side of the page, separate the bbox, and filter out "."
#then make the 4 columns - xstart,ystart,xend,yend - numeric
left_text<-ocr_data(left_image)
left_text<-separate(left_text,bbox,c("xstart","ystart","xend","yend"))
filtered_left =left_text[which(left_text$word!="."& left_text$word!=".."),]
filtered_left[3:6]<-sapply(filtered_left[3:6],as.numeric)

right_text<-ocr_data(right_image)
right_text<-separate(right_text,bbox,c("xstart","ystart","xend","yend"))
filtered_right = right_text[which(right_text$word!="."& right_text$word!=".."),]
filtered_right[3:6]<-sapply(filtered_right[3:6],as.numeric)
################################################################################
###DESCRIPTION EXTRACTION STARTS
# find the xstart of No./N0. and xstart of bottle
# to filter the data outside these x coordinates to get the description
left_no_xstart = pull(filtered_left[filtered_left$word=="No.",3]) - 30
left_bottle_xstart = pull(filtered_left[filtered_left$word=="Bottle",3])

right_no_xstart = pull(filtered_right[filtered_right$word=="N0.",3]) -30
right_bottle_xstart = pull(filtered_right[filtered_right$word=="Bottle",3])
################################################################################

#extract wine description from text
filtered_name_left = filtered_left[which(filtered_left$xstart >= left_no_xstart & filtered_left$xend <= left_bottle_xstart),]

filtered_name_right = filtered_right[which(filtered_right$xstart >= right_no_xstart & filtered_right$xend <= right_bottle_xstart),]

################################################################################
# Find the indices from which the next line starts on the page
# Has some errors with dividing the lines properly
# fixed in the last but of description extraction
array_left = c(1)
length_filtered_name_left = length(filtered_name_left$word) - 1
for(i in 1:length_filtered_name_left)
{
  if((filtered_name_left$ystart[i+1] - filtered_name_left$ystart[i]) > 30)
    array_left = c(array_left,i+1)
}

array_right = c(1)
length_filtered_name_right  = length(filtered_name_right$word) - 1
for(i in 1:length_filtered_name_right)
{
  if( (filtered_name_right$ystart[i+1] - filtered_name_right$ystart[i]) > 30)
    array_right = c(array_right,i+1)
}
################################################################################

#get the description for each wine and store it in a array
#still some errors, which fixed in the last but of description extraction
description_left = c()
length_array_left = length(array_left) - 1
for (i in 1:length_array_left){
  start = array_left[i]
  secondline = array_left[i+1]
  line = filtered_name_left$word[start]
  while (start < secondline-1)
  {
    start = start + 1
    line = paste(line,filtered_name_left$word[start]) 
  }
  description_left[i] = line
} 
description_left

description_right = c()
length_array_right = length(array_right) - 1
for (i in 1:length_array_right){
  start = array_right[i]
  secondline = array_right[i+1]
  line = filtered_name_right$word[start]
  while (start < secondline-1)
  {
    start = start + 1
    line = paste(line,filtered_name_right$word[start]) 
  }
  description_right[i] = line
}  
################################################################################


# check the first item of each element of the description, 
# if it is not a number, vec will have a true value there
# use this logical array to put together description from two lines in one line
# errors from above are fixed here
arrayL = c()
start_description_left = sapply(description_left,substr,1,1,USE.NAMES = F)
vecL = is.na(as.numeric(start_description_left))
lenL = length(start_description_left)
for (i in 2:lenL) {
  if (vecL[i] == TRUE) {
    description_left[i-1] = paste(description_left[i-1],description_left[i])
    arrayL = c(arrayL, i )
  }
}
arrayL = c(arrayL,1)
description_left = description_left[-arrayL]

#right side
arrayR = c()
start_description_right = sapply(description_right,substr,1,1,USE.NAMES = F)
vecR = is.na(as.numeric(start_description_right))
lenR = length(start_description_right)

for (i in 2:lenR) {
  if (vecR[i] == TRUE) {
    description_right[i-1] = paste(description_right[i-1],description_right[i])
    arrayR = c(arrayR, i )
  }
}
arrayR = c(arrayR,1)
description_right = description_right[-arrayR]
description_right[5] = paste(description_right[5],description_right[6])
arrayR = c(6)
description_right = description_right[-arrayR]
################################################################################
description_left
description_right
###DESCRIPTION EXTRACTION ENDS

################################################################################

# getting the bottle price and case price of the left and right side of the page separately
left_bottle_xstart = as.numeric(pull(left_text[left_text$word=="Bottle",3]))-10
price_left<-image_crop(left_image,geometry_point(left_bottle_xstart,0))
price_left<-ocr_data(price_left)

len_pl = length(price_left$word)
bottleprice_left = c()
caseprice_left = c()
for(i in 3:len_pl){
  if (i%%2 == 0){
    caseprice_left = c(caseprice_left,pull(price_left[i,1]))
  }
  else{
    
    bottleprice_left = c(bottleprice_left,pull(price_left[i,1]))
  }
}


#right
right_bottle_xstart = as.numeric(pull(right_text[right_text$word=="Bottle",3]))-10
price_right<-image_crop(right_image,geometry_point(right_bottle_xstart,0))
price_right1<-ocr_data(price_right)
price_right1<-separate(price_right1,bbox,c("xstart","ystart","xend","yend"))
right_case_xend = as.numeric(pull(price_right1[price_right1$word=="Case",5])) +10
price_right<-image_chop(price_right,geometry_area(200,0,right_case_xend,0))
price_right<-ocr_data(price_right)

len_pr = length(price_right$word)
bottleprice_right = c()
caseprice_right = c()
for(i in 3:len_pr){
  if (i%%2 == 0){
    caseprice_right = c(caseprice_right,pull(price_right[i,1]))
  }
  else{

    bottleprice_right = c(bottleprice_right,pull(price_right[i,1]))
  }
}
# put the description, bottle price, and case price of the whole page in one list
# the list wine_data has 3 components - name_description, bottle price, and case price
# wine_dataset is the data frame version of the list wine_data
description = c(description_left,description_right)
bottle_price = c(bottleprice_left,bottleprice_right)
case_price = c(caseprice_left,caseprice_right)
wine_data = list(name_description = description, bottle_price = bottle_price, case_price = case_price)
wine_dataset = as.data.frame(wine_data)
