library(dplyr)
library(tesseract)
library(magick)
library(tidyr)
library(stringi)

#read the image and use tesseract
image<-image_read("Catalog4.jpg")

eng <- tesseract("eng")
#without any cropping or filter
text<-ocr_data(image)
#separate the bbox
text<-separate(text,bbox,c("xstart","ystart","xend","yend"))
no_y = as.numeric(pull(text[which(text$word == "N"), 4]))
case_y = min(as.numeric(pull(text[which(text$word == "Case"), 4])))
no_x = as.numeric(text[which(text$word == "N"), 3])
case_x = min(as.numeric(pull(text[which(text$word == "Case"), 3])))

if(abs(no_y - case_y) >= 10){
  tangent = (case_y - no_y) / (case_x - no_x)
  angle = atan(tangent)
  angle = angle * 180/pi
}
image2 = image_rotate(image,abs(angle))

#get rid of the top and left edge of the left image
no_xstart<-as.numeric(pull(text[which(text$word=="N"),3]))-10
no_ystart<-as.numeric(pull(text[which(text$word=="N"),4]))-25
new_image1<-image_crop(image2,geometry_point(no_xstart,no_ystart))
new_text1<-ocr_data(new_image1)
new_text1<-separate(new_text1,bbox,c("xstart","ystart","xend","yend"))
case_xend<-min(as.numeric(pull(new_text1[which(new_text1$word=="Case"),5]))) + 100
new_image<-image_chop(new_image1,geometry_area(1000,0,case_xend,0))

new_text<-ocr_data(new_image)

new_text<-separate(new_text,bbox,c("xstart","ystart","xend","yend"))
filtered_text = new_text[which(new_text$word!="."& new_text$word!=".."),]
filtered_text[3:6]<-sapply(filtered_text[3:6],as.numeric)



no_xstart = pull(filtered_text[filtered_text$word=="No.",3]) - 35
case_xstart = min(as.numeric(pull(filtered_text[filtered_text$word=="Case",3])))

filtered_name = filtered_text[which(filtered_text$xstart >= no_xstart & filtered_text$xend <= case_xstart),]

array = c(1)
length_filtered_name = length(filtered_name$word) - 1
for(i in 1:length_filtered_name)
{
  if((filtered_name$ystart[i+1] - filtered_name$ystart[i]) > 30)
    array = c(array,i+1)
}
#get the description for each wine and store it in a array
#still some errors, which fixed in the last but of description extraction
description = c()
length_array=t = length(array) - 1
for (i in 1:length_array){
  start = array[i]
  secondline = array[i+1]
  line = filtered_name$word[start]
  while (start < secondline-1)
  {
    start = start + 1
    line = paste(line,filtered_name$word[start]) 
  }
  description[i] = line
} 

# check the first item of each element of the description, 
# if it is not a number, vec will have a true value there
# use this logical array to put together description from two lines in one line
# errors from above are fixed here
arrayL = c()
start_description = sapply(description,substr,1,1,USE.NAMES = F)
lenL = length(start_description)
for (i in 2:lenL) {
  if (start_description[i] != "F") {
    if (is.na(as.numeric(start_description[i])) == TRUE){
      arrayL = c(arrayL, i )
    }
  }
}
arrayL = c(arrayL,1,40)
description = description[-arrayL]
description

# getting the bottle price and case price of the left and right side of the page separately
case_xstart = min(as.numeric(pull(filtered_text[filtered_text$word=="Case",3])))-40
price<-image_crop(new_image,geometry_point(case_xstart,0))
price<-ocr_data(price)

array1 = c()
price1=!is.na(as.numeric(price$word))
lenR = length(price1)
for (i in 1:lenR) {
  if (price1[i] == FALSE) {
    array1 = c(array1, i )
  }
}
price = price$word[-array1]
wine_data = list(name_description = description, case_price = price)
wine_dataset = as.data.frame(wine_data)
wine_dataset