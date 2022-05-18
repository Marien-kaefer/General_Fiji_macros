// Macro to generate a montage from a single focal plane, multichannel image. Individual chanenls are converted to grayscale.
// The composite image contains the channel colours as set for the original z-stack. The multichannel image must be open and 
// the only open image in the workspace before running the macro
//
//
//												- Written by Marie Held [mheldb@liverpool.ac.uk] February 2021
//												  Liverpool CCI (https://cci.liverpool.ac.uk/)

title = getTitle(); 
//print("Image title: " + title); 

//get image dimensions, in particular number of channels and image width
Stack.getDimensions(width, height, channels, slices, frames)
//print("width: " + width);

// set default processing parameters
Montage_slices = channels +1; 
Montage_columns = floor(Montage_slices / 2 + 1);
Montage_rows = Math.ceil(Montage_slices / Montage_columns);
resized_image_width = 300; 
scale_bar_width = 10;
scale_bar_height = 5;
scale_font_size = 12;
final_image_type_choice = newArray("8-bit color", "RGB");
include_merge_choice = newArray("Yes", "No");
auto_brightness_and_contrast_choice = newArray("Yes", "No"); 

//request information from the user, displaying default processing parameters as set above
scale_bar_option = newArray("Yes", "No");
scale_bar_colour_choice = newArray("White", "Black", "Light Gray", "Gray", "DarkGray", "Red", "Green", "Blue", "Yellow"); 
scale_bar_position_choice = newArray("Upper Right", "Lower Right", "Lower Left", "Upper Left");
Dialog.create("Please choose processing parameters");
Dialog.addMessage("The image currently being processed is " + title + "\n" + "Please choose the following parameters.");
Dialog.addNumber("Resize image width to (pixels):", resized_image_width);
Dialog.addRadioButtonGroup("Auto set Brightness or contrast? If no, the currently set display settings will be used.", auto_brightness_and_contrast_choice, 1, 2, auto_brightness_and_contrast_choice[0]);
Dialog.addRadioButtonGroup("Add scale bar? ", scale_bar_option, 1, 2, scale_bar_option[0]);
Dialog.addNumber("Scale bar width (microns):", scale_bar_width);
Dialog.addNumber("Scale bar height (pixels):", scale_bar_height);
Dialog.addNumber("Scale font size:", scale_font_size);
Dialog.addChoice("Scale bar colour:", scale_bar_colour_choice);
Dialog.addChoice("Scale bar position:", scale_bar_position_choice);
Dialog.addMessage("Montage dimensions");
Dialog.addNumber("Montage columns:", Montage_columns);
Dialog.addNumber("Montage rows:", Montage_rows);
Dialog.addRadioButtonGroup("Final image type: ", final_image_type_choice, 1, 2, final_image_type_choice[0]);
Dialog.addRadioButtonGroup("Include merged channel image? ", include_merge_choice, 1, 2, include_merge_choice[0]);
Dialog.show();
//title = Dialog.getString();
resized_image_width = Dialog.getNumber();
auto_brightness_and_contrast_choice = Dialog.getRadioButton();
scale_bar_option = Dialog.getRadioButton();
scale_bar_width = Dialog.getNumber();
scale_bar_height = Dialog.getNumber();
scale_font_size = Dialog.getNumber();
scale_bar_colour = Dialog.getChoice();
scale_bar_position = Dialog.getChoice();
Montage_columns = Dialog.getNumber();
Montage_rows = Dialog.getNumber();
final_image_type = Dialog.getRadioButton();
include_merge_choice = Dialog.getRadioButton();


run("Duplicate...", "duplicate");

// resize image
run("Size...", "width=resized_image_width depth=channels constrain average interpolation=Bicubic")
scaled_title = getTitle(); 

run("Duplicate...", "duplicate");
duplicate_Title = getTitle();

// set LUTs for single channel images to gray
for (i=0; i<channels; i++){
	selectWindow(scaled_title);
	//print("channel processed: " + (i+1)); 
	setSlice(i+1);
	if(auto_brightness_and_contrast_choice == "Yes"){
		run("Enhance Contrast", "saturated=0.35");
	}
	run("Grays");
}
selectWindow(scaled_title);
if (scale_bar_option == "Yes"){
	run("Scale Bar...", "width=scale_bar_width height=scale_bar_height font=scale_font_size color="+scale_bar_colour+" background=None location=["+scale_bar_position+"] bold label");
}
run("RGB Color");
run("Stack to Images");

if (include_merge_choice == "Yes"){
	// generate composite image with pseudocolours
	selectWindow(duplicate_Title);
	for (i=0; i < (channels); i++){
		selectWindow(duplicate_Title);
		setSlice(i+1);
		//print("Channel " + (i+1));
		if(auto_brightness_and_contrast_choice == "Yes"){
			run("Enhance Contrast", "saturated=0.35");
		}
	}
	run("Make Composite");
	//add scale bar to composite image
	if (scale_bar_option == "Yes"){
		run("Scale Bar...", "width=scale_bar_width height=scale_bar_height font=scale_font_size color="+scale_bar_colour+" background=None location=["+scale_bar_position+"] bold overlay");
	}
	run("Flatten");
}

// gather single channel and composite merge image in single stack to generate montage
run("Images to Stack", "name=Stack title=[] use");
// make montage
run("Make Montage...", "columns=Montage_columns rows=Montage_rows scale=1 border=3");
// convert to 8-bit colour image to reduce file size
if (final_image_type == "8-bit color"){
	if (bitDepth() == "RGB"){
		run("8-bit Color", "number=256");
	}
	else if (bitDepth() == "16-bit"){
		run("8-bit");
	}
}
