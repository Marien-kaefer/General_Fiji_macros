/*
This macro processes all images within a folder, filtered by an adjustible string, e.g. use for file extension. 
The macro requests an output location in which intermediary and the results files are saved automatically. 
The input requires two channel images, one for DNA and one for the signal of interest. 

												- Written by Marie Held [mheldb@liverpool.ac.uk] 
												  Liverpool CCI (https://cci.liverpool.ac.uk/)
________________________________________________________________________________________________________________________

BSD 2-Clause License

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
*
*/

// Prompting user for input directory, output directory, file suffixes, classifier file, and other parameters
#@ File (label = "Input directory", style = "directory") input
#@ String (label = "File suffix filter", value = ".czi", persist=false) input_suffix
#@ File (label = "Output directory", style = "directory") output
#@ Double(label = "Antisense channel number: ", value=1, min=0, max=1, style="spinner") antisense_channel
#@ Double(label = "DNA channel number: ", value=2, min=0, max=1, style="spinner") DNA_channel
#@ Double(label = "Rolling ball radius: ", value=25, min=0, max=1, style="spinner") rolling_ball_size
#@ String (label = "Bacteria segmentation algorithm: ",choices={"IJ_IsoData","Default", "Huang","Intermodes","IsoData","Li","MaxEntropy","Mean","MinError","Minimum","Moments","Otsu","Percentile","RenyiEntropy","Shanbhag","Triangle","Yen"}, style="listBox") bacteria_threshold_algorithm
#@ Double(label = "Bacteria maximum size: ", value=300, min=0, max=1, style="spinner") maximum_bacteria_size
#@ String (label = "Bodo segmentation algorithm: ",choices={"Mean","Default", "Huang","IJ_IsoData","Intermodes","IsoData","Li","MaxEntropy","MinError","Minimum","Moments","Otsu","Percentile","RenyiEntropy","Shanbhag","Triangle","Yen"}, style="listBox") bodo_threshold_algorithm
#@ Double(label = "Bodo minimum size: ", value=1000, min=0, max=1, style="spinner") minimum_bodo_size

// Main function to process the folder

setBatchMode("hide");
processFolder(input);
waitForUser("Done! Check out the results. \nAdjust parameters in initial user dialog if segmentation results are not satisfactory."); 
beep();
setBatchMode("show");

// Function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], input_suffix))
			process_file(list[i]);
	}
}

// Function to process individual files
function process_file(file){
	input_file = input + File.separator + file; 
	run("Bio-Formats Windowless Importer", "open=[input_file]");
	image_title = getTitle();
	image_ID = getImageID();
	File.setDefaultDir(getDirectory("image"));
	
	//preprocessing of DAPI channel
	selectImage(image_ID);
	run("Duplicate...", "duplicate channels=" + DNA_channel);
	run("Subtract Background...", "rolling=" + rolling_ball_size);	
	
	run("Duplicate...", " ");
	
	// Identify bacteria 
	setAutoThreshold(bacteria_threshold_algorithm + " dark");	
	run("Convert to Mask");
	run("Watershed");	//split toughing objects
	run("Analyze Particles...", "size=0-"+ maximum_bacteria_size + " pixel exclude add"); 
	saveAs("TIFF", output + File.separator + image_title + "-bacteria-mask.tif"); 
	roiManager("Save", output + File.separator + image_title + "-bacteria-ROIs.zip");
	
	//Identify cells
	selectImage(image_ID);
	run("Duplicate...", "duplicate channels=" + antisense_channel);
	setAutoThreshold(bodo_threshold_algorithm + " dark"); 
	//run("Threshold...");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Analyze Particles...", "size=" + minimum_bodo_size + "-Infinity pixel exclude add");
	saveAs("TIFF", output + File.separator + image_title + "-bodo-mask.tif"); 
	
	// ROI arithmetics to generate cell ROI with bacteria excluded
	roiManager("Deselect");
	roiManager("XOR");
	roiManager("Add");
	ROI_count = roiManager("count");
	roiManager("Select", ROI_count - 1);
	roiManager("Rename", "cell-minus-bacteria");
	roiManager("Select", ROI_count - 2);
	roiManager("Rename", "cell");
	roiManager("Deselect");
	roiManager("Save", output + File.separator + image_title + "-bacteria-and-bodo-ROIs.zip");
	
	//Set measurements
	run("Set Measurements...", "area mean modal integrated median display redirect=None decimal=3"); 	//change as required
	selectImage(image_ID); 
	setSlice(antisense_channel); 
	
	//Measure intensities
	roiManager("multi-measure");
	
	//Save intensities
	saveAs("Results", output + File.separator + image_title + "-Results-bacteria-and-cell-red-intensities.csv");
	
	// Reset ROI manager and close images
	roiManager("reset");
	run("Select None");
	close("*"); 
}