# Base imports

import sys
import os
import logging
import numpy as np
import argparse
import h5py
import tensorflow as tf
import time
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
from tensorflow.python.lib.io import file_io


# Reset graph in case of re-runs
tf.reset_default_graph()


def train_model(data_dir, export_dir, m_name):
    # Setup model --------------------------------------------------------------
    num_classes = 2
    batch_size = 2048
    img_rows = 81
    img_cols = 81
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

    # Unpack tf records file to dataset API
    # reader = tf.TFRecordReader()
    dataset = tf.data.TFRecordDataset([data_dir])
    logging.info(dataset.output_shapes)

    # Use parse function test
    dataset = dataset.map(parse_fun)

    # Shuffle and split data
    dataset = dataset.shuffle(buffer_size=20000)
    val_size = 30000  # Stupid workaround until proper splitting method found
    valid_dataset = dataset.take(val_size)
    train_dataset = dataset.skip(val_size)

    # Batches for gpu
    valid_dataset = valid_dataset.batch(batch_size)
    train_dataset = train_dataset.batch(batch_size)

    # Create iterator
    valid_iterator = valid_dataset.make_one_shot_iterator()
    train_iterator = train_dataset.make_one_shot_iterator()

    # Train
    model.fit(dataset,
              epochs=epochs,
              steps_per_epoch=30,
              validation_data=valid_dataset,
              validation_steps=3)


def parse_fun(record_data):
    #
    features = \
    {
        'ximage': tf.FixedLenFeature([],tf.string),
        'ylabel': tf.FixedLenFeature([],tf.int64)
    }

    parsed_example = tf.parse_single_example(serialized=record_data,
                                             features=features)
    logging.info(parsed_example['ximage'].get_shape())
    return parsed_example['ximage'], parsed_example['ylabel']


if __name__ == '__main__':

    # Argument section
    parser = argparse.ArgumentParser()
    # Model path
    parser.add_argument('--data_path',
                        help='Full path to tf records file',
                        required=True
                        )
    # Data path
    parser.add_argument('--export_path',
                        help='Full path of place to put models',
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
