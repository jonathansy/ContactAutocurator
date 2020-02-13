# Base imports
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
from keras.layers import ConvLSTM2D
from keras.layers import Activation, Dropout, Flatten, Dense
from keras.models import load_model
from keras.preprocessing.image import ImageDataGenerator
from keras import callbacks
from keras.callbacks import ProgbarLogger
from keras.callbacks import TensorBoard
from keras.layers.normalization import BatchNormalization
from keras import backend as K
from keras.utils import np_utils
import logging
from tensorflow.python.lib.io import file_io
import os, os.path

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

    model.add(ConvLSTM2D(filters=40,
                         kernel_size=(2, 2),
                         input_shape=input_shape,
                         padding='same',
                         return_sequences=True
                         dropout=0.5,
                         recurrent_dropout=0.5))
    model.add(BatchNormalization())

    model.add(ConvLSTM2D(filters=40,
                         kernel_size=(3, 3),
                         padding='same',
                         return_sequences=True
                         dropout=0.5,
                         recurrent_dropout=0.2))
    seq.add(BatchNormalization())

    model.add(ConvLSTM2D(filters=40,
                         kernel_size=(3, 3),
                         padding='same',
                         return_sequences=True
                         dropout=0.5,
                         recurrent_dropout=0.2))
    seq.add(BatchNormalization())

    model.add(AveragePooling3d((1,61,61)))
    model.add(Reshape((-1,40)))
    model.add(Dense(num_classes, activation='softmax'))

    model.compile(loss=keras.losses.categorical_crossentropy,
                  optimizer=keras.optimizers.Adam())
