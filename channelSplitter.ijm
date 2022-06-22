// Macro to split a multichannel image into individual tif files


//MIT License
//Copyright (c) [2021] [Marie Held {mheldb@liverpool.ac.uk}, Image Analyst Liverpool CCI (https://cci.liverpool.ac.uk/)]
//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



//get input and output directories from user
#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = "", persist=false) suffix
#@ String(label = "Adjust Brightness/Contrast?", choices = {"no", "yes"}, style = "radioButtonHorizontal", persist=false)  adjust_brightness_contrast
#@ String(label = "Convert to 8 bit?", choices = {"no", "yes"}, style = "radioButtonHorizontal", persist=false)  convert_to_8bit



setBatchMode(true);	// run routine without showing image windows, i.e. quicker

processFolder(input);
print("Done!"); 
beep();

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			splitChannels(list[i]);
	}
}

// split channels for an opened function 
function splitChannels(file){
	open(input + File.separator + file);
	print("Processing: " + file); 
	getDimensions(width, height, channels, slices, frames);
	numberOfChannels = channels;  // query number of slices in stack
	if (numberOfChannels == 1){
		print("This file contains only one channel.");
		}	
	else if (numberOfChannels > 1){
		run("Split Channels");
		saveChannels(numberOfChannels);	// save channel for as many times as there were slices in the original stack	
		}
	numberOfChannels = 0; 
	}

// save files in specified output folder and close saved files
function saveChannels(numberOfChannels){
	for (i = 0; i < numberOfChannels; i++){
		fileName = getTitle();
		if (adjust_brightness_contrast == "yes"){
			run("Z Project...", "projection=[Max Intensity]");
			MIP_image = getTitle(); 
			getMinAndMax(min, max);
			selectWindow(MIP_image); 
			close();
			setMinAndMax(min, max);				
		}
		if (convert_to_8bit == "yes"){
   			run("8-bit");
		}
		saveAs("Tiff",output + File.separator + fileName);
		print("Saving file: " + fileName);
		close();
	}
}
