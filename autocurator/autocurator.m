% Main code to use the autocurator on whisker data

%% PARAMETERS
videoDirectory = []; % Location of your video files
dataObject = []; % Path or variable name of data object, leave empty to build
dataTarget = []; % Directory of whisker files from tracker to build data object, leave blank if built
outputFileName = 'default_output.mat'; % Name to use when saving output file
processDirectory = []; % Directory to use when creating and processing numpy files (can be same as video directory)
cloudProcessDirectory = []; % Directory on cloud to transfer data to
model = 'General_Model_R3.h5'; % Name of desired model to use
modelROI = [81,81];
jobName = 'Job_1'; % Name of cloud job (must be different each time)
ffmpegDir = []; % Location of ffmpeg executables (specifically need ffprobe)

%% SECTION CONTROL
% Use this to turn sections on and off, good for debugging without
% re-running time-consuming sections. Note that the full autocuration
% pipeline requires running through each section at least once.
PREPROCESS =            1;
NUMPY_CONVERT =         1;
UPLOAD =                1;
PROCESS =               1;
DOWNLOAD =              1;
WRITE_CONTACTS =        1;
CLEAR_DIRECTORIES =     0;

%% Load base settings
% Extract out information about the location of various scripts
pathSettings = return_path_settings();
cloudSettings = cloud_config;

%% Input checks

%% Build data object (if needed)
% This is an optional section that will package your whisker tracker data
% together into a single object for ease of use.
if isempty(dataObject)
    dataObject = package_session(videoDirectory, dataTarget, ffmpegDir);
    % Save packaged files to avoid long reloading time
    packaged_filename = [processDirectory filesep 'Data_Package_' jobName];
    save(packaged_filename, 'dataObject');
else
    dataObject = load(dataObject);
    dataObject = dataObject.dataObject;
end

%% Preprocess data
% Use this section to preprocess data, especially useful for telling the
% autocurator to ignore certain frames that cannot possibly be contacts
if PREPROCESS == 1
    tempContacts = preprocess_data(dataObject);
end

%% Convert to numpy
% Each video in a session is converted to a numpy file storing relevant
% frames. This format is needed to be read into the python Tensorflow
% script
if NUMPY_CONVERT == 1
    videos_to_numpy(tempContacts, processDirectory, modelROI);
end

%% Upload to cloud
if UPLOAD == 1
    npyDataPath = [processDirectory '/*.npy'] ;
    % Uses gsutil command tool
    gsutilUpCmd = sprintf('gsutil -m cp %s %s',...
        npyDataPath, cloudProcessDirectory);
    system(gsutilUpCmd)
end

%% Process on cloud
% This script uses the training job submission script for Google's cloudML,
% although this is not a training job, the script is still effective for
% curating on the cloud and will not use cloud resources (i.e. your money)
% once the job is completed.
if PROCESS == 1
    gcloudCmd = sprintf(['gcloud ml-engine jobs submit training %s ^'...
        '--job-dir %s ^'...
        '--runtime-version %.01f ^'...
        '--module-name %s ^'...
        '--package-path ./%s ^'...
        '--region %s ^'...
        '--config=%s ^'...
        '-- ^'...
        '--cloud_data_path %s '...
        '--s_model_path %s '...
        '--job_name %s '],...
        jobName,...
        cloudSettings.logDir,... % Place to store log files
        cloudSettings.runVersion,... % Runtime version
        pathSettings.cloudCurationScript,... % Path to python script actually used on cloud
        [pathSettings.cloudCurationScript 'cnn_curator_cloud'],...
        cloudSettings.region,... % Datacenter to use (see README)
        pathSettings.curateConfigFile,... % Config file that requests GPU from cloud
        cloudProcessDirectory,...
        [cloudSettings.models '/' model],... % Path to desired model (please upload new models to same path)
        jobName);

    system(gcloudCmd)
    pause(1200) % gCloud doesn't have an automatic means of notifying
    % MATLAB when it is done, as a result, the best way to let the code run
    % automatically is to put in a pause command that exceeds the estimated
    % time needed by the cloud curation script. Unfortunately, this will
    % change based on the size of the dataset being curated, so
    % experimental benchmarking will be needed to determine appropriate
    % numbers

end

%% Download from cloud
% The files will be downloaded to the same directory but will have
% '_curated' appended to the name differentiate them.
if DOWNLOAD == 1
    downloadName = [cloudProcessDirectory '/curated/*.npy'];
    gsutilDownCmd = sprintf('gsutil -m cp %s%s %s',...
        gcloudBucket, downloadName, processDirectory);
    system(gsutilDownCmd)
end

%% Convert to output matrix
% Your contacts will be saved as a .mat file containing the contact points
% for each trial as well as the confidence percentage of the autocurators
% classification. This script can also be used for post-processing.
if WRITE_CONTACTS == 1
    outputMat = write_predictions_to_mat(tempContacts, processDirectory);
    save(outPutFileName, 'outputMat')
end

%% Clear directories
% Deletes the numpy files created by clearing processing directories.
% Please ensure no downstream errors occured before using this as
% re-running the code will be much faster without having to regenerate the
% numpy files.
if CLEAR_DIRECTORIES == 1
    system(['del /q ' processDir])
    system(['gsutil -m rm -rf ' cloudProcessDirectory])
end
