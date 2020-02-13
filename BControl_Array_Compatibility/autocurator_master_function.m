% AUTOCURATOR_MASTER_FUNCTION(VID_DIR, T, CONTACTARRAY, JOBNAME) takes an input of a directory of
% your videos, a T array, and an empty contact array, and attempts to automatically curate them frame by frame using a
% convolutional neural network specified in MODEL
function [contacts] = autocurator_master_function(videoDir, tArray, contactArray, jobName)
%% SECTION CONTROL             
JOB_NAME = 'OldPhil_688_20_1';
INPUT_DATA_FORMAT = 'distance';
PIXEL_DETECTION =       0;
MAKE_NPY =              0;
UPLOAD =                0;
PROCESS =               0;
DOWNLOAD =              0;
PICKLE_TO_NPY =         0;
WRITE_CONTACTS =        1;
clearDir = 'N';

%% SETTINGS
  % Defaults
  BEHAV_TRIAL_OFFSET = 0;
  % Bucket is Google Cloud storage location of data, url will begin with 'gs://'
  gcloudBucket = 'gs://whisker-autocurator-data';
  % Project ID name
  gcloudProjectID = 'whisker-personal-autocurator';
  % Version number is for CloudML, 1.8 seems to work fine
  runVer = 1.8;
  % Model code gives location of python code that is actually uploaded to the cloud
  modCode = 'trainer.cnn_curator_cloud';
  % The location of your model code on the local drive
  modCodePath = 'trainer';
  % Path where the code you are currently running is
  autocuratorPath = 'C:\Users\shires\Documents\GitHub\whisker_autocurator_labversion';
  % Data center in which to process data. us-west1 (Oregon) is closest but
  % us-central1 (Iowa) or us-east1 (South Carolina) is required to use TPUs and best GPUs
  region = 'us-east1';
  % Location of .yaml file used by Google Cloud for configuration settigns
  configFile = 'C:\Users\shires\Documents\GitHub\whisker_autocurator_labversion\Autocurator_Beta\trainer\cloudml-gpu.yaml';
  % Model Path lists the location on the cloud where the training model is
  % stored including the model name
   modelPath = 'gs://whisker-autocurator-data/Models/rotated_model_29.h5';%Adjusted_Curation_7.h5';
  % Place to save uncurated datasets
  saveDir = 'C:\Users\shires\Documents\2019_Autocurator\Datasets';
  % Place to save curated datasets
  newSaveDir = 'C:\Users\shires\Documents\2019_Autocurator\Curated_Datasets';
  if nargin < 4
    jobName = JOB_NAME;
  end

  %% (1) Input checks and base variables
%   if exist(model) ~= 2
%     error(['Input for "MODEL" should be the full path of the h5 file \n'...
%     'containing the training model'])
%   if exist(videoDir) ~= 7
%     error('Cannot find the image directory specified')
%   end
  if exist(tArray) ~= 2 && exist(tArray) ~= 7
    error('Cannot find trial array, remember to supply full path!')
  end

  if exist('jobName') == false
    jobName = input('What would you like to call this training job? \n');
  end

  %Derived settings
  jobDir = [gcloudBucket '/Jobs'];
  dataBucket = [gcloudBucket '/Data/2019_Curation_Validation'];
  if exist(contactArray) == 2
    cArray = load(contactArray);
  end

  %% (2) Section for pre-processing images
  [contacts] = preprocess_pole_images(INPUT_DATA_FORMAT, tArray, BEHAV_TRIAL_OFFSET);

  %% (3) Turn directory into images
  % Take the videos supplied in the video directory and use them to create
  % batches of .png images that can be analyzed by the model
  if PIXEL_DETECTION == true
      system(['mkdir ' saveDir])
      if strcmp(INPUT_DATA_FORMAT, 'distance_WT');
          contacts = videos_to_npy_alt(contacts, videoDir, saveDir, MAKE_NPY);
      else
        contacts = videos_to_npy(contacts, videoDir, saveDir, MAKE_NPY);
      end
  end

  %% (4) Move to cloud
  % Uploads pickle files to Google cloud
  npyDataPath = [saveDir '/*.npy'];
  if UPLOAD == true
      gsutilUpCmd = sprintf('gsutil -m cp %s %s',...
          npyDataPath, dataBucket);
      system(gsutilUpCmd)
  end
  % Change project ID to avoid permission issues
  %changeProjCmd = ['gcloud set project

  %% (5a) Call Python code to use neural network and train on Google Cloud
  cd(autocuratorPath);
  cd Autocurator_Beta

%   gcloudCmd = sprintf(['gcloud ml-engine jobs submit training %s ^'...
%                         '--job-dir %s ^'...
%                         '--runtime-version %.01f ^'...
%                         '--module-name %s ^'...
%                         '--package-path ./%s ^'...
%                         '--region %s ^'...
%                         '--config=%s ^'...
%                         '-- ^'...
%                         '--cloud_data_path %s '...
%                         '--s_model_path %s '...
%                         '--job_name %s '...
%                         ], jobName, jobDir, runVer,...
%                          modCode, modCodePath, region,...
%                          configFile, dataBucket, modelPath,...
%                          jobName);
                     
    gcloudCmd = sprintf([...
        'gcloud ml-engine jobs submit training %s ^'...
        '--staging-bucket %s ^'...
        '--job-dir %s ^'...
        '--runtime-version %.01f ^'...
        '--package-path %s ^'...
        '--module-name %s ^'...
        '--region %s ^'...
        '--config=%s ^'...
        '-- ^'...
        '--cloud_data_path %s '...
        '--s_model_path %s '...
        '--job_name %s '],...
        jobName,...
        gcloudBucket,... % Location of files on cloud
        jobDir,... % Place to store log files
        runVer,... % Runtime version
        [autocuratorPath '\Autocurator_Beta\trainer'],... % Path to application package
        ['trainer.cnn_curator_cloud'],... % Name of python module and directory in special dot notation
        region,... % Datacenter to use (see README)
        configFile,... % Config file that requests GPU from cloud
        dataBucket,...
        modelPath,... % Path to desired model (please upload new models to same path)
        jobName);
                     
                     
 if PROCESS == true
     system(gcloudCmd)
     pause(1200)
 end

  %% (5b) Call Python code to use neural network and train on local computer
  % with a GPU (Lol, like we'll get a GPU)
  % {This section left unfinished until such time as the lab acquires
  % a GPU for neural network purposes}

  %% (6) Remove touch predictions from Google Cloud
  %gcloudBucket = 'gs://whisker_training_data';
  downloadName = ['/Data/2019_Curation_Validation/*.pickle'];
%   gsutilDownCmd = sprintf('gsutil -m cp %s%s %s',...
%                          gcloudBucket, downloadName, newSaveDir);
                     
  gsutilDownCmd = sprintf('gsutil -m cp %s%s %s',...
                         gcloudBucket, downloadName, newSaveDir);
                     
  if DOWNLOAD == true
      system(gsutilDownCmd)
  end

  %% (7) Convert to contact array (or fill in contact array in reverse)
  if PICKLE_TO_NPY == true
    system(['py retrieve_npy_labels.py --data_dir ' newSaveDir]);
  end
  if WRITE_CONTACTS == true
    if strcmp(INPUT_DATA_FORMAT,'distance_WT')
        % Alternate version which writes to a contact array with only
        % contact info
        write_to_contact_mat(newSaveDir, contacts, tArray);
    else
        write_to_contact_array(newSaveDir, contacts, contactArray, tArray);
    end
  end

  %% (8) Finish 
  % Use to clear needed directories 
  %clearDir = input('Do you want to clear data directories? [Y/N] ', 's');
  
  % Clearing section below
  if strcmpi(clearDir, 'Y')
      system(['del /q ' saveDir])
      system(['del /q ' newSaveDir])
      system(['gsutil -m rm -rf ' dataBucket])
  end

