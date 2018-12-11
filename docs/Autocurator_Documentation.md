# Autocurator Pipeline

## Introduction
These instructions detail how to curate new data with an already-trained model. Several pretrained convolutional neural network models have been included in the demo section, all for whisker-touch curation. In order to train a new model please see the [Model Training Pipeline Guide](https://github.com/jonathansy/ContactAutocurator/blob/master/docs/Training_Pipeline_Documentation.md). The usage of custom models will not affect the general pipeline, however, models are often trained on images of specific dimensions and feeding in images outside of those dimensions can produce issues in curation. As such, the pipeline includes customization for cropping videos to particular dimensions. It is highly suggested that one train a custom model for video data requiring particular pixel dimensions to be curated. 

The speed and accuracy of the autocurator will be highly dependent on the difficulty of the problem and the size of the dataset. Oftentimes converting videos to numpy arrays will require significantly more time than the actual curation step (assuming a GPU is used). 

## Setting up the control code
The top level script for the autocurator is [autocurator.m](https://github.com/jonathansy/ContactAutocurator/blob/master/autocurator/autocurator.m) with [autocurator_fun.m]() being a function variant in case one wishes to run multiple sessions in sequence. In all other respects autocurator.m and autocurator_fun.m are identical. The first section has a list of parameters that can be set (or read in the case of the function variant) while the second section (Section Control) provides an easy way to disable certain sections of the pipeline. This is useful for debugging purposes or when re-running specific sections. For example, in the event uploading to the cloud fails, it would be a massive waste of time to re-run the numpy conversion section when to recreate files that already exist. 

### Section Overview
The general flow of the pipeline is as follows:

```matlab
%% Build data object
```
This version of the autocurator is designed to package all pre-processing data into one object. This object should contain trial, session, and video information as well as any relevant numbers one wishes to use for preprocessing. since ContactAutocurator was designed to determine pole-whisker touches, by default it includes information on the distance between a mouse whisker and a pole as calculated from Janelia Farm whisker-tracking files. One is not obligated to include information outside of trial, session, and video information, however failing to do so will render the preprocessing section of this pipeline irrelevant. If one wishes to crop images in the numpy conversion step, this object should also include the centerpoints of the desired cropped frames/new ROI. Default code is included to determine centerpoints based on the position of a pole in the image (referred to as "bar positions' in the Hires Lab). 

```matlab
%% Preprocess data
```
In this case, preprocessing refers to selecting which images the autocurator should look at while excluding either bad data or obvious frames. (Image preprocessing, meaning changes done to the images themselves before they are fed into the neural network, happen in the numpy conversion step). Excluding frames in this type of preprocessing helps make the pipeline faster, as fewer frames of video actually need to be processed. By default, the pipeline only includes preprocessing using distance to pole, however it can be generalized to any other metric that exists on a frame-by-frame basis. 

```matlab
%% Convert to numpy
```
This section takes the frames indicated by preprocessing (or every frame in the event it was disabled) and converts them to numpy arrays. One numpy array is created per trial with each array being 3-dimensional (a 3rd-rank tensor). The conversion function, [videos_to_numpy.m]() also crops frames of video down to a smaller ROI based on the dimensions specified in the function. By default

```matlab
%% Upload to cloud
```
This section is fairly straightforward and only uploads the completed numpy files to the cloud. Before reaching this step, you should have a Google Cloud Platform account established and a bucket location in which to upload your files and perform training. 

## Troubleshooting

