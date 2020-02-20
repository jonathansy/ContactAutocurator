% AUTOCURATOR_MASTER_FUNCTION(VID_DIR, T, CONTACTARRAY, JOBNAME) takes an input of a directory of
% your videos, a T array, and an empty contact array, and attempts to automatically curate them frame by frame using a
% convolutional neural network specified in MODEL
function [contacts] = autocurator_master_function(videoDir, tArray, contactArray, jobName)
%% SECTION CONTROL             
JOB_NAME = 'OldPhil_688_20_1';
INPUT_DATA_FORMAT = 'distance';
% Debug section, set to 0 to skip
PIXEL_DETECTION =       1;
MAKE_NPY =              1;
UPLOAD =                1;
PROCESS =               1;
DOWNLOAD =              1;
PICKLE_TO_NPY =         1;
WRITE_CONTACTS =        1;
clearDir = 'N';

if nargin < 4
    jobName = JOB_NAME;
end

curateSet = autocurator_config();
cloudSet = cloud_config();

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
  jobDir = [curateSet.gcloudBucket '/Jobs'];
  dataBucket = [curateSet.dataBucket filesep '2019_Curation_Validation'];
  if exist(contactArray) == 2
    cArray = load(contactArray);
  end

  %% (2) Section for pre-processing images
  [contacts] = preprocess_pole_images(INPUT_DATA_FORMAT, tArray, curateSet.behavTrialOffset);

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
  npyDataPath = [curateSet.saveDir '/*.npy'];
  if UPLOAD == true
      gsutilUpCmd = sprintf('gsutil -m cp %s %s',...
          npyDataPath, dataBucket);
      system(gsutilUpCmd)
  end
  % Change project ID to avoid permission issues
  %changeProjCmd = ['gcloud set project

  %% (5) Call Python code to use neural network and train on Google Cloud
  cd(curateSet.folder)
  cd Autocurator_Beta
                     
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
        cloudSet.gcloudBucket,... % Location of files on cloud
        cloudSet.logDir,... % Place to store log files
        curateSet.runVer,... % Runtime version
        [curateSet.folder curateSet.modCodePath],... % Path to application package
        curateSet.modCode,... % Name of python module and directory in special dot notation
        cloudSet.region,... % Datacenter to use (see README)
        curateSet.configFile,... % Config file that requests GPU from cloud
        dataBucket,...
        curateSet.modelPath,... % Path to desired model (please upload new models to same path)
        jobName);
                     
                     
 if PROCESS == true
     system(gcloudCmd)
     pause(1200)
 end

  %% (6) Remove touch predictions from Google Cloud
  %gcloudBucket = 'gs://whisker_training_data';
  downloadName = [dataBucket '/*.pickle'];
                     
  gsutilDownCmd = sprintf('gsutil -m cp %s%s %s',...
                         gcloudBucket, downloadName, curateSet.newSaveDir);
                     
  if DOWNLOAD == true
      system(gsutilDownCmd)
  end

  %% (7) Convert to contact array (or fill in contact array in reverse)
  if PICKLE_TO_NPY == true
    system(['py retrieve_npy_labels.py --data_dir ' curateSet.newSaveDir]);
  end
  if WRITE_CONTACTS == true
    if strcmp(INPUT_DATA_FORMAT,'distance_WT')
        % Alternate version which writes to a contact array with only
        % contact info
        write_to_contact_mat(curateSet.newSaveDir, contacts, tArray);
    else
        write_to_contact_array(curateSet.newSaveDir, contacts, contactArray, tArray);
    end
  end

  %% (8) Finish 
  % Use to clear needed directories 
  %clearDir = input('Do you want to clear data directories? [Y/N] ', 's');
  
  % Clearing section below
  if strcmpi(clearDir, 'Y')
      system(['del /q ' curateSet.saveDir])
      system(['del /q ' curateSet.newSaveDir])
      system(['gsutil -m rm -rf ' dataBucket])
  end

