image_title = getTitle();
File.setDefaultDir(getDirectory("image"));

//preprocessing of DAPI channel
run("Duplicate...", "duplicate channels=2");
run("Subtract Background...", "rolling=25");	//change from 25 as required
run("Duplicate...", " ");

// Identify bacteria 
//run("Threshold...");
setAutoThreshold("IsoData dark");	// choose anohter thresholding mechanism if required
run("Convert to Mask");
run("Watershed");	//split toughing objects
run("Analyze Particles...", "size=0-300 pixel exclude add");  //change min and max sizes as required
roiManager("Save", image_title + "-bacteria-ROIs.zip");

//Identify cells
selectWindow(image_title);
run("Duplicate...", "duplicate channels=1");
setAutoThreshold("Mean dark");  // choose anohter thresholding mechanism if required
//run("Threshold...");
setOption("BlackBackground", false);
run("Convert to Mask");
run("Analyze Particles...", "size=1000-Infinity pixel exclude add"); //change min {and max} sizes as required

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
roiManager("Save", image_title + "-bacteria-and-cell-ROIs.zip");

//set measurements
run("Set Measurements...", "area mean modal integrated median display redirect=None decimal=3"); 	//change as required
selectWindow(image_title); //make sure to select the channel to be measured
setSlice(1);  //assuming that Channel 1 is the channel to be measured

//measure intensities
roiManager("multi-measure");

//save intensities
saveAs("Results", image_title + "-Results-bacteria-and-cell-red-intensities.csv");