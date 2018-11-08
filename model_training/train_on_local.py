# Trains using tensorflow on keras on a local drive, ideally using a GPU

import sys
import os
import h5py
import tensorflow as tf
import keras
import numpy as np
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


def main():
    # Train model
    new_model = build_model('estimator')
    new_model.train(input_fn=train_input_fn, steps=1024)
    # Save model
    new_model.save('JK_model_01.h5')


def train_input_fn():
    return input_fn()


def input_fn():
    # Settings
    data_target = 'C:\SuperUser\CNN_Projects\Model_v2\JK_Data_1.tfrecords'
    input_shape = (81, 81, 1)
    batch_size = 1024
    epochs = 80

    # Load training data
    batch_shape = tuple([batch_size] + list(input_shape))
    # Convert tfrecords file to tf.data
    training_dataset = tf.data.TFRecordDataset(filenames=data_target)
    training_dataset = training_dataset.map(parse)
    training_dataset = training_dataset.shuffle(buffer_size=2048)
    training_dataset = training_dataset.batch(batch_size)
    iterator = training_dataset.make_one_shot_iterator()
    print(training_dataset)
    print('Error is below')
    images_batch, labels_batch = iterator.get_next()
    x = {'ximage': images_batch}
    y = labels_batch

    return x, y


def build_model(model_type):
    if model_type == 'keras':
        # Build Model
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
        model.add(Dense(2, activation='softmax'))
        model.compile(loss=keras.losses.categorical_crossentropy,
                      metrics=['accuracy'],
                      optimizer=keras.optimizers.Adam())

        # Train using 30% of data for validation. Batch size of 1000-3000 appropriate
        # for current GPU
        model.fit(training_dataset,
                  batch_size=batch_size,
                  epochs=epochs,
                  initial_epoch=0,
                  verbose=1,
                  validation_split=0.3,
                  shuffle=False,
                  steps_per_epoch=None)

    elif model_type == 'estimator':
        # Build estimator
        feature_image = tf.feature_column.numeric_column("ximage",
                                                         shape=(81,81,1),
                                                         dtype=tf.float32)
        model = tf.estimator.DNNClassifier(feature_columns=[feature_image],
                                           hidden_units=[512, 256, 128],
                                           activation_fn=tf.nn.relu,
                                           n_classes=2,
                                           model_dir="C:/SuperUser/CNN_Projects/Model_v2/")
    return model


def parse(serialized):
    # Define a dict with the data-names and types we expect to
    # find in the TFRecords file.
    # It is a bit awkward that this needs to be specified again,
    # because it could have been written in the header of the
    # TFRecords file instead.
    features = \
        {
            'ximage': tf.FixedLenFeature([], tf.string),
            'ylabel': tf.FixedLenFeature([], tf.int64)
        }

    # Parse the serialized data so we get a dict with our data.
    parsed_example = tf.parse_single_example(serialized=serialized,
                                             features=features)

    # Get the image as raw bytes.
    image_raw = parsed_example['ximage']

    # Decode the raw bytes so it becomes a tensor with type.
    image = tf.decode_raw(image_raw, tf.uint8)

    # The type is now uint8 but we need it to be float.
    image = tf.cast(image, tf.float32)

    # Get the label associated with the image.
    label = parsed_example['ylabel']

    # The image and label
    return image, label


def build_tf_data(np_location):
    np_list = os.listdir(np_location)
    first_train = 1
    first_valid = 1
    main_dataset = []
    for np_file in np_list:
        np_path = os.path.join(np_location, np_file)
        np_array = np.load(np_path)
        np_fname = np_file
        if np_fname[6:10] == 'Data':
            label_name = np_fname[0:5] + '_Labels' + np_fname[10:]
            label_path = os.path.join(np_location, label_name)
            np_labels = np.load(label_path)
            np_labels = np_labels.T
            iter_dataset = tf.data.Dataset.from_tensor_slices((np_array, np_labels))
            # Check if training or validation set and assign accordingly
            if np_fname[0:5] == 'Train':
                if first_train == 1:
                    main_dataset = iter_dataset
                    first_train = 0
                    first_valid = 0
                else:
                    main_dataset = tf.data.Dataset.concatenate(main_dataset, iter_dataset)
            elif np_fname[0:5] == 'Valid':
                if first_valid == 1:
                    main_dataset = iter_dataset
                    first_valid = 0
                    first_train = 0
                else:
                    main_dataset = tf.data.Dataset.concatenate(main_dataset, iter_dataset)

    def map_fn(image, label):
        x = tf.reshape(tf.cast(image, tf.float32), input_shape)
        y = tf.one_hot(tf.cast(label, tf.uint8), 2)
        return x, y

    main_dataset = main_dataset.map(map_fn)
    main_dataset = main_dataset.batch(batch_size)
    main_dataset = main_dataset.repeat()

    return main_dataset


if __name__ == '__main__':
    main()
