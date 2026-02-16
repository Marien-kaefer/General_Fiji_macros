# General_Fiji_macros

Some tasks come up again and again in image processing and even just for display/presentation purposes. This will be grown into a collection of Fiji macros making these repetitive tasks less time consuming

## Convert stack to individual z slices
* Stack_To_Slices.ijm

required: 
* open z-stack, can be multidimensional  

Output: 
* one tif file per z slice
  - The file names are suffixed with "_Z{sliceNumber}

The macro requests the user to specify an output folder. 

## Create z stack from height map/topography image
* create_z-stack_from_height_map.ijm

required: 
* location of topography image - at the moment this assumes that the topography is an image file

Output: 
* one z stack
  - The file names are suffixed with "_Z{sliceNumber}

The macro requests the user to specify the following parameters: 
* calibration unit
* x, y & z scaling of the height map/topography image 
* number of z slices in stack to be generated

## Generate maximum intensity projections of multiple files automatically
* MakeAndSaveMIP.ijm

Input: 
* folder containing image files  

Output: 
* one tif file per  image
  - The file names are prefaced with MAX- as it is implemented in Fiji

The macro requests the user to specify an input and an output folder. The files are filtered for a specific file format (default: .czi). All the files in the input folder with the specified suffix will be processed. 

## Generate montage from a single plane multi channel image
* multi_channel_montage.ijm

Input: 
* Active image stack containing multiple channels but only one focal plane. 
* If any channels in the original image should be disregarded, please create a substack with only the channels of interest as the input. 

Output: 
* Montage containing:
  - All individual channels of the input image with a grey LUT 
  - Composite image merged from the individual channels with the LUTs set in the input image before running the macro. 

The macro offers a selection of parameters for downscaling of the images, scale bar options, montage options, and further downscaling of the montage file type for integration of the montage in presentations and/or documents without unecessarily inflating the final document file size.

## Instance mask to binary stack
*instance_mask_to_binary_stack.ijm

Input: 
* saved instance mask, e.g. created through Cellpose
* single channel image expected
* image can be z-stack or time series but not a combination of the two

Output:
* Stack containing binary masks per slice/frame

## Split a multichannel image into individual .tif files
* channelSplitter.ijm

Input: 
* folder containing image files  

Output: 
* one tif file per channel for each image
  - This macro runs independent of the number of channels in the original image. The file names are prefaced with C1, C2, ... Cn as it is implemented in Fiji

The macro requests the user to specify an input and an output folder. The files are filtered for a specific file format (default: .lsm). All the files in the input folder with the specified suffix will be processed. 
