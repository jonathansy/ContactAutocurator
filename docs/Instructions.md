Documentation on Installation and Use of the Whisker Autocurator
======
*Written 2018-06-11 by J. Sy*

*Last updated 2018-06-19 by J. Sy*

[![Hires Lab](https://github.com/jonathansy/whisker-autocurator/blob/master/Resources/Images/HiresLab-logoM.png)](http://68.181.113.239:8080//hireslabwiki/index.php?title=Main_Page)

Table of Contents 
------
[Installation](https://github.com/jonathansy/whisker-autocurator/blob/master/Autocurator_Beta/README.md#installation)

[Cloud ML Setup](https://github.com/jonathansy/whisker-autocurator/blob/master/Autocurator_Beta/README.md#cloud-ml-setup)

[Local Drive Setup](https://github.com/jonathansy/whisker-autocurator/blob/master/Autocurator_Beta/README.md#local-drive-setup)

[Operation and Use](https://github.com/jonathansy/whisker-autocurator/blob/master/Autocurator_Beta/README.md#operation-and-use)

[Troubleshooting](https://github.com/jonathansy/whisker-autocurator/blob/master/Autocurator_Beta/README.md#troubleshooting)

Installation 
------
In addition to all the scripts in this repository, you will also require a working Google Cloud Services account. Curation can be done using either a VM or CloudML, but these scripts have been optimized for Cloud ML. Additionally, you will require a functional trial array and an empty contact array for your data. These can be created using software found in the Hires Lab repository [HLab_MatlabTools](https://github.com/hireslab/HLab_MatlabTools). The scripts in [HLab_Whiskers](https://github.com/hireslab/HLab_Whiskers) will also need to be added to the MATLAB path to instantiate the trial arrays. 

Clone or download the scripts in this directory as well as the HLab dependencies and add both to the path. Currently the trial contact browser in HLab_Matlabtools is backwards compatible to MATLAB 2013b. The autocurator scripts in here may be compatible with older versions but have not been tested as such. 

### Full Dependency List
* Python 3.5 (compatibility not tested with 2.7)  
  - Numpy package  
  - Pickle package  
  - Scipy package  
* Google Cloud SDK package 
* MATLAB r2013b or later (recommend Parallel Processing and Machine Learning toolbox)  
  - [HLab_MatlabTools](https://github.com/hireslab/HLab_MatlabTools)  
  - [HLab_Whiskers](https://github.com/hireslab/HLab_Whiskers)
  - [npy-matlab](https://github.com/kwikteam/npy-matlab)
* Google Cloud Account

Cloud ML Setup
------
If you intend to use the cloud curation scripts in this package, you will first need to setup a consistent directory structure within a Google Cloud Bucket. Buckets are a form of cloud data storage. Information about creating and using them can be found [here](https://cloud.google.com/storage/docs/creating-buckets). After creating a cloud storage bucket for your training jobs, you should create the following directories:
/Jobs for storing output logs from curation
/Data for importing uncurated image data 
/Curated_Data for placing curated labels for export 
/Model_Saves for placing the model(s) you wish to use for curation.

Cloud storage buckets begin with the prefix gs://, for example gs://my_bucket/Data. Make sure all relevant cloud paths are set within [autocurator_master_function.m](https://github.com/jonathansy/whisker-autocurator/blob/master/Autocurator_Beta/autocurator_master_function.m). Cloud storage buckets do not have the same functionality as local drives and thus will not display their properties or index files. They also require the File_IO package to index on Python (included with Tensorflow). 

Submitting training jobs to CloudML do not require manually setting up virtual machines on Google's cloud console. You will have to specify certain settings for the curation environment when you submit a job to the cloud. These are handled via  the 'gcloud ml-engine jobs submit' command as well as a .yaml file included in the local directory. Important variables to specify are the type of GPU (if any) to use, the runtime environment, and the [region](https://cloud.google.com/compute/docs/regions-zones/) (note that only certain regions support GPU use).    

Local Drive Setup 
------
Autocurator_Beta, HLab_MatlabTools, HLab_Whiskers, and npy-matlab should all be cloned to the local Github location and added to the MATLAB path. Python should be installed. Once Python is installed, use pip to install the other packages on the command line (exact syntax for using pip may vary with your version of Python). Install Google Cloud SDK and make sure its commands can be run from the command line prompt. 

Within Autocurator_Beta, make sure you have a subdirectory called 'trainer' (you can rename it but you will need to change the pathing in 'autocurator_master_function.m'. Within this subdirectory you should have cnn_curator_cloud.py, the .yaml file you are using as a configuration file (default/example included in this package), and \_\_init\_\_.py (which is an empty Python file but required for operation). 

You should designate a directory on your local drive to save .npy files as well as a location to save the final curated datasets. 

Operation and Use
------
The master curator function accepts (and requires) four arguments. The first should be the directory where videos for a session are located. The session can be broken into multiple trial arrays but all videos for a single trial array must be in that directory. The second argument is the trial array one wishes to curate. This is the base unit for autocuration and the autocurator currently does not accept curation of multiple trial arrays (even if their is a single video directory). The third argument is the contact array (ConTA) which should match the trial array supplied. An empty contact array can be created by calling the [trial contact browser](https://github.com/hireslab/HLab_MatlabTools/blob/master/trialContactBrowser.m) using the trial array as the only argument.

The fourth, and last argument is the job name. This is used in submitting a job to CloudML as well as in naming datasets. Google Cloud Services requires that each training job has a unique name in perpetuity. Thus, you can never re-use a training job name on the same Google account. You must call autocurator_master_function with a unique job name argument every time it reaches the CloudML section. The only exception is if you need to fix a problem in post-processing (see [Troubleshooting](https://github.com/jonathansy/whisker-autocurator/blob/master/Autocurator_Beta/README.md#troubleshooting) below).

The code is designed that errors in any given step does not require the repeat of previous steps. The current workflow is as follows:

SETTINGS: A place to set all static variables such as file paths and the CloudML region

STEP 1: The code will check that all input variables exist and load the trial array. 

STEP 2: Images will be pre-processed using distance-to-pole information in the trial array. Currently this process only designates non-touches. A separate 'curated' contact array will be created containing only touch/non-touch labels and trial number (this information will be kept separate from the empty and properly formated contact array for ease of access). Non-touches will be marked with a zero. Trials with no distance-to-pole information will have each point marked with a -1 (indicating impossibility of curation). Points which still need to be curated will be marked with a 2 (The 1 is reserved for future marking as a touch). The shorter contact list is the only variable returned. 

STEP 3: In this step, your videos are turned into images. This is currently the largest bottleneck step as it requires looping through every video and using FFMPEG to change them to .png files. MATLAB's built in 'imread.m' is unsuitable because several Hires Lab mp4s cannot be read by imread.m or most standard video players. They can currently only be read by VLC and FFMPEG (Whiski also works due to utilizing FFMPEG in reading videos). Unfortunately, FFMPEG lacks the ability to only convert specific frames. Thus, the entire video needs to be converted to .pngs regardless of whether those images are deemed unecessary by pre-processing. The images are written to temporary directories. After writing to .pngs, the pre-processing information is used to determine which images are relevant (e.g. the ones corresponding to thier points == 2). Relevant images are cropped to a 61x61 pixel image centered around the pole. Currently the pole location is determined using a matrix correlation with a sample image of the pole although this can be replaced by making the user click on an image. Relevant images are placed in a new permanent directory while irrelevant images are discarded along with the temporary directory. 

STEP 4: Images are converted into numpy arrays using a Python script. This conversion is necessary in order to use them in Tensorflow. One array is created per trial and stored in a .pickle file. The collection of .pickle files will be stored in a directory named (job name)_datasets_ which will be stored alongside the other directories of pole images. This step also uses gsutil to upload images onto the cloud. They will be uploaded into gs://my_bucket_name/Data.  

STEP 5: This step  submits a job to CloudML. Once this step is called, it cannot be called again with the same job name. This applied even to jobs which are denied for reasons of insufficient cloud resources. Note that it is only for this job (and for your bucket storage) that you will be charged. In addition to your actual Python script using Tensorflow, you must also supply a .yaml file specifying the environment (CPUs and GPUs) as well as a setup.py file specifying the Python packages needed in the runtime environment (Tensorflow, Keras, Numpy, etc.). The actual curation step is benchmarked at about 19.5 trials/minute when using an Nvidia Tesla K80. You will not be charged after your curation job finishes. Predictions will be placed in gs://my_bucket/Curated_Data unless otherwise specified. You will also need to supply a trained model for use in curation.  

STEP 6: Downloads your prediction data (still .pickle files organized by trial) from the cloud into a specified local directory.

STEP 7: Take the predictions, convert from .pickle files to .npy files using a Python script. Then a MATLAB script takes the final script and unpacks the predictions in the .npy files and fills in the formatted contact array using both those predictions and the ones generated in pre-processing. The cloud predictions come with a measure of confidence (categorical percentage) which can be used to help with further post-curation work if needed. The script is also set to default to Non-touch in the event that the neural network's guess is exactly 50:50. This reflects the networks tendency to bias towards false touch predictions. 



Troubleshooting
------
### Solutions to specific known errors:

1. "Resources are insufficient in region" >>> This logged error is caused when too many people are using the region you submit your job to. You can fix this by either attempting to find another suitable region or simply trying again at a later time. 

2. "Cannot find trial array / contact array" >>> Make sure you supply the path to your trial/contact array (as a string) for the program to work, rather than the object variable itself. 

3. "No module named numpy"/"No module named Scipy" >>> Caused by not installing the packages on Python. The autocurator is written with the assumption that you install packages to the base Python code using the pip installer. It does not support Anaconda or other environment software and installing packages only to an environment may cause this error to occur. 

4. "Expected one output from a curly brace or dot indexing expression, but there were 2 results." >>> Thus far this error appears to occur randomly within the videos_to_npy.m script. It cannot be replicated 100% of the time and the known solution is to simply run your code again (it will likely work). The error only occurs on the first iteration of the top level loop in videos_to_npy.m and thus will not interrupt your program in the middle of creating .npy files.  

### General troubleshooting instructions 

Due to the large amount of exact paths that need to be inputed into the code, typos or incorrect paths will likely cause a large amount of early errors when the autocurator is first transfered onto a new device. The autocurator_master_function is divided into sections, each of which is designed to save progress at each interval. For example, if the program errors in section 4 you will not have to re-run section 3 as the needed files have already been created and stored. The only exception is section 2, which outputs the pre-processed varaible 'contacts'. The 'contacts' variable is required for sections 3 and 7 and will thus have to be re-run.   
