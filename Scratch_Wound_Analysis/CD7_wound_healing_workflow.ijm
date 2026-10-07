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
#@ Boolean(label="Run local contrast enhancement (CLAHE)? ") contrast_enhancement_choice
#@ Integer(label="Median Filter radius (px): ", value = 2, persist = true) median_filter_radius
#@ Integer(label="Top Hat Filter radius (px): ", value = 30, persist = true) top_hat_filter_radius
#@ Integer(label="Variance Filter radius (px): ", value = 35, persist = true) variance_filter_radius
#@ String (choices={"Li","Default", "Huang","Intermodes","IsoData","IJ_IsoData","MaxEntropy","Mean","MinError","Minimum","Moments","Otsu","Percentile","RenyiEntropy","Shanbhag","Triangle","Yen"}, style="listBox") threshold_algorithm
#@ Double(label="Wound minimum size (micron^2): ", value = 10000, persist = true) wound_size_minimum
#@ Integer(label = "Wound centroid allowed deviation from image centre (%): ", value = 25, persist = true) wound_centroid_position_deviation_percent


run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack display redirect=None decimal=3");
run("Line Width...", "line=6");
	print("Input file: " + input_file); 

for (scene_index = start_scene_index; scene_index <= end_scene_index; scene_index+=scene_increment) {
	run("Bio-Formats Importer", "open=[" + input_file + "] windowless=true autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_list=" + scene_index);
	raw_ID = getImageID();
	raw_title = File.nameWithoutExtension; 
	print("Processing " + raw_title + " Scene " + scene_index); 
	
	write_processing_parameters_to_file(input_file, output_directory, start_scene_index, end_scene_index, scene_increment, contrast_enhancement_choice, median_filter_radius, top_hat_filter_radius, variance_filter_radius, threshold_algorithm, wound_size_minimum, wound_centroid_position_deviation_percent);	
	process_images(raw_ID, output_directory); 
	clean_up(); 
}

run("Line Width...", "line=1");
waitForUser("All done. Your job is quality control.");


function write_processing_parameters_to_file(input_file, output_directory, start_scene_index, end_scene_index, scene_increment, contrast_enhancement_choice, median_filter_radius, top_hat_filter_radius, variance_filter_radius, threshold_algorithm, wound_size_minimum, wound_centroid_position_deviation_percent){
	parameters_output_file = File.open(output_directory + File.separator + "analysis_parameters.txt"); 
	print(parameters_output_file, "Folder - input: " + input_file);
	print(parameters_output_file, "Folder - output: " + output_directory);
    print(parameters_output_file, "First Scene to analyse: " + start_scene_index);
    print(parameters_output_file, "Last Scene to analyse: " + end_scene_index);
    print(parameters_output_file, "Scene increment for processing: " + scene_increment);
    print(parameters_output_file, "Contrast enhancement choice: " + contrast_enhancement_choice); 
    print(parameters_output_file, "Median Filter radius (px): " + median_filter_radius); 
    print(parameters_output_file, "Top Hat Filter radius (px): " + top_hat_filter_radius); 
    print(parameters_output_file, "Variance Filter radius (px): " + variance_filter_radius);  
    print(parameters_output_file, "Threshold algorithm: " + threshold_algorithm); 
    print(parameters_output_file, "Wound size minimum (micron^2): " + wound_size_minimum); 
    print(parameters_output_file, "Wound centroid allowed deviation from image centre (%): " + wound_centroid_position_deviation_percent); 
	File.close(parameters_output_file);
}

function CLAHE_contrast_enhancement(blocksize, histogram_bins, maximum_slope, mask, fast, process_as_composite){
	getDimensions( width, height, channels, slices, frames );
	isComposite = channels > 1;
	parameters =
	  "blocksize=" + blocksize +
	  " histogram=" + histogram_bins +
	  " maximum=" + maximum_slope +
	  " mask=" + mask;
	if ( fast )
	  parameters += " fast_(less_accurate)";
	if ( isComposite && process_as_composite ) {
	  parameters += " process_as_composite";
	  channels = 1;
	}
	   
	for ( f=1; f<=frames; f++ ) {
	  Stack.setFrame( f );
	  for ( s=1; s<=slices; s++ ) {
	    Stack.setSlice( s );
	    for ( c=1; c<=channels; c++ ) {
	      Stack.setChannel( c );
	      run( "Enhance Local Contrast (CLAHE)", parameters );
	    }
	  }
	}
}


function process_images(raw_ID, output_directory){
	selectImage(raw_ID); 
	getDimensions(width, height, channels, slices, frames);
	//print("Width: " + width + ", Height: " + height); 
	getPixelSize(unit, pixelWidth, pixelHeight);
	mid_x = width/2 * pixelWidth ; 
	mid_y = height/2 * pixelHeight; 
	min_x = (width * (0.5 - wound_centroid_position_deviation_percent/100) * pixelWidth);
	max_x = (width * (0.5 + wound_centroid_position_deviation_percent/100) * pixelWidth);
	min_y = (height * (0.5 - wound_centroid_position_deviation_percent/100) * pixelHeight);
	max_y = (height * (0.5 + wound_centroid_position_deviation_percent/100) * pixelHeight);
	//print("Centroid cutoff: " + min_x + "-" + max_x + "; " + min_y + "-" + max_y); 
	
	//run("Duplicate...", "duplicate");
	run("Duplicate...", "duplicate use");
	duplicate_ID = getImageID();
	run("Duplicate...", "duplicate use");
	
	// https://imagej.net/plugins/clahe
	// CLAHE parameters
	blocksize = 127; //127
	histogram_bins = 256;  //256
	maximum_slope = 3;
	mask = "*None*";
	fast = false;
	process_as_composite = false;
	selectImage(duplicate_ID);
	if(contrast_enhancement_choice == true){
		CLAHE_contrast_enhancement(blocksize, histogram_bins, maximum_slope, mask, fast, process_as_composite);
	};
	run("Median...", "radius=" + median_filter_radius + " stack");
	run("Top Hat...", "radius=" + top_hat_filter_radius + " stack");
	run("Variance...", "radius=" + variance_filter_radius + " stack");
	run("Convert to Mask", "method=" + threshold_algorithm + " background=Dark calculate black create");
	run("Fill Holes", "stack");
	run("Invert", "stack");
	run("Analyze Particles...", "size=" + wound_size_minimum + "-Infinity show=Masks add stack");
	for (i = 0; i < roiManager("count"); i++){
		roiManager("select", i);
		roiManager("rename", "ROI_" + IJ.pad(i,3));
	};
	roiManager("save", output_directory + File.separator + raw_title + "_Scene_" + IJ.pad(scene_index, 4) + "_ROIs-unfiltered.zip");
	
	// filter ROIs
	roi_index = newArray();
	print("ROI count before filtering: " + roiManager("count"));
	n = 0; 
	delete_array = newArray(); 
	for (i = 0; i < roiManager("count"); i++) {
		roiManager("select", i);
		roiManager("rename", "ROI_" + IJ.pad(i,3));
		//print("Investigating ROI " + i); 
		run("Measure");
		centroid_x = getResult("X", i);
		centroid_y = getResult("Y", i);
		//print("Centroid X: " + centroid_x); 
		//print("Centroid Y: " + centroid_y); 
		if (centroid_x < min_x || centroid_x > max_x || centroid_y < min_y || centroid_y > max_y){ 
			roi_index[n] = roiManager("index");
			print("ROI Manager index: " + roi_index[i] + "; n = " + n); 
			Array.show(roi_index); 
			roiManager("select", roi_index);
			delete_array[n] = i; 			
			//roiManager("Delete");
			n += 1; 
		}		
	}
	//Array.show("Delete index list", delete_array); 
	if(delete_array.length > 0){
		roiManager("select", delete_array);
		Array.show(delete_aray); 
		roiManager("delete");
	};
	print("ROI count after filtering: " + roiManager("count")); 
	run("Clear Results");		
	setLineWidth(6);
	setForegroundColor(0, 0, 0);
	setBackgroundColor(255, 255, 255);
	if(roiManager("count") > 0){
		for (i = 0; i < roiManager("count"); i++) {
			selectImage(raw_ID);
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
	selectImage(raw_ID);
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

