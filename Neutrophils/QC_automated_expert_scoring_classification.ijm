// Prompting user for input and output directories
#@ File (label = "Input directory", style = "directory") inputDir
#@ File (label = "Output directory", style = "directory") outputDir

// Main function to process the folder
processFolder(inputDir);
print("Done! Check out the results.");
beep();

// Function to scan folders/subfolders/files to find image files
function processFolder(inputDir) {
    list = getFileList(inputDir);
    list = Array.sort(list);
    for (i = 0; i < list.length; i++) {
        if (File.isDirectory(inputDir + File.separator + list[i])) {
            processFolder(inputDir + File.separator + list[i]);
        } else {
        	print(list[i]); 
            if (endsWith(list[i], ".tif")) { // || endsWith(list[i], ".czi")
                processFile(inputDir, list[i]);
            }
        }
    }
}

// Function to process individual files
function processFile(directory, file) {
    open(directory + File.separator + file);
    imageTitle = getTitle();
    
    // Check if there is a point selection in the image
    pointsAvailable = roiManager("count") > 0 && roiManager("getType", 0) == "Point";
    if (pointsAvailable) {
        pointsROI = roiManager("getRoi", 0);
        pointArray = pointsROI.getPolygon().xpoints;
    } else {
        pointArray = newArray();
    }
    
    // Open ROI set with the same name as the image
    roiFile = directory + File.separator + imageTitle + ".zip";
    roiManager("reset");
    if (File.exists(roiFile)) {
        roiManager("Open", roiFile);
    } else {
        close();
        return;
    }
    
    // Prepare to write results
    resultsFile = outputDir + File.separator + imageTitle + "-results.txt";
    results = newArray();
    
    // Analyze each ROI in the set
    roiCount = roiManager("count");
    for (j = 0; j < roiCount; j++) {
        roiManager("Select", j);
        roiName = "ROI_" + j;
        
        // Check if ROI contains any points
        roiContainsPoint = "Healthy";
        if (pointsAvailable) {
            roi = roiManager("getRoi", j);
            roiBounds = roi.getBounds();
            for (k = 0; k < pointArray.length; k++) {
                if (roi.contains(pointArray[k], pointArray[k])) {
                    roiContainsPoint = "NET";
                    break;
                }
            }
        }
        
        // Add result to array
        results = Array.concat(results, newArray(roiName + "\t" + roiContainsPoint));
    }
    
    // Write results to file
    File.saveString(Array.join(results, "\n"), resultsFile);
    
    // Clean up
    close();
}

// Helper functions to manage ROI manager
function roiManager(action, param) {
    if (action == "reset") {
        eval("script", "roiManager('reset');");
    } else if (action == "count") {
        return eval("script", "roiManager('count');");
    } else if (action == "getType") {
        return eval("script", "roiManager('getType', " + param + ");");
    } else if (action == "getRoi") {
        return eval("script", "roiManager('getRoi', " + param + ");");
    } else if (action == "Select") {
        eval("script", "roiManager('Select', " + param + ");");
    } else if (action == "Open") {
        eval("script", "roiManager('Open', '" + param + "');");
    }
}

// Helper function to check if string ends with a suffix
function endsWith(str, suffix) {
    return str.indexOf(suffix, str.length - suffix.length) !== -1;
}
