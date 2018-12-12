# Model Training Pipeline

Unless you have a setup similar to the videos used to train the included models, you will likely find it necessary to train a new model for your data. Even if you do have a similar setup, you may wish to increase the accuracy or sophistication of the model as new updates to Tensorflow become available. Whatever the reason, the model training pipeline is meant to provide an easy route through MATLAB to create new Tensorflow models for your dataset. 

## Control Code
Like the autocurator pipeline, there is a single script to set training parameters and call other functions in the pipeline. This script is [train_new_model.m](). The training script provides different options for how to feed a new dataset into Tensorflow to train a model. You will of course, need to label your data and the script provides several options to do so. 
* You can feed in a set of videos along with a MATLAB array containing contact labels
* You can use two directories (corresponding to class names) with sets of images placed in the directory corresponding to their labels
* You can bypass the whole MATLAB labeling step and create your own numpy arrays for both images and labels

The preferred pipeline will depend on your method of labeling data. However, regardless of your choice, the data will ultimately end up in numpy arrays that are fed into Tensorflow (using the Keras API). Code is included in the 'tools' directory for conversion to a tfrecord file if you wish to train new models that way, however feeding in batches of numpy arrays has proven sufficient in the past without the extra conversion step. 

## Model Python Code

