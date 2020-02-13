import sys
import os
import h5py
import tensorflow as tf
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


# Check GPU functionality
print(device_lib.list_local_devices())

# Build model
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

# Data generators
train_datagen = ImageDataGenerator(rescale=1./255)
test_datagen = ImageDataGenerator(rescale=1./255)

train_generator = train_datagen.flow_from_directory(
                                                    'data/train',
                                                    target_size=(81,81),
                                                    batch_size = 1000,
                                                    class_mode='binary')
valid_generator = test_datagen.flow_from_directory(
                                                    'data/valid',
                                                    target_size=(81,81),
                                                    batch_size = 500,
                                                    class_mode='binary')

model.fit_generator(
                    train_generator,
                    steps_per_epoch=1000,
                    epochs = 80,
                    validation_data= valid_generator,
                    validation_steps=500)

model.save('1000F_model_01.h5')
