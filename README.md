# General_Fiji_macros

Some tasks come up again and again in image processing and even just for display/presentation purposes. This will be grown into a collection of Fiji macros making these repetitive tasks less time consuming

## Generating a montage from a single plane multi channel image
* multi_channel_montage.ijm

Input: 
* Active image stack containing multiple channels but only one focal plane. 
* If any channels in the original image should be disregarded, please create a substack with only the channels of interest as the input. 

Output: 
* Montage containing:
  - All individual channels of the input image with a grey LUT 
  - Composite image merged from the individual channels with the LUTs set in the input image before running the macro. 

The macro offers a selection of parameters for downscaling of the images, scale bar options, montage options, and further downscaling of the montage file type for integration of the montage in presentations and/or documents without unecessarily inflating the final document file size.
