% WRAP_LEGACY_TRAINING_DATA(TRIALARRAY, CONTACTARRAY, VIDEODIR) takes old 
% trial and contact arrays used by the Hires Lab and wraps them together 
% into a compatible input data format fpr ContactAutocurator. Do not use 
% this code unless you have data in this legacy format. TRIALARRAY and 
% CONTACTARRAY must either be a trial and contact array or a path to those 
% respective arrays. VIDEODIR must be path to the directory containing the
% videos of the labeled trials to be used as training data. 

% Created: 2018-11-08 by J. Sy
% Last updated: 2018-11-08 by J. Sy
function [trainingArray] = wrap_legacy_training_data(trialArray, contactArray, videoDir)

% Accept trial array as either array or path to array
if exist(trialArray) == 2
    tArray = load(trialArray);
    tArray = tArray.T;
elseif strcmpi(class(trialArray),'LCA.TrialArray')
    tArray = trialArray;
else
    error('Invalid trial array input')
end
% Accept contact array as either array or path to array
if exist(contactArray) == 2
    contacts = load(trialArray);
    contacts = contacts.contacts;
elseif iscell(contactArray)
    contacts = contactArray;
else
    error('Invalid contact array input')
end
% Check if videodir exists
if exist(videoDir) ~=7
    error('Cannot find video directory')
end

% Create empty training array
trainingArray.meta = [];
trainingArray.trials = cell(1, length(contacts));
% Fill in metadata
trainingArray.meta.numberOfTrials = length(contacts);
trainingArray.meta.cropDimensions = [81 81]; % Size to crop image to for 
% training purposes, 81x81 is the default and can be changed in the 
% preprocessing of the training code. 


% Loop through contact array and write data to trainingArray
iterator = 1;
for i = 1:length(contacts)
    % See if contacts and T array load
    try
        conIdx = contacts{i}.contactInds{1};
        distance = tArray.trials{i}.whiskerTrial.distanceToPoleCenter;
    catch
        continue
    end
    % Check video path for trial
    videoName = tArray.trials{i}.trackerFileName;
    fullVidPath = [videoDir filesep videoName];
    if ~exist(fullVidPath)
        continue
    end
    
    % Begin repackaging trial data
    trainingArray.trials{iterator}.distanceToPole = distance;
    trainingArray.trials{iterator}.touchFrames = conIdx;
    trainingArray.trials{iterator}.startFrame = tArray.trials{i}.pinDescentOnsetTime;
    trainingArray.trials{iterator}.stopFrame = tArray.trials{i}.pinAscentOnsetTime;
    trainingArray.trials{iterator}.videoPath = fullVidPath;
    
end

