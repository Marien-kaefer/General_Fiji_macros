/*


												- Written by Marie Held [mheldb@liverpool.ac.uk] February 2026
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


#@ File (style = "open", label="Select file to be processed") input_file

open(input_file);

instance_mask_ID = getImageID();
file_name = File.nameWithoutExtension; 
directory = File.directory;
run("glasbey_on_dark");

getDimensions(width, height, channels, slices, frames);

if (frames > 1) {
	iterator = "frames";
	loop_stop = frames; 
	iterate_through_stack(width, height, channels, slices, frames, instance_mask_ID, iterator, loop_stop);
}
else if (slices > 1){
	iterator = "slices";
	loop_stop = slices; 
	iterate_through_stack(width, height, channels, slices, frames, instance_mask_ID, iterator, loop_stop);
}
else {
	waitForUser("I am not set up to iterate over two dimensions - frames and slices.");
}

function iterate_through_stack(width, height, channels, slices, frames, instance_mask_ID, iterator, loop_stop){
	newImage("HyperStack", "8-bit color-mode", width, height, channels, slices, frames);
	binary_mask_ID = getImageID();
	
	for (i = 1; i <= loop_stop; i++) {
		selectImage(instance_mask_ID);
		if (iterator == "slices") {
			Stack.setSlice(i);
		}
		else if (iterator == "frames") {
			Stack.setFrame(i); 
		}
		run("Duplicate...", " ");
		dup_ID = getImageID();
		run("glasbey_on_dark");	
		run("LabelMap to ROI Manager (2D)");
		
		selectImage(binary_mask_ID);
		if (iterator == "slices") {
			Stack.setSlice(i);
		}
		else if (iterator == "frames") {
			Stack.setFrame(i); 
		}
		for (n = 0; n < roiManager("count"); n++) {
		//for (n = 0; n < 10; n++) {
			roiManager("Select", n);
			setForegroundColor(255, 255, 255);
			setBackgroundColor(0, 0, 0);
			run("Fill", "slice"); 
			setForegroundColor(0, 0, 0);
			setBackgroundColor(255, 255, 255);
			run("Draw", "slice");
		}
		roiManager("deselect");
		roiManager("reset");
		run("Select None");
		selectImage(dup_ID);
		close(); 
	}

saveAs("TIFF", directory + File.separator + file_name + "_binary.tiff");

}

waitForUser("Done. Time for a victory lap?");