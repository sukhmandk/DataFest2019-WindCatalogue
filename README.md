# UCD DataFest
## TeamBravo
### members

Sukhmandeep Kaur	sdkkaur@ucdavis.edu	  Applied Mathematics		

Zack Liu				  zheliu@ucdavis.edu		Statistics	

Xingwei Ji			  xwji@ucdavis.edu		  Computer Science		

## Purpose
Extracting text from wine catalog with tesseract and store the data into a data frame in a efficient way.
Long term goal is to design a framework that can enable businesses to make data-driven trend analysis & decisions
## Goal
Our goal during this project was to learn basics of Optical Character Recognition. We are working on being able to read the images, extract the data using tesseract, and find an optimized way of storing the data. We are programming in R and we hope to be able to use the coordinates of certain words to be able to divide our data, and store little chunks as structs such that each element of the struct corresponds to particular wine. We incorporated tesseract in R & ML to optimize the optical character recognition and data structures for record-keeping.

## Challenges
### Picture noise reduction
Tesseract will detect unnecessary and odd symbols if we don't preprocess the image. Thus, we reduced the noise by croping and rotating the image. As a result, we got rid of most noises and extracted accurate text from the picture.

### Grouping words that are in the same line
Tesseract doesn't extract text line by line. It detects it words by words. So we have to figure out a way to group those words that are in the same line. We tackled this by deciding if the differences of y coordinates of words are greater than 45 pixels. If so, we will seperate the words to next line. We implement this by writing a for loop that iterates through each word and deciding which words belong to next line.

### Seperating prices from texts
We isolated prices of wines by x coordinates of a word called "bottle" or "case". We found a pattern that prices are always under the word "bottle" or "case". So if we can find the coordinates of those two words, we then can find where prices are.

### Rotating tilted images automatically
Some images are tilted. It will make Tesseract harder to extract texts. We use basic geometry to solve this problem. We find a pattern that words "case" and "bottle" are always in the same line. With this in mind, we detect the coordinates of those two words and check if their y coordinates are close. If not, we will use geometric method to calculate the angle and then, we rotate the image using image_rotate from magick.

## Unsolved 
* OCR fails to recognize some texts accurately.
* Our approach only applies to certain picture with specific pattern as we worked with three samples only due to time constraint.
* We detect the boundary by key words. It doesn't work if there are no key words in the image.
* Cropping images is extremely limited with our approach. It has to find those key words in order to function properly.
* We don't have a sound setup yet, but with more OCR understanding, and using ML with Tessearct can help further this exploratory setup.
