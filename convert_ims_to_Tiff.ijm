#@ File (label = "Input File", style = "file") input

file_name = getTitle();
slashIndex = lastIndexOf(input, File.separator ); 
directory = substring(input, 0, slashIndex );
//print("Directory: " + directory);


//print("File name: " + file_name); 
file_name_without_extension = file_name_remove_extension(file_name); 
print("Opening file " + file_name_without_extension + " located in " + directory ); 

//print(input); 
open(input);
print("Saving file " + file_name_without_extension + ".tif in " + directory ); 
saveAs("Tiff", directory + File.separator + file_name_without_extension + ".tif");


close();
print("Done!")

// functions
function file_name_remove_extension(file_name){
	dotIndex = lastIndexOf(file_name, "." ); 
	file_name_without_extension = substring(file_name, 0, dotIndex );
	//print( "Name without extension: " + file_name_without_extension );
	return file_name_without_extension;
}