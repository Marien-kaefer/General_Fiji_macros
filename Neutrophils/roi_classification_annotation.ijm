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

#@ File (label = "Classification results file (csv)", style = "table") table_file
#@ File (label = "Folder containing raw images", style = "directory") input
#@ File (label = "Folder containing ROI sets", style = "directory") ROI_input
#@ String (label = "File suffix", value = ".tif", persist=false) input_suffix
#@ File (label = "Output directory", style = "directory") output


run("Table... ", "open=" + table_file);
image_names_and_ROI_IDs = Table.getColumn("Sample and ROI ID"); 
object_classes = Table.getColumn("Prediction (Expert Scores)"); 

//setBatchMode("hide");
processFolder(input); 
waitForUser("Done. Check out the results! :) ");
//setBatchMode("show");


// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i])){ //also process files in directories within the input directory
			
		}
		if(endsWith(list[i], input_suffix)){
			file_processing(input, list, ROI_input, output);	
		}
	}
}


function file_processing(input, list, ROI_input, output){
	inputFile = input + File.separator + list[i]; 
	print("Processing file (" + (i+1) + "/" + list.length + ") : " + list[i]); 
	if (File.exists(input + File.separator + list[i])){
		run("Bio-Formats Windowless Importer", "open=[inputFile]");
		image_name = File.nameWithoutExtension;
		Stack.setChannel(1);
		run("Enhance Contrast", "saturated=0.05");
		Property.set("CompositeProjection", "null");
		Stack.setDisplayMode("color");
		run("Flatten", "stack");
		ROI_Set_file = ROI_input + File.separator + image_name + "_split-ROIs.zip";
		if (File.exists(ROI_Set_file)){
			roiManager("Open", ROI_Set_file);
			
			for (i = 0; i < roiManager("count"); i++) {
				roiManager("select", i);
				roi_name = Roi.getName;
				object_to_search_for = image_name + "_" + roi_name; 
				//print("object to search for: " + object_to_search_for); 
				index_of_object_in_array = contains( image_names_and_ROI_IDs, object_to_search_for );
				//print(index_of_object_in_array); 
				//print(object_classes[index_of_object_in_array]); 
				if (isNaN(index_of_object_in_array) == true) {
					print(object_to_search_for + " does not exist in Classification table"); 
				}
				else{
					if (object_classes[index_of_object_in_array] == "QC-NETs") {
						setForegroundColor(255, 255, 0);
					}
					else if (object_classes[index_of_object_in_array] == "QC-Healthy") {
						setForegroundColor(0, 255, 255);
					}
					else {
						setForegroundColor(255, 255, 255);
						setBackgroundColor(0, 0, 0);
					}
					run("Draw", "slice");
				}
			}
			saveAs("Tiff", output + File.separator + image_name + "_annotated");
			run("Fresh Start");
		}
	}
	run("Fresh Start");
}

function contains( image_names_and_ROI_IDs, object_to_search_for ) {
    for (i=0; i<image_names_and_ROI_IDs.length; i++) 
        if ( image_names_and_ROI_IDs[i] == object_to_search_for ) return i;
    return false;
}
