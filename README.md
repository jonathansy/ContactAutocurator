# ContactAutocurator
Code to train and deploy neural network models to curate whisker touch data

[![Hires Lab](https://github.com/jonathansy/whisker-autocurator/blob/master/Resources/Images/HiresLab-logoM.png)](http://68.181.113.239:8080//hireslabwiki/index.php?title=Main_Page)

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)

## Introduction

## Installation 
------
In addition to all the scripts in this repository, you will also require a working Google Cloud Services account. Curation can be done using either a VM or CloudML, but these scripts have been optimized for Cloud ML. Additionally, you will require a functional trial array and an empty contact array for your data. These can be created using software found in the Hires Lab repository [HLab_MatlabTools](https://github.com/hireslab/HLab_MatlabTools). The scripts in [HLab_Whiskers](https://github.com/hireslab/HLab_Whiskers) will also need to be added to the MATLAB path to instantiate the trial arrays. 

Clone or download the scripts in this directory as well as the HLab dependencies and add both to the path. Currently the trial contact browser in HLab_Matlabtools is backwards compatible to MATLAB 2013b. The autocurator scripts in here may be compatible with older versions but have not been tested as such. 

### Dependencies
* [Python 3.5 or higher](https://www.python.org/downloads/) (compatibility not tested with 2.7)  
  - Numpy package  
  - Pickle package  
  - Scipy package
* [Google Cloud SDK package](https://cloud.google.com/sdk/)
* MATLAB r2013b or later
  - [npy-matlab](https://github.com/kwikteam/npy-matlab)
* Google Cloud Platform Account



### Recommended
* [Janelia Farm Whisker Tracker](https://wiki.janelia.org/wiki/display/MyersLab/Whisker+Tracking+Downloads) (all distance-to-pole preprocessing assumes you have it)

* MATLAB Packages (for Hires Lab)
  - [HLab_MatlabTools](https://github.com/hireslab/HLab_MatlabTools)  
  - [HLab_Whiskers](https://github.com/hireslab/HLab_Whiskers)



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
