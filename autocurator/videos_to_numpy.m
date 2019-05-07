% VIDEOS_TO_NUMPY(TCONTACTS, DIRTOPROCESS, ROI) takes the videos indicated
% the preprocessed contact array in DIRTOPROCESS, ROI
function videos_to_numpy(tContacts, dirToProcess, roi)

% Main loop to process
numTrials = length(tContacts);
for i = 1:numTrials
    % Video information
    videoToFind = tContacts{i}.video;
    [~,videoName,~] = fileparts(videoToFind);
    frameIdx = find(tContacts{i}.labels == 1);
    % Load video
    trialVideo = mmread(videoToFind);
    nFrames = length(trialVideo.frames);
    % Loop through each frame of video
    finalMat = zeros(length(frameIdx),roi(1));
    finalMat = repmat(finalMat, 1, 1, roi(2));
    for j = 1:length(frameIdx)
        % Find valid frames
        cFrame = trialVideo.frames(frameIdx(j)).cdata(:,:,1);
        % Use bar positions to crop
        if frameIdx(j) > length(tContacts{i}.bar)
            % Not enough bar positions, use last valid one and hope it
            % works
            frameIdx(j) = length(tContacts{i}.bar);
        end
        xPos = round(tContacts{i}.bar(frameIdx(j),2));
        yPos = round(tContacts{i}.bar(frameIdx(j),3));
        poleBox = [xPos-floor(roi(1)/2), xPos + floor(roi(1)/2), yPos - floor(roi(2)/2), yPos + floor(roi(2)/2)];
        
        # Check if out of frame and correct
        [yDim, xDim] = size(cFrame);
        if poleBox(1) < 1
            poleBox(2) = poleBox(2) + (1 - poleBox(1));
            poleBox(1) = 1;
        end
        if poleBox(2) > xDim
            poleBox(1) = poleBox(1) - (poleBox(2)-yDim);
            poleBox(2) = yDim;
        end
        if poleBox(3) < 1
            poleBox(4) = poleBox(4) + (1 - poleBox(3));
            poleBox(3) = 1;
        end
        if poleBox(4) > yDim
            poleBox(3) = poleBox(3) - (poleBox(4)-yDim);
            poleBox(4) = yDim;
        end
            
        % Check if ROI exceeds edge of image and skip if so
        nFrameMat = cFrame((poleBox(3)):(poleBox(4)),(poleBox(1)):(poleBox(2)));
        nFrameMat = imadjust(nFrameMat);
        % Save frame in array
        finalMat(j,:,:) = nFrameMat;
    end
    % Save array as numpy file for autocurator
    saveVidName = [videoName '_' num2str(i) '.npy'];
    saveName = [dirToProcess filesep saveVidName];
    writeNPY(finalMat, saveName)
end

