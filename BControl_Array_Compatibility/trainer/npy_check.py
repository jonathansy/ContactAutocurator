import sys
import os
import numpy as np
import pickle
import scipy.misc
import tensorflow
from keras.utils import np_utils

target = 'AH0698x170601-3_labels.npy'
path = 'C:/SuperUser/CNN_Projects/Phil_Dataset/SavingDir/'
fullpath = path + target
X = np.load(fullpath)
print(X.shape)
A = X
print(A.shape)
B = np.concatenate((X, A), axis=1)
print(B.shape)

# a = X[0,1]
# # scipy.misc.imsave('C:/SuperUser/CNN_Projects/outfile1.jpg', a)
# a = np_utils.to_categorical(X, 2)
# print(a.shape)
# b = a.shape
# a = np.reshape(a, [b[1], b[2]])
# X = np.reshape(X, [230, 61, 61, 1])

#print(target[-10:])

# A = np.random.rand(2,3,3)
# B = np.random.rand(1,3,3)
# print(A.shape)
# print(B.shape)
#
# A = np.concatenate((A,B), axis=0)
# print(A)
# print(A.shape)