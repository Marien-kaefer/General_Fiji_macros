/*

												- Written by Marie Held [mheldb@liverpool.ac.uk] April 2024
												  Liverpool CCI (https://cci.liverpool.ac.uk/)
________________________________________________________________________________________________________________________

BSD 2-Clause License

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
*
*/

run("Fresh Start");

#@ File (label = "Input directory", style = "directory") input
#@ String (label = "File suffix", value = ".czi", persist=false) input_suffix
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix of segmentation files", value = "_LK_segmentation", persist=false) output_suffix
#@ File(label = "Classifier file: ", style = "file") classifier_file
#@ Double(label = "Minimum cell size: ", value=25, min=0, max=1, style="spinner") minimum_cell_size
#@ Double(label = "Maximum cell size: ", value=200, min=0, max=1, style="spinner") maximum_cell_size
#@ String(label = "Create individual cropped cell files?",choices={"Yes", "No"}, style="radioButtonHorizontal") cropped_cell_saving_choice

start = getTime(); 
print(TimeStamp() + ": The analysis is running");
print("Input root directory: " + input); 
input_root_path_length = lengthOf(input);

run("Set Measurements...", "area mean standard modal min centroid perimeter bounding fit shape feret's integrated median skewness kurtosis display decimal=3");
input_sub_directory = "";

processFolder(input, output, input_root_path_length); 

//let user know the process has finished and how long it took
stop = getTime(); 
duration = stop - start;
duration_String = duration_conversion(duration);
print(TimeStamp() + ": Processing complete. The analysis took " + duration_conversion(duration) + ".");
beep();

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input, output, input_root_path_length) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i])){ //also process files in directories within the input directory
			processFolder(input + File.separator + list[i], output, input_root_path_length);
			print("List item: " + list[i]);
			File.makeDirectory(output + list[i]);
			print("Input full path directory:" + input + File.separator + list[i]);
			input_sub_directory = substring(input + File.separator + list[i], input_root_path_length); 
			print("Input sub directory:" + input_sub_directory); 
			output = output + input_sub_directory; 
			print("Output folder: " + output); 
		}
		if(endsWith(list[i], input_suffix)){
			output = output + input_sub_directory; 
			file_processing(input, list, classifier_file, output, output_suffix, minimum_cell_size, maximum_cell_size, input_sub_directory);	
		}
	}
}

function processDirectory(inputDir, outputDir, level) {
}


function file_processing(input, list, classifier_file, output, output_suffix, minimum_cell_size, maximum_cell_size, input_sub_directory){

	if (cropped_cell_saving_choice == "Yes"){
		single_cell_image_output_directory = output + File.separator + "single_cell_files"; 
		File.makeDirectory(single_cell_image_output_directory);
	}
	
	inputFile = input + File.separator + list[i]; 
	File.makeDirectory(output);
	print("Processing file (" + (i+1) + "/" + list.length + ") : " + list[i]); 
	run("Bio-Formats Windowless Importer", "open=[inputFile]");
	original_title = getTitle(); 
	file_name_without_extension = File.nameWithoutExtension; 
	run("Duplicate...", "duplicate channels=1");
	resetMinAndMax; 
	fluorescence_title = getTitle(); 
	//selectWindow(original_title); 

	selectWindow(fluorescence_title); 
	run("Segment Image With Labkit", "segmenter_file=[" + classifier_file + "] use_gpu=false");
	segmentation_title = getTitle(); 

	//print("Seg title: " + segmentation_title); 
	selectWindow(segmentation_title); 
	//waitForUser; 

	//run("Brightness/Contrast...");
	
	//save segmentation file
	//saveAs("Tiff", output + File.separator + file_name_without_extension + output_suffix);
	saveAs("Tiff", output + File.separator + file_name_without_extension + output_suffix);
	rename(segmentation_title); 
	resetMinAndMax; 
	selectWindow(fluorescence_title); 
	run("Median...", "radius=2");
	run("Find Maxima...", "prominence=500 output=[Segmented Particles]");
	segmented_particles_mask =  getTitle(); 
	setPasteMode("AND");
	selectWindow(segmentation_title); 
	run("Copy");
	selectWindow(segmented_particles_mask); 
	run("Paste"); 
	run("Multiply...", "value=255");
	run("Convert to Mask");
	run("Fill Holes");
	//run("Brightness/Contrast...");
	resetMinAndMax;
	saveAs("Tiff", output + File.separator + file_name_without_extension + output_suffix + "_split");
	split_objects_mask = getTitle(); 
	
	run("Select None");
	run("Analyze Particles...", "size=" + minimum_cell_size + "-" + maximum_cell_size + " exclude add");
	if (roiManager("Count") > 0){
		for (i = 0; i < roiManager("Count"); i++) {
			roiManager("select", i);
			roiManager("rename", IJ.pad((i+1), 3) );
			if (cropped_cell_saving_choice == "Yes"){
				selectWindow(original_title); 
				roiManager("select", i);
				run("Duplicate...", " ");
				run("Select None");
				saveAs("TIFF", single_cell_image_output_directory + File.separator + file_name_without_extension + "_" + IJ.pad((i+1), 3));
				close(); 
			}
		}
		roiManager("deselect");
		roiManager("Save", output + File.separator + file_name_without_extension + "_split-ROIs.zip");
		//selectWindow(fluorescence_title); 
		selectWindow(original_title);
		Stack.setChannel(1);
		roiManager("multi-measure append");
		saveAs("Results", output + File.separator + "Results.csv");
	}
	close("*");
	roiManager("reset");
}











// ##################### GENERIC ##################### 

function file_name_remove_extension(TL_title){
	dotIndex = lastIndexOf(TL_title, "." ); 
	file_name_without_extension = substring(TL_title, 0, dotIndex );
	//print( "Name without extension: " + file_name_without_extension );
	return file_name_without_extension;
}

// set up time string for print statements
function TimeStamp(){
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	month = month + 1;
	TimeString ="["+year+"-";
	if (month<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+month + "-";
	if (dayOfMonth<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+dayOfMonth + " --- ";
	if (hour<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+hour+":";
	if (minute<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+minute+":";
	if (second<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+second + "]";
	return TimeString;
}

//convert time from ms to more appropriate time unit
function duration_conversion(duration){
	if (duration < 1000){
		duration_String = duration + " ms";
	} 
	else if (duration <60000){
		duration = duration / 1000;
		duration_String = d2s(duration, 0) + " s";
	}
	else if (duration <3600000){
		duration = duration / 60000;
		duration_String = d2s(duration, 1) +  "min";
	}
	else if (duration <86400000){
		duration = duration / 3600000;
		duration_String = d2s(duration, 0) + " hr";
	}
	else if (duration <604800000){
		duration = duration / 86400000;
		duration_String = d2s(duration, 0) + " d";
	}
	//print("Duration string: " + duration_String);	
	return duration_String;
}
