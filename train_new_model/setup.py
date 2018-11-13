'''Cloud ML Engine package configuration'''
from setuptools import setup, find_packages

setup(name='trainer',
    version='1.0',
    packages=find_packages(),
    include_package_data=True,
    description='Whisker Autocuration keras model on Cloud ML Engine',
    author='Jonathan Sy',
    author_email='jonathbs@usc.edu',
    install_requires=[
        'keras',
        'h5py',
        'IPython',
        'Pillow',
        'numpy'],
    zip_safe=False)
