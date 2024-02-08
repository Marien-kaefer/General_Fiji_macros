/*


												- Written by Marie Held [mheldb@liverpool.ac.uk] & Thomas Waring [twaring@liverpool.ac.uk] February 2024
												  Liverpool CCI (https://cci.liverpool.ac.uk/)
________________________________________________________________________________________________________________________

BSD 2-Clause License

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
*
*/

pre_clean_up();

//get input parameters
#@ String(value="Please select the files you wish to process.", visibility="MESSAGE") message
#@ String(choices={"ASCII","TIFF"}, style="radioButtonHorizontal") input_file_type
#@ File (label = "Height map to process:", style = "open") height_inputFile
#@ File (label = "Youngs modulus map to process:", style = "open") youngs_inputFile
#@ String(label="Calibration unit", choices={"µm", "nm"}, style="list") calibration_unit
//#@ String(label = "Calibration unit: ", description = "nm", persist=true) calibration_unit
#@ Double(label="Calibration in x: " , value = 0.33, stepSize=0.001, persist=false) x_scaling
#@ Double(label="Calibration in y: " , value = 0.33, stepSize=0.001 , persist=false) y_scaling
#@ Integer(label="Number of z slices in resulting 3D stack: " , value = 13, persist=false) z_slices

setBatchMode("hide");
z_stack_title = generate_z_stack_from_height_map(height_inputFile, x_scaling, y_scaling, z_slices, calibration_unit); 
create_Youngs_modulus_stack(youngs_inputFile, z_slices, z_stack_title);
print("Done!"); 


setBatchMode("show");
//print("x_scaling: " + x_scaling); 
//print("y_scaling: " + y_scaling); 
//print("Calibration unit: " + calibration_unit); 


function generate_z_stack_from_height_map(height_inputFile, x_scaling, y_scaling, z_slices, calibration_unit){
	if (input_file_type == "TIFF") {
		run("Bio-Formats Windowless Importer", "open=[" + height_inputFile + "]");
	}
	else if (input_file_type == "ASCII") {
		run("Text Image... ", "open=[" + height_inputFile + "]");
	}
	topo_title = getTitle(); 
	topo_name = file_name_remove_extension(topo_title);
	z_stack_name = topo_name + "_z-stack"; 
	getDimensions(width, height, channels, slices, frames);
	getRawStatistics(nPixels, mean, min, max, std, histogram);
	print("min: " + min); 
	print("max: " + max); 
	print("range: " + (max-min));
	z_interval = (max - min) / z_slices; 
	print("Interval: " + z_interval);
	newImage(z_stack_name, "16-bit black", width, height, z_slices);
	run("Paste Control...");
	setPasteMode("OR");
	
	for (i = 0; i < z_slices; i++) {	
		print((i + 1) + "/" + z_slices); 
		//print("height level: " + i * z_interval); 
		selectWindow(topo_title); 
		run("Duplicate...", " ");
		temp_title = getTitle(); 
		setAutoThreshold("Default dark");
		//run("Threshold...");
		//print("Threshold min: " + (min + (i * z_interval))); 
		//print("Threshold max: " + (min + ((i+1) * z_interval))); 
		setThreshold((min + (i * z_interval)), (min + (i+1) * z_interval));
		setOption("BlackBackground", true);
		run("Convert to Mask");
		run("Copy");
		selectWindow(z_stack_name); 
		setSlice((z_slices - i));
		run("Paste");
		run("Enhance Contrast", "saturated=0.35");
		run("Select None");
		selectWindow(temp_title); 
		close();
		setBatchMode("show");
	}
	
	selectWindow(z_stack_name); 
	Stack.setXUnit(calibration_unit);
	if (calibration_unit == "µm") {
		z_interval = z_interval * 1E6; 
	}
		if (calibration_unit == "nm") {
		z_interval = z_interval * 1E9; 
	}
	//print("Converted Z interval): " + z_interval); 

	run("Properties...", "channels=1 slices=" + z_slices + " frames=1 pixel_width=" + x_scaling + " pixel_height=" + y_scaling + " voxel_depth=" + z_interval + " frame=[0.00 sec]");
	z_stack_title = getTitle();
	selectWindow(topo_title);
	close();
	return 	z_stack_title;
}

function create_Youngs_modulus_stack(youngs_inputFile, z_slices, z_stack_title){
	selectWindow(z_stack_title);
	run("Duplicate...", "duplicate");
	z_stack_title_dupl = getTitle();
	run("Divide...", "value=255.0000000 stack");
	for (i = 0; i < z_slices; i++) {	
		if (input_file_type == "TIFF") {
			run("Bio-Formats Windowless Importer", "open=[" + youngs_inputFile + "]");
		}
		else if (input_file_type == "ASCII") {
			run("Text Image... ", "open=[" + youngs_inputFile + "]");
		}
	}
	run("Images to Stack", "use");
	parameter_image_title = getTitle();
	
	imageCalculator("Multiply create 32-bit stack", parameter_image_title , z_stack_title_dupl);

}

function pre_clean_up(){
	setForegroundColor(255, 255, 255);
	setBackgroundColor(0, 0, 0);
	close("*");
	roiManager("reset");
	run("Clear Results");
}

function file_name_remove_extension(originalTitle){
	dotIndex = lastIndexOf(originalTitle, "." ); 
	file_name_without_extension = substring(originalTitle, 0, dotIndex );
	//print( "Name without extension: " + file_name_without_extension );
	return file_name_without_extension;
}