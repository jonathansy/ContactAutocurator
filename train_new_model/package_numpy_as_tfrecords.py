import sys
import os
import numpy as np
import tensorflow as tf
import argparse


def numpy_to_tfrecords(np_location, records_name):
    records_name = records_name + '.tfrecords'
    print('Writing to ' + records_name)
    np_list = os.listdir(np_location)
    with tf.python_io.TFRecordWriter(records_name) as writer:
        for np_file in np_list:
            np_fname = os.path.basename(np_file)
            if np_fname[6:10] == 'Data':
                label_name = np_fname[0:5] + '_Labels' + np_fname[10:]
                np_labels = np.load(os.path.join(np_location, label_name))
                np_array = np.load(os.path.join(np_location,np_file))
                print('Converting ' + label_name)

                flat_im = np_array.flatten()
                flat_im = flat_im.tostring()
                labels = np_labels.flatten()
                labels = labels.astype(int)

                feature = {}
                feature['ximage'] = tf.train.Feature(bytes_list=tf.train.BytesList(value=[flat_im]))
                feature['ylabel'] = tf.train.Feature(int64_list=tf.train.Int64List(value=labels))

                combined = tf.train.Example(features=tf.train.Features(feature=feature))
                serialized = combined.SerializeToString()

                writer.write(serialized)


if __name__ == '__main__':
    # Argument section
    parser = argparse.ArgumentParser()
    # Directory location of numpy dataset files
    parser.add_argument('--numpy_file_path',
                        help='Full path to numpy datasets and labels',
                        required=True
                        )
    # Name to use for final datasets
    parser.add_argument('--name_dataset',
                        help='Full path to place to put models',
                        required=True
                        )
    args = vars(parser.parse_args())
    numpy_file_path = format(args["numpy_file_path"])
    name_dataset = format(args["name_dataset"])

    numpy_to_tfrecords(numpy_file_path, name_dataset)
