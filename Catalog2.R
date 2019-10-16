library(tesseract)
library(magick)
library(tidyr)
library(stringi)
library(dplyr)

#image preprossessing 
input <- image_read("~/Desktop/DataFest/catalog2.jpg")

text = ocr_data(input)
text = separate(text, bbox, into = c("xstart","ystart","xend","yend"))
text[3:6] = sapply(text[3:6],as.numeric)

#rotate the image:
bottle_y = text[which(text$word == "Bottle"), 4]
case_y = text[which(text$word == "Case"), 4]
bottle_x = text[which(text$word == "Bottle"), 3]
bottle_x_end = text[which(text$word == "Bottle"), 5] + 300
case_x = text[which(text$word == "Case"), 3]

if(abs(bottle_y - case_y) >= 10){
  tangent = (case_y - bottle_y) / (case_x - bottle_x)
  angle = atan(tangent)
  angle = angle * 180/pi
  angle
}
image = image_rotate(input,pull(-angle))
image

no_x = text[which(text$word == "No."), 3]- 50
no_y = text[which(text$word == "No."), 4]+ 70
#input_text = ocr_data(image)
image_cropped = image_crop(image,geometry_point(no_x,no_y))
image_cropped

text_left = ocr_data(image_cropped)

filtered = text_left[which(text_left$word != "." & text_left$word != ".." ),]
filtered1 = separate(filtered, bbox, into = c("xstart","ystart","xend","yend"))
text_left = separate(text_left,bbox,into = c("xstart","ystart","xend","yend"))
text_left[3:6] = sapply(text_left[3:6],as.numeric)
filtered1[3:6]<-sapply(filtered1[3:6],as.numeric)

#extract wine description from text
#filtered_name = filtered1[which(filtered1$xstart >= 103 & filtered1$xend <= 1269),]
filtered_name = filtered1[which(filtered1$xend <= as.numeric(bottle_x)-450),]

#get the indexes of the starting word of each wine
arr=c(1)
for(i in 1:(length(filtered_name$word)-1))
{
  if((filtered_name$ystart[i+1] - filtered_name$ystart[i]) > 40)
    arr = c(arr,i+1)
}
#get the description for each wine and store it in a array
description = c()
length_arr = length(arr) - 1
for (i in 1:length_arr){
  start = arr[i]
  secondline = arr[i+1]
  line = filtered_name$word[start]
  line
  while (start < secondline-1)
  {
    start = start + 1
    line = paste(line,filtered_name$word[start]) 
  }
  description[i] = line
}  
description

arrayL = c()
start_description_left = sapply(description,substr,1,1,USE.NAMES = F)
vecL = is.na(as.numeric(start_description_left))
description2 = description[!vecL]
description2

array=c()
price_bottle = text_left[which(text_left$xstart > 2720 & text_left$xend < 3040),]
for(i in 2:length(price_bottle$word)-1){
  if (abs(price_bottle$ystart[i]-price_bottle$ystart[i+1])<5){
    price_bottle$word[i]<-paste(price_bottle$word[i],price_bottle$word[i+1],sep = "")
    array=c(array,i+1)
  }
}
price_bottle=price_bottle[-array,]
price_case = text_left[which(text_left$xstart > 3000 & text_left$xend < 3400),]

wine_data = list(name_description = description2, bottle_price = price_bottle$word, case_price = price_case$word)
wine_dataset = as.data.frame(wine_data)
