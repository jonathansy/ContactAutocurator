% PREPROCESS_DATA(DATAOBJ) is designed to take a data object and perform 
% all preprocessing that does not require pole images. All relevant whisker
% tracking data you wish to use should be in dataObj. The output contacts
% will inform the autocurator whether or not to curate a frame (excluding 
% known frames can speed up autocuration). Preprocessing involving altering 
% images fed to the autocuration should happen in the VIDEOS_TO_NUMPY step 
function [preprocessedContacts] = preprocess_data(dataObj, processSettings)

%% DEFAULT SETTINGS
if nargin == 1
    processSettings.useDataPreprocessing = true;
    processSettings.useVelocity = true;
    processSettings.velocityCutoff = 0.05;
    processSettings.useAbsoluteDistance = true;
    processSettings.distanceCutoff = 2;
    processSettings.curateUntracked = true;
end
%% MAIN

numTrials = length(dataObj);
preprocessedContacts = cell(1);
preprocessedContacts{1}.labels = [];
preprocessedContacts{1}.trialNum = [];
preprocessedContacts{1}.video = [];
% Loop through trials and create contacts
for i = 1:numTrials
    % Check if we want to preprocess with data, if not, mark every frame as
    % good
    if processSettings.useDataPreprocessing == 0
        labels = zeros(1, dataObj{i}.numFrames);
        labels(:) = 2;
        preprocessedContacts{1}.labels = labels;
        preprocessedContacts{1}.trialNum = dataObj.trialNum;
        preprocessedContacts{1}.video = dataObj.video;
        continue
    end
    
    % Otherwise proceed with preprocessing 
    labels = zeros(1, dataObj{i}.numFrames);
    for j = 1:dataObj{i}.numFrames
        % Check if frame has usable distance-to-pole data (no lost 
        % tracking)
        if ismember(j,dataObj{i}.trackedFrames)
            dist = dataObj{i}.distance(dataObj{i}.trackedFrames == j);
        elseif processSettings.curateUntracked == 1
            labels(j) = 1; % Have autocurator find contacts in untracked
            % frames
            continue
        else
            labels(j) = -1; % Mark as un-curatable
            continue
        end
        
        if processSettings.useVelocity == 1
            % Velocity filter removes frames that can't be touches due to
            % impossibly high velocity
            if ismember(j-1,dataObj{i}.trackedFrames)
        end
        if processSettings.useAbsoluteDistance == 1
            % Distance filter removes frames that can't be touches due to
            % being too far away even accounting for the whisker tracker's
            % margin of error. 
        end
    end
    
    % Write trial data to temporary contacts
    preprocessedContacts{1}.trialNum = dataObj.trialNum;
    preprocessedContacts{1}.video = dataObj.video;
        
end
