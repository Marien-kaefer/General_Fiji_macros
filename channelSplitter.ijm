// Macro to split a multichannel image into individual tif files/stacks


//BSD Zero Clause License
//Copyright (c) [2021] [Marie Held {mheldb@liverpool.ac.uk}, Image Analyst Liverpool CCI (https://cci.liverpool.ac.uk/)]
//Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
//THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.



//get input and output directories from user
#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".lsm", persist=false) suffix


setBatchMode(true);	// run routine without showing image windows, i.e. quicker

processFolder(input);

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
	numberOfChannels = nSlices();  // query number of slices in stack
	run("Split Channels");
	saveChannels(numberOfChannels);	// save channel for as many times as there were slices in the original stack
	}

// save files in specified output folder and close saved files
function saveChannels(numberOfChannels){
	for (i = 0; i < numberOfChannels; i++){
		fileName = getTitle();
		saveAs("Tiff",output + File.separator + fileName);
		close();
	}
}
