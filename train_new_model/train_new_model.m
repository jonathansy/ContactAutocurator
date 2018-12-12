% Main code to train a new model for the autocurator
% Created 2018-12-12 by J. Sy

%% Parameters
dataPath = []; % Location of training data, whether full videos or images
labelPath = []; % Full path to file containing training labels (leave blank if images are in directories by class)
processDirectory = []; % Directory to use when creating and processing numpy files
modelName = []; % What to call your new model
classNames = {'Touch',...
              'NonTouch'}; % What to name your class
labelOptions = {'labelsInFile','directoryClasses','numpy'}
labelOptionSelect = 1;
trainOnCloud = true;
jobName = 'Training_001';

%% Section Control
% Like the autocurator code, this allows you to disable
% certain sections for debugging and easier re-runs
CREATE_NUMPY =          1;
UPLOAD =                1;
TRAIN =                 1;
DOWNLOAD_MODEL =        0;
CLEAR_DIRECTORIES =     0;

%% Load base settings
pathSettings = return_path_settings();
cloudSettings = cloud_config;
labelSelection = labelOptions{labelOptionSelect};

%% Create numpy array from training data
if CREATE_NUMPY == 1
  switch labelSelection
  case 'labelsInFile'
    % Search for a file containing
  case 'directoryClasses'
    %
  case 'numpy'
    % Skip this entire section
  otherwise
    error('The training data option you selected does not exist')
  end
end

%% Upload to cloud
if UPLOAD == 1 && trainOnCloud == 1
  npyDataPath = [processDirectory '/*.npy'] ;
  % Uses gsutil command tool
  gsutilUpCmd = sprintf('gsutil -m cp %s %s',...
    npyDataPath, cloudProcessDirectory);
  system(gsutilUpCmd)
end

%% Train new model
if TRAIN == 1 && trainOnCloud == 1
  % Train on cloud ML
elseif TRAIN == 1 && trainOnCloud == 0
  % Train on local 
end

%% Download_model

%% Clear directories
