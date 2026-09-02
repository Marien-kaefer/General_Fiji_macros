/*
Macro to identify cells, their nucleus and cytoplasm and generate measurements for all available channels. 

												- Written by Marie Held [mheldb@liverpool.ac.uk] May 2026
												  Liverpool CCI (https://cci.liverpool.ac.uk/)
________________________________________________________________________________________________________________________

BSD 2-Clause License

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 

*/

run("Fresh Start");

#@ String(value="Please specify the files and parameters to be applied for the processing.", visibility="MESSAGE") message
#@ File (style="file", label = "Select input file to be processed:") input_file
#@ File (style="directory", label = "Select output folder to save result files to:") output_directory
#@ Integer(label="First Scene to analyse: ", value = 1, persist = true) start_scene_index
#@ Integer(label="Last Scene to analyse: ", value = 24, persist = true) end_scene_index
#@ Integer(label="Scene increment for processing:", value = 1, persist = true) scene_increment
#@ Integer(label="Median Filter radius (px): ", value = 2, persist = true) median_filter_radius
#@ Integer(label="Top Hat Filter radius (px): ", value = 30, persist = true) top_hat_filter_radius
#@ Integer(label="Variance Filter radius (px): ", value = 35, persist = true) variance_filter_radius
#@ Double(label="Wound minimum size (micron): ", value = 10000) wound_size_minimum
#@ Integer(label = "Wound centroid allowed deviation from image centre (%): ", value = 50) wound_centroid_position_deviation_percent


run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack display redirect=None decimal=3");
run("Line Width...", "line=6");
	print("Input file: " + input_file); 

for (scene_index = start_scene_index; scene_index <= end_scene_index; scene_index+=scene_increment) {
	run("Bio-Formats Importer", "open=[" + input_file + "] windowless=true autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_list=" + scene_index);
	raw_ID = getImageID();
	raw_title = File.nameWithoutExtension; 
	print("Processing " + raw_title + " Scene " + scene_index); 
	
	process_images(raw_ID, output_directory); 
	clean_up(); 
}

run("Line Width...", "line=1");
waitForUser("All done. Your job is quality control.");

function process_images(raw_ID, output_directory){
	selectImage(raw_ID); 
	getDimensions(width, height, channels, slices, frames);
	print("Width: " + width + ", Height: " + height); 
	getPixelSize(unit, pixelWidth, pixelHeight);
	mid_x = width/2 * pixelWidth ; 
	mid_y = height/2 * pixelHeight; 
	min_x = round(mid_x * wound_centroid_position_deviation_percent/100);
	max_x = round(mid_x * (1 + wound_centroid_position_deviation_percent/100));
	min_y = round(mid_y * wound_centroid_position_deviation_percent/100);
	max_y = round(mid_y * (1 + wound_centroid_position_deviation_percent/100));
	//print("Centroid cutoff: " + min_x + "-" + max_x + "; " + min_y + "-" + max_y); 
	
	
	//run("Duplicate...", "duplicate");
	run("Duplicate...", "duplicate use");
	duplicate_ID = getImageID();
	run("Duplicate...", "duplicate use");
	run("Median...", "radius=" + median_filter_radius + " stack");
	run("Top Hat...", "radius=" + top_hat_filter_radius + " stack");
	run("Variance...", "radius=" + variance_filter_radius + " stack");
	run("Convert to Mask", "method=MaxEntropy background=Dark calculate black create");
	//run("Fill Holes", "stack");
	run("Invert", "stack");
	run("Analyze Particles...", "size=" + wound_size_minimum + "-Infinity show=Masks add stack");
	roiManager("save", output_directory + File.separator + raw_title + "_Scene_" + IJ.pad(scene_index, 4) + "_ROIs-unfiltered.zip");
		
	
	// filter ROIs
	roi_index = newArray();
	print("ROI count before filtering: " + roiManager("count"));
	n = 0; 
	for (i = 0; i < roiManager("count"); i++) {
		roiManager("select", i);
		print("Investigating ROI " + i); 
		run("Measure");
		centroid_x = getResult("X", i);
		centroid_y = getResult("Y", i);
		//print("Centroid X: " + centroid_x); 
		//print("Centroid Y: " + centroid_y); 
		if (centroid_x < min_x || centroid_x > max_x || centroid_y < min_y || centroid_y > max_y){ 
			roi_index[n] = roiManager("index");
			//Array.show(roi_index); 
			roiManager("select", roi_index);
			roiManager("Delete");
			print("ROI centroid outside of the specifed central area of the image - deleted."); 
			n += 1; 
		}
	}
	print("ROI count after filtering: " + roiManager("count")); 
	run("Clear Results");	
	
	setLineWidth(6);
	setForegroundColor(0, 0, 0);
	setBackgroundColor(255, 255, 255);
	if(roiManager("count") > 0){
		for (i = 0; i < roiManager("count"); i++) {
			selectImage(duplicate_ID);
			roiManager("select", i);
			roiManager("measure");
			run("Draw", "slice");
			roiManager("deselect");
			run("Select None");
			run("Hide Overlay");
		}
		roiManager("save", output_directory + File.separator + raw_title + "_Scene_" + IJ.pad(scene_index, 4) + "_ROIs-filtered.zip");
		roiManager("deselect");
		saveAs("Results", output_directory + File.separator + raw_title + "_Scene_" + IJ.pad(scene_index, 4) + "_wound_measurements.csv");
	}
	selectImage(duplicate_ID);
	saveAs("TIFF", output_directory + File.separator + raw_title + "_Scene_" + IJ.pad(scene_index, 4) + "_wound_boundary_overlay.tif");
	selectWindow("Log"); 
	saveAs("Text", output_directory + File.separator + raw_title + "_Scene_" + IJ.pad(scene_index, 4) + "_LOG.txt");
	run("Clear Results");
}

function clean_up(){
	roiManager("reset");
	run("Select None");
	run("Hide Overlay");
	close("*");
}

