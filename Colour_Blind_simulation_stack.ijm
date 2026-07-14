OG_ID = getImageID();
OG_title = getTitle();

CB_options = newArray("Normal", "Protanopia (no red)", "Deuteranopia (no green)", "Tritanopia (no blue)", "Protanomaly (low red)", "Deuteranomaly (low green)", "Tritanomaly (low blue)", "Typical Monochromacy", "Atypical Monochromacy"); 

array_length = CB_options.length; 

for (i = 0; i < array_length; i++) {
	selectImage(OG_ID); 
	run("Duplicate...", "title=" + CB_options[i]);
	dup_ID = getImageID();
	rename(CB_options[i]);
	
	run("Simulate Color Blindness", "mode=[" + CB_options[i] + "]");

}

selectImage(OG_ID); 
close();

run("Images to Stack", "name=[" + OG_title + "_Colour_blind_simulation] use");

print("Done, check out the simulation stack. The first image is the original."); 