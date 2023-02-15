// Macro to convert individual .ims files to .tif


//MIT License
//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

//request input file
#@ File (label = "Input File", style = "file") input

//get file name and directory from file, uncomment the print statements for troubleshooting 
//print(input)
start = getTime(); 
slashIndex = lastIndexOf(input, File.separator ); 
file_name = substring(input, slashIndex + 1, lengthOf(input) -1 );
directory = substring(input, 0, slashIndex );
//print("Directory: " + directory);
//print("File name: " + file_name); 
file_name_without_extension = file_name_remove_extension(file_name); 
print(TimeStamp() + ": Opening file " + file_name_without_extension + " located in " + directory ); 

//open file, adjust brightness and contrast and save as .tif
//print(input); 
open(input);
run("Enhance Contrast", "saturated=0.35");
print(TimeStamp() + ": Saving file " + file_name_without_extension + ".tif in " + directory ); 
saveAs("Tiff", directory + File.separator + file_name_without_extension + ".tif");

//close original file and calculate elapsed time
close();
stop = getTime(); 
duration = stop - start;
duration_String = duration_conversion(duration);
print("The file conversion took " + duration_conversion(duration));
print(TimeStamp() + ": Done!");



// functions
function file_name_remove_extension(file_name){
	dotIndex = lastIndexOf(file_name, "." ); 
	file_name_without_extension = substring(file_name, 0, dotIndex );
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
