# seizure-imaging
Code for GCaMP-imaging in mouse models of absence epilepsy

To begin, open `ExampleScript.m`

## Step 1 - Prepare data

Run `ExampleScript.m` section-by-section (one at a time). By doing this you will complete the necessary manual preparation steps for calculating dF/F traces for a widefield imaging series. Below are short descriptions of each step in `ExampleScipt.m`:

1) Converting .dcimg filetype to .imgbin. Only Windows can run the proprietary Hamamatsu MEX code to read .dcimg files so converting to .imbgin is useful for converting to a file type that any OS can use. .imbgin files are binary files that can be read with the function `imgbinRead` which reads the images in as a memory map object. Here's [more on memory mapping in MATLAB](https://www.mathworks.com/help/matlab/memory-mapping.html)
2) Manually selecting the time limits for the imaging epoch. Simply select one timepoint before the imaging begins and one after the imaging ends. This is very useful is there were multiple strings camera TTLs and you want to ignore some of them
3) Get the actual frame times. This is necessary for aligning the imaging data with the other data streams (EEG, movement, pupil imaging, etc)
4) Manually mapping the points on the widefield image to a reference atlas. The user selects corresponding points in side-by-side images of the first widefield imaging frame and the dorsal image of the Allen reference atlas
5) Morphing the atlas image to register it to the data

## Step 1.5 (Optional)  - Run Motion Correction
This step uses the NoRMCorre algorithm to correct motion artifacts that may be present in the data

## Step 2 - Generate dF/F trace for all regions labeled in the reference atlas
This step will yield the final result: the dF/F trace for every region that is labeled in the reference atlas. Depending on the size of the original data, this step can by VERY MEMORY INTENSIVE: a 50GB imaging sessions exceeds available memory on a system with 256GB  RAM. 

This is done by first low-pass filtering the data from each pixel with a cutoff frequency of 0.1Hz. This accounts for fluorescence decay due to photobleaching. The low-passed trace is used as the denomiator in the dF/F calculation. Then, the discrete regions in the morphed reference atlas image are used as masks to compute a mean dF/F for every frame and every region. 

The final result is a structure called `pd` with the following fields:

`dft` - mean dF/F for all labeled regions

`FT` - frames times. The length will equal `length(pd.dft)`

`reg_img` - the morphed reference atlas image used to segment the data images

`labNames` - names of all the labeled cortex regions

`eeg.data` - EEG trace

`eeg.tv` - Corresponding EEG time vector (time value of every EEG sample)

## Dependencies
I've tried to include all non-MATLAB-toolbox dependencies in the 'Dependencies' folder in this repo, but here are links too:

[FMAToolbox](https://github.com/michael-zugaro/FMAToolbox)

[ADInstruments (LabChart) SDK](https://github.com/JimHokanson/adinstruments_sdk_matlab)

[Chronux Toolbox](https://github.com/jsiegle/chronux)

[MATLAB Signal Processing Toolbox](https://www.mathworks.com/products/signal.html)

[MATLAB Statistics and Machine Learning Toolbox](https://www.mathworks.com/products/statistics.html)

[abfload](https://github.com/fcollman/abfload)

[NoRMCorre](https://github.com/flatironinstitute/NoRMCorre)
