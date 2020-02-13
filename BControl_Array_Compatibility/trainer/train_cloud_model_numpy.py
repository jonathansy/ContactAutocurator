# New python code for numpy array input, for GCP use

# Base imports
from __future__ import print_function
import numpy as np
import argparse
import h5py
import tensorflow as tf
import time
from PIL import Image
import pickle
import keras
from keras.datasets import mnist
from keras.models import Sequential
from keras.layers import Dense, Dropout, Flatten
from keras.layers import Conv2D, MaxPooling2D
from keras.layers import Activation, Dropout, Flatten, Dense
from keras.models import load_model
from keras.preprocessing.image import ImageDataGenerator
from keras import callbacks
from keras.callbacks import ProgbarLogger
from keras.callbacks import TensorBoard
from keras import backend as K
from keras.utils import np_utils
import logging
from tensorflow.python.lib.io import file_io
import sys
import os, os.path

# Reset graph in case of re-runs
tf.reset_default_graph()


# Main function
def train_model(data_dir, export_dir, m_name):
    # Setup model --------------------------------------------------------------
    num_classes = 2
    max_batch_size = 1024
    input_shape = (61, 61, 1)
    logging.info('Setting up model')
    model = Sequential()

    model.add(Conv2D(32, (3, 3), padding='same',
                     input_shape=input_shape))
    model.add(Activation('relu'))
    model.add(Conv2D(32, (3, 3)))
    model.add(Activation('relu'))
    model.add(MaxPooling2D(pool_size=(2, 2)))
    model.add(Dropout(0.25))

    model.add(Conv2D(64, (3, 3), padding='same'))
    model.add(Activation('relu'))
    model.add(Conv2D(64, (3, 3)))
    model.add(Activation('relu'))
    model.add(MaxPooling2D(pool_size=(2, 2)))
    model.add(Dropout(0.25))

    model.add(Flatten())
    model.add(Dense(512))
    model.add(Activation('relu'))
    model.add(Dropout(0.5))
    model.add(Dense(num_classes, activation='softmax'))
    model.compile(loss=keras.losses.categorical_crossentropy,
                  metrics=['accuracy'],
                  optimizer=keras.optimizers.Adadelta())
    # End of actual model setup ------------------------------------------------

    # Train model by looping through batches
    search_loc = data_dir + '/*.npy'
    datasets = file_io.get_matching_files(search_loc)
    batch_iteration = 0
    for np_file in datasets:
        if np_file[-10:] == 'labels.npy':
            continue
        else:
            batch_iteration = batch_iteration + 1
            # Format and load training images
            x_train = load_image_data(np_file)
            # Format and load labels
            np_labels = np_file[:-11] + 'labels.npy'
            y_train = load_image_labels(np_labels, num_classes)
            # Determine batch size
            if x_train.shape[0] > max_batch_size:
                batch_size = max_batch_size
                epochs = 15
            else:
                batch_size = x_train.shape[0]
                epochs = 10
            # Set dummy validation data for first trial
            if batch_iteration == 1:
                # The first 10 trials will have dummy validation data really
                x_test = x_train
                y_test = y_train
            # Train 9/10 batches
            if batch_iteration % 10 != 0:
                # Train on batch
                model.fit(x_train, y_train,
                          batch_size=batch_size,
                          epochs=epochs,
                          verbose=1,
                          shuffle=True,
                          validation_data=(x_test, y_test))
                out_message = 'Trained batch: ' + str(batch_iteration)
                logging.info(out_message)
            else:
                # Evaluate every 10th batch
                x_test = x_train
                y_test = y_train
    save_model(model, export_dir, m_name)


def load_image_data(n_path):
    # Shape of images (temporarily hard-coded)
    img_rows = 61
    img_cols = 61
    # Parses through data on cloud and unpickles it
    # Import Data
    logging.info('Loading image data: ')
    logging.info(n_path)
    with file_io.FileIO(n_path, mode='rb') as n_file:
        i_data = np.load(n_file)
    # i_data = np.array(i_data, dtype=np.uint8)
    i_data = i_data.reshape(i_data.shape[0], img_rows, img_cols, 1)
    i_data = i_data.astype('float32')
    i_data /= 255
    return i_data


def load_image_labels(label_path, class_num):
    # Import data
    with file_io.FileIO(label_path, mode='rb') as np_file:
        labels = np.load(np_file)
    # Reformat data
    labels = np_utils.to_categorical(labels, class_num)
    f_shape = labels.shape
    labels = np.reshape(labels, [f_shape[1], f_shape[2]])
    return labels


def save_model(finished_model, save_path, save_name):
    # Check name
    if save_name[:-3] != '.h5':
        # Name as h5py file
        save_name = save_name + '.h5'

    # Saving section
    if save_path.startswith("gs://"):
        finished_model.save(save_name)
        with file_io.FileIO(save_name, mode='rb') as input_f:
            with file_io.FileIO(os.path.join(save_path, save_name), mode='w+') as output_f:
                output_f.write(input_f.read())
    else:
        finished_model.save(os.path.join(save_path, save_name))


if __name__ == '__main__':

    # Argument section
    parser = argparse.ArgumentParser()
    # Model path
    parser.add_argument('--data_path',
                        help='Full path to numpy datasets and labels',
                        required=True
                        )
    # Data path
    parser.add_argument('--export_path',
                        help='Full path to place to put models',
                        required=True
                        )
    # Model name
    parser.add_argument('--model_name',
                        help='what to name saved model',
                        required=True
                        )
    # Stuff for compatibility
    parser.add_argument('--job-dir',
                        help='GCS location to write checkpoints and export models',
                        required=True
                        )
    args = vars(parser.parse_args())
    data_path = format(args["data_path"])
    export_path = format(args["export_path"])
    model_name = format(args["model_name"])

    train_model(data_path, export_path, model_name)
