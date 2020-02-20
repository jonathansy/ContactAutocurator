% DYNAMIC SETTINGS

function [settings] = autocurator_config()
% Google Cloud Platform settings
  % Defaults
  settings.folder = 'C:\SuperUser\Documents\GitHub\whisker-autocurator\Autocurator_Beta';
  settings.behavTrialOffset = 0;
  % Version number is for CloudML, 1.8 seems to work fine
  settings.runVer = 1.8;
  % Model code gives location of python code that is actually uploaded to the cloud
  settings.modCode = 'trainer.cnn_curator_cloud';
  % The location of your model code on the local drive
  settings.modCodePath = '\Autocurator_Beta\trainer';
  % Path where the code you are currently running is
  settings.autocuratorPath = 'C:\Users\shires\Documents\GitHub\whisker_autocurator_labversion';
  % Data center in which to process data. us-west1 (Oregon) is closest but
 
  settings.region = 'us-east1';
  % Location of .yaml file used by Google Cloud for configuration settigns
  settings.configFile = 'C:\Users\shires\Documents\GitHub\whisker_autocurator_labversion\Autocurator_Beta\trainer\cloudml-gpu.yaml';
  % Model Path lists the location on the cloud where the training model is
  % stored including the model name
  settings.modelPath = 'gs://whisker-autocurator-data/Models/rotated_model_29.h5';%Adjusted_Curation_7.h5';
  % Place to save uncurated datasets
  settings.saveDir = 'C:\Users\shires\Documents\2019_Autocurator\Datasets';
  % Place to save curated datasets
  settings.newSaveDir = 'C:\Users\shires\Documents\2019_Autocurator\Curated_Datasets';

end
