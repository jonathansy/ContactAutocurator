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
    batch_size = 2048
    img_rows = 61
    img_cols = 61
    epochs = 80
    input_shape = (img_rows, img_cols, 1)
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
                  optimizer=keras.optimizers.Adam())
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
            if batch_iteration == 1:
                x_train = load_image_data(np_file)
                x_train = x_train.reshape(x_train.shape[0], img_rows, img_cols, 1)
                np_labels = np_file[:-11] + 'labels.npy'
                y_train = load_image_labels(np_labels, num_classes)
            elif batch_iteration == 2:
                x_test = load_image_data(np_file)
                x_test = x_test.reshape(x_test.shape[0], img_rows, img_cols, 1)
                np_labels = np_file[:-11] + 'labels.npy'
                y_test = load_image_labels(np_labels, num_classes)
            elif batch_iteration % 4 == 0:
                x_test_new = load_image_data(np_file)
                x_test_new = x_test_new.reshape(x_test_new.shape[0], img_rows, img_cols, 1)
                x_test = np.concatenate((x_test, x_test_new), axis=0)
                np_labels = np_file[:-11] + 'labels.npy'
                y_test_new = load_image_labels(np_labels, num_classes)
                y_test = np.concatenate((y_test, y_test_new), axis=1)
            else:
                x_train_new = load_image_data(np_file)
                x_train_new = x_train_new.reshape(x_train_new.shape[0], img_rows, img_cols, 1)
                x_train = np.concatenate((x_train, x_train_new), axis=0)
                np_labels = np_file[:-11] + 'labels.npy'
                y_train_new = load_image_labels(np_labels, num_classes)
                y_train = np.concatenate((y_train, y_train_new), axis=1)

    # Reformat data

    x_train = x_train.astype('float32')
    x_train /= 255

    x_test = x_test.astype('float32')
    x_test /= 255
    # Reformat train labels
    y_train = np_utils.to_categorical(y_train, num_classes)
    f_shape = y_train.shape
    y_train = np.reshape(y_train, [f_shape[1], f_shape[2]])
    # Reformat test labels
    y_test = np_utils.to_categorical(y_test, num_classes)
    f_shape = y_test.shape
    y_test = np.reshape(y_test, [f_shape[1], f_shape[2]])

    # Train on batch
    model.fit(x_train, y_train,
              batch_size=batch_size,
              epochs=epochs,
              verbose=1,
              shuffle=True,
              validation_data=(x_test, y_test))
    out_message = 'Trained batch: ' + str(batch_iteration)
    logging.info(out_message)
    # Finished, now save
    save_model(model, export_dir, m_name)


def load_image_data(n_path):
    # Shape of images (temporarily hard-coded)
    # Parses through data on cloud and unpickles it
    # Import Data
    logging.info('Loading image data: ')
    logging.info(n_path)
    with file_io.FileIO(n_path, mode='rb') as n_file:
        i_data = np.load(n_file)
    # i_data = np.array(i_data, dtype=np.uint8)
    return i_data


def load_image_labels(label_path, class_num):
    # Import data
    with file_io.FileIO(label_path, mode='rb') as np_file:
        labels = np.load(np_file)
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
