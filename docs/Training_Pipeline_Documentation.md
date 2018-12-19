# Model Training Pipeline

Unless you have a setup similar to the videos used to train the included models, you will likely find it necessary to train a new model for your data. Even if you do have a similar setup, you may wish to increase the accuracy or sophistication of the model as new updates to Tensorflow become available. Whatever the reason, the model training pipeline is meant to provide an easy route through MATLAB to create new Tensorflow models for your dataset. 

## Control Code
Like the autocurator pipeline, there is a single script to set training parameters and call other functions in the pipeline. This script is [train_new_model.m](). The training script provides different options for how to feed a new dataset into Tensorflow to train a model. You will of course, need to label your data and the script provides several options to do so. 
* You can feed in a set of videos along with a MATLAB array containing contact labels
* You can use two directories (corresponding to class names) with sets of images placed in the directory corresponding to their labels
* You can bypass the whole MATLAB labeling step and create your own numpy arrays for both images and labels

The preferred pipeline will depend on your method of labeling data. However, regardless of your choice, the data will ultimately end up in numpy arrays that are fed into Tensorflow (using the Keras API). Code is included in the 'tools' directory for conversion to a tfrecord file if you wish to train new models that way, however feeding in batches of numpy arrays has proven sufficient in the past without the extra conversion step. 

## Model Python Code

There will be two iterations of Python code to train a new model. [train_model_cloud.py]() and [train_model_local.py](). Both construct model the same way, using the Keras API on top of Tensorflow. The key differences being, of course, optimizations for use on the cloud. In particular, Google Cloud Platform requires the ```file_io``` and ```logging``` modules to read and write files from a cloud storage bucket and print messages to the log files.

Keras's sequential model is used in both scripts. A simple example is as follows:

```python
    model = Sequential()

    model.add(Conv2D(32, (3, 3), padding='same',
                     input_shape=input_shape))
    model.add(Activation('relu'))
    model.add(Conv2D(32, (3, 3)))
    model.add(Activation('relu'))
    model.add(MaxPooling2D(pool_size=(2, 2)))
    model.add(Dropout(0.25))

    model.add(Flatten())
    model.add(Dense(512))
    model.add(Activation('relu'))
    model.add(Dropout(0.4))
    model.add(Dense(num_classes, activation='softmax'))
    model.compile(loss=keras.losses.categorical_crossentropy,
                  metrics=['accuracy'],
                  optimizer=keras.optimizers.Adam())
```

Detailed information about each layer can be found in the [Keras documentation](https://keras.io/). This is the only section of code where the design of the model itself is changed. All other sections handle the input and output pipelines. Even after the model is created, it will not begin to be trained until you call:
```python
model.fit(x_train, y_train,
          batch_size=batch_size,
          epochs=num_epochs,
          verbose=1,
          shuffle=True,
          validation_data=(x_test, y_test))
```
(Note: there are other methods of fitting a model that are explained in the Keras documentation)

Thus, any reshaping of model inputs needs to happen before calling 'model.fit' but can happen after the model is compiled. 

The model can be saved by calling 'model.save' although when on the cloud, one will need to remember to use the file_io package to save it to the cloud storage bucket. The scripts are designed to save models as .h5 files. If you wish to save your model under different filetypes, remember to change the curation script as well (since it looks for .h5 files by default). 

## Assembling Training Data
Training a new model will require curating videos frames by some other method, typically through human judgement. The video frames should ideally be turned into some sort of number array with matching labels used by class number. An alternative is to save each frame as a jpeg, png, or tiff file which can then be placed into a directory containing the class label. Note that saving each frame as its own separate image can substantially increase the time it takes to create a training set. 

The ContactAutocurator code includes a method of turning your videos into arrays and preprocessing them for training, however you must be able to provide an array which contains labels for every frame of the video (or provide a method of excluding frames which should not go into the training set or which were uncuratable). 

## Preprocessing
Dataset preprocessing in training is arguably even more important than in autocuration as it can have a major effect in the accuracy of the resulting model as well as whether the model will be biased towards different types of data. For example, one of the pre-trained models provided randomly rotates the training image by a multiple of 90°. This ensures that the model is generalizable regardless of which side of the image the mouse whisker and pole come from (meaning rotating the camera will not affect the model). If there are multiple objects or shapes being contacted, you will need to make sure they are all appropriately represented in your training dataset.  

## Troubleshooting
### Programming Error Troubleshooting
The following are common errors which can occur during the training pipeline:
* "Cannot find project"
* "Insufficient resources in region"
* "Image out of frame"
* "Cannot find numpy arrays"
* Model did not save 

### Inaccurate Model Troubleshooting
This section is meant to offer suggestions for models which train to completion without error but do not traing properly. This normally takes one of two forms:
> Underfitting: where neither the training nor the validation data is accurately predicted the model
> Overfitting: predicts training data accurately but cannot generalize to the validation data 

Both error types can also include issues where the model is reasonably accurate (better than random chance) but not good enough for the desired task. 

There are two basic ways to fix underfitting, changing the training data or adding more layers to the model. Underfitting has been observed experimentally with training datasets of limited size (The ContactAutocurator failed to train a new model off of 1000 frames of data). Adding more training data will provide the model with more examples to work with. Adding more layers (convolutional or deep) to the model is a rather crude way of solving issues, but it has proven effective and is a recommended approach so long as your model does not begin overfitting. Underfitting can also occur do to an insufficient number of epochs to fit the training data. ContactAutocurator defaults to 100 epochs but the appropraitely number will very depending on the amount of training data and the complexity of the model needed.

Models which are overfitting (for example, 99% accuracy on the training set, 52% accuracy on the validation set) can do so for a variety of reasons. If your training data is either too small or too similar, the model can "memorize" the training data but not actually learn the relevant features for predicting contacts. This can sometimes be fixed by increasing the variety of the training data, making it more representative of a typical sample and increasing the odds that the model learns generalizable features rather than just memorizing the images. Overfitting can also be caused by the creation of an overly complex model with too many layers. This can be remedied by decreasing the number of layers or increasing the dropout associated with each layer (see Tensorflow and Keras documentation for more information). 

Properly assessing both underfitting and overfitting requires that both the training and validation set accurately represent all general types of images that need to be sorted into certain classes. One must also be aware of discrepancies between class sizes which can cause the model to ignore one particular class. There are various means of dealing with these discrepancies with the easiest being to increase the proportion of the underepresented class in the training data. More sophisticated methods can also be used but are beyond the scope of this guide.





