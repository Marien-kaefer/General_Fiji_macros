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
processedFiles = newArray();
input_root_path_length = lengthOf(input);
output_root_path_length = lengthOf(output);
output_root_path = substring(output, 0, output_root_path_length);
run("Set Measurements...", "area mean standard modal min centroid perimeter bounding fit shape feret's integrated median skewness kurtosis display decimal=3");


// Start processing from the top-level directory
processDirectory(input, output, input_root_path_length, 1);

//let user know the process has finished and how long it took
stop = getTime(); 
duration = stop - start;
duration_String = duration_conversion(duration);
print(TimeStamp() + ": Processing complete. The analysis took " + duration_conversion(duration) + ".");
beep();

// Recursive function to process all files in directories
function processDirectory(input, output, input_root_path_length, level) {
    list = getFileList(input);
    for (i = 0; i < list.length; i++) {
        path = input + File.separator + list[i];
        if (File.isDirectory(path)) {
            // Create corresponding output directory
            File.makeDirectory(output + File.separator + list[i]);
            // Recursively process the subdirectory
            processDirectory(path, output + File.separator + list[i], input_root_path_length, level + 1);
        } else {
            // Process image file
            outputPath = output + File.separator + list[i];
            //sub_dir_and_file = substring(path, input_root_path_length);
            //print("Subdirectory and file currently processing: " + sub_dir_and_file); 
            file_processing(input, list, classifier_file, output, output_root_path, output_suffix, minimum_cell_size, maximum_cell_size);
        }
    }
}

function file_processing(input, list, classifier_file, output, output_root_path, output_suffix, minimum_cell_size, maximum_cell_size){
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
    selectWindow(fluorescence_title); 
    run("Segment Image With Labkit", "segmenter_file=[" + classifier_file + "] use_gpu=false");
    segmentation_title = getTitle(); 
    selectWindow(segmentation_title); 
    //save segmentation file
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
                files_and_ROIs = substring(output, output_root_path_length) + File.separator + file_name_without_extension + "_" + IJ.pad((i+1), 3);
                //print(files_and_ROIs); 
                File.append(files_and_ROIs, output_root_path + File.separator + "folder_file_ROI_ID.txt"); 
                close(); 
            }
        }
        roiManager("deselect");
        roiManager("Save", output + File.separator + file_name_without_extension + "_split-ROIs.zip");
        //selectWindow(fluorescence_title); 
        selectWindow(original_title);
        Stack.setChannel(1);
        roiManager("multi-measure append");
        saveAs("Results", output_root_path + File.separator + "Results.csv");
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
