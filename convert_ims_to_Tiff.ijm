#@ File (label = "Input File", style = "file") input

//print(input)

slashIndex = lastIndexOf(input, File.separator ); 
file_name = substring(input, slashIndex, lengthOf(input) -1 );
directory = substring(input, 0, slashIndex );
//print("Directory: " + directory);


//print("File name: " + file_name); 
file_name_without_extension = file_name_remove_extension(file_name); 
print(TimeStamp() + ": Opening file " + file_name_without_extension + " located in " + directory ); 

//print(input); 
open(input);


print(TimeStamp() + ": Saving file " + file_name_without_extension + ".tif in " + directory ); 
saveAs("Tiff", directory + File.separator + file_name_without_extension + ".tif");


close();
print(TimeStamp() + ": Done!");

// functions
function file_name_remove_extension(file_name){
	dotIndex = lastIndexOf(file_name, "." ); 
	file_name_without_extension = substring(file_name, 0, dotIndex );
	//print( "Name without extension: " + file_name_without_extension );
	return file_name_without_extension;
}

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