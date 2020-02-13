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

