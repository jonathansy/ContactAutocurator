% Top level MATLAB script to generate a new model based on contact array
% training data.
% Create 2018-09-28 by J. Sy, derived from legacy scripts
jobName = 'Adjusted_Curation_7';

upload = 1;
%% Section 1: Setting inputs
% List and location of contact arrays with touch/no-touch labels
contactArrayDir = 'Z:\Users\Jonathan_Sy\JK_Pipeline\Unfininshed_ConTA';
contArrayList = {'ConTAJK037pre_(done)',...
                 'ConTA_JK025pre_(session_8)'};
             
% Cloud directories
dataBucket = 'gs://whisker-autocurator-data/Data/Better_Curation';

% List and location of trial arrays: each trial array must be
% placed in the same order on the list as its corresponding contact array
trialArrayDir = 'Z:\Users\Jonathan_Sy\JK_Pipeline\tArrays';
trialArrayList = {'JK037pre1_T',...
                  'JK025pre1_T'};

if length(contArrayList) ~= length(trialArrayList)
  error('Each contact array must have a matching trial array!')
end

% Location of video files: leave videoArrayList empty if the
% exact path can be determined from mouse and session name found in the trial
% array
videoDir = 'C:\Users\jonat\Documents\MATLAB\Transfer';
videoList = {'Y:\Whiskernas\JK\whisker\tracked\JK037pre1',...
             'Y:\Whiskernas\JK\whisker\tracked\JK025pre1'};

% Training settings
sizeROI = 61; % length/width of training image in pixels

% Transfer directory: the location where numpy arrays will be stored before
% being transfered to the cloud
transferDir = 'C:\Users\jonat\Documents\MATLAB\Transfer';

% Optional: supply list of contact arrays with relevant points indicated
useSubsetOfData = false; % Set to 'true' and the trainer will only use images
% and labels marked as touches in this second set of contact arrays. In the
% second set, a touch label is not actually meant to indicate a touch, but merely
% that the point should be curated. The first set of contact arrays will still
% be used for training labels.
if useSubsetOfData == true
  subContactArrayDir = 'C:\SuperUser\CNN_Projects\Model_v2\ConTA';
  subContArrayList = {};
end

%% Section 2: Loop through contact array and create dataset
% if 1 == 0
%     for i = 1:length(contArrayList)
%         contactArrayFullPath = [contactArrayDir filesep contArrayList{i}];
%         trialArrayFullPath = [trialArrayDir filesep trialArrayList{i}];
%         cArray = load(contactArrayFullPath);
%         cArray = cArray.contacts;
%         tArray = load(trialArrayFullPath);
%         %tArray = tArray.T;
%         tArray = tArray.arrayT;
%         % Find full video path
%         if isempty(videoList)
%             %mouse = tArray.mouseName;
%             %session = tArray.sessionName;
%             %vidPath = [videoDir filesep mouse filesep session];
%             vidPath = videoDir;
%         else
%             vidPath = videoList{i};
%         end
%         % Now call function to turn contact arrays into training, test, valid sets
%         create_training_data(tArray, cArray, sizeROI, vidPath, transferDir, i)
%     end
%     % Turn numpy datasets into tf.dataset format and concatenate together
%     dataCmd = ['py ' trainCodePath filesep 'create_main_dataset.py'];
    %system(dataCmd)
    
%end
%% Section 3: Upload dataset
% (3a) Uploads pickle files to Google cloud
npyDataPath = [transferDir '/*.npy'];
if upload == true
    gsutilUpCmd = sprintf('gsutil -m cp %s %s',...
        npyDataPath, dataBucket);
    %system(gsutilUpCmd)
end
% Change project ID to avoid permission issues
%changeProjCmd = ['gcloud set project

%% Section 4: Call Python code to train neural network and train on Google Cloud
% Cloud settings: determine different training factors. See Google Cloud
% documentation or read-me for more details
autocuratorPath = 'C:\Users\jonat\Documents\GitHub\ContactAutocurator';
trainCodePath = 'C:\Users\jonat\Documents\GitHub\ContactAutocurator\train_new_model';
gcloudBucket = 'gs://whisker-autocurator-data';
gcloudProjectID = 'whisker-autocurator';
runVer = 1.8;
modCode = 'cloud.train_cloud_model_numpy_v2';
modCodePath = 'cloud';
region = 'us-east1';
configFile = 'C:\Users\jonat\Documents\GitHub\ContactAutocurator\train_new_model\cloud\cloud_config_training.yaml';
dataBucket = [gcloudBucket '/Data/Better_Curation'];
jobDir = [gcloudBucket '/Logs'];
modelName = [jobName '.h5'];
exportPath = 'gs://whisker-autocurator-data/Models';
cd(autocuratorPath);
cd C:\Users\jonat\Documents\GitHub\ContactAutocurator\train_new_model

gcloudCmd = sprintf(['gcloud ai-platform jobs submit training %s ^'...
                      '--job-dir %s ^'...
                      '--runtime-version %.01f ^'...
                      '--module-name %s ^'...
                      '--package-path ./%s ^'...
                      '--region %s ^'...
                      '--config=%s ^'...
                      '-- ^'...
                      '--data_path %s '...
                      '--export_path %s '...
                      '--model_name %s '...
                      ], jobName, jobDir, runVer,...
                       modCode, modCodePath, region,...
                       configFile, dataBucket, exportPath,...
                       modelName);
system(gcloudCmd)
