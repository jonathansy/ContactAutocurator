% CREATE_TRAINING_DATA(TARRAY, CARRAY, SIZEROI, TRANSFERDIR) creates numpy
% datasets in TRANSFERDIR using training data based on labels in CARRAY and
% images of size SIZEROI located in VIDPATH.
function create_training_data(tArray, cArray, sizeROI, vidPath, transferDir, metaIter)
  bitSize = 8;
  maxRamGB = 1;
  % Derived variables
  %framesPerSet = round(maxRamGB*(1024^3))/(2*bitSize*sizeROI*sizeROI);
  framesPerSet = 2048;
  numTrials = length(cArray);
  roiRadius = round((sizeROI-1)/2);

  % Prep trial loop
  mainIter = 1;
  trainSetIter = 1;
  testSetIter = 1;
  validSetIter = 1;
  maxDataset = [];
  maxLabels = [];

  for i = 1:200
    % Find indices of frames we need to curate
    try
        labels = cArray{i}.contactInds{1};
    catch
        continue
    end
    % Skip trial if no touches
    if isempty(labels)
      continue
    end
    % Find name of corresponding video, skip if no name
    try
      videoName = tArray.trials{i}.whiskerTrial.trackerFileName;
    catch
      continue
    end
    % Check full video path, skip if video doesn't exist
    fullVideoPath = [vidPath filesep videoName];
    if ~exist(fullVideoPath)
      continue
    end

    % Load with mmread
    videoArray = mmread(fullVideoPath);

    % Prep loop
    poleStartTime = round(tArray.trials{i}.pinDescentOnsetTime);
    poleStopTime = round(tArray.trials{i}.pinAscentOnsetTime);
    barOffset = find(isnan(tArray.trials{i}.whiskerTrial.distanceToPoleCenter{1}) == 0, 1, 'first');
    % Make sure pole stop time doesn't exceed video or bars
    if poleStopTime > length(videoArray.frames)
        poleStopTime = length(videoArray.frames);
    end
    if poleStopTime > length(tArray.trials{i}.whiskerTrial.barPos) + barOffset
        poleStopTime = length(tArray.trials{i}.whiskerTrial.barPos) + barOffset;
    end
    numFrames = poleStopTime - poleStartTime;
    finalMat = zeros(numFrames,sizeROI);
    finalMat = repmat(finalMat, 1, 1, sizeROI);
    cutMat = zeros(1, numFrames);
    newLabels = zeros(1, numFrames);

    for j = 1:numFrames
        % Determine pole position
        timePos = j + poleStartTime - 1;
        idx = timePos - barOffset;
        xPole = round(tArray.trials{i}.whiskerTrial.barPos(idx,2));
        yPole = round(tArray.trials{i}.whiskerTrial.barPos(idx,3));
        
        
        % Check touch or no touch and write labels
        if ismember(timePos, cArray{i}.contactInds{1})
            newLabels(j) = 1; % Mark as touch
            % --Repeated in both sections -------------------------------------
            curFrame = videoArray.frames(timePos).cdata(:,:,1);
            poleBox = [xPole-roiRadius, xPole + roiRadius, yPole - roiRadius, yPole + roiRadius];
            % Check if ROI exceeds edge of image and skip if so
            nFrameMat = curFrame((poleBox(3)):(poleBox(4)),(poleBox(1)):(poleBox(2)));
            nFrameMat = imadjust(nFrameMat);
            % Save Frame
            finalMat(j,:,:) = nFrameMat;
            
            % If non-touch, only write if close to actual touch
        elseif sum(ismember([timePos-20:timePos+20], cArray{i}.contactInds{1})) > 0
            newLabels(j) = 0; % Mark as touch
            % --Repeated in both sections -------------------------------------
            curFrame = videoArray.frames(timePos).cdata(:,:,1);
            poleBox = [xPole-roiRadius, xPole + roiRadius, yPole - roiRadius, yPole + roiRadius];
            nFrameMat = curFrame((poleBox(3)):(poleBox(4)),(poleBox(1)):(poleBox(2)));
            nFrameMat = imadjust(nFrameMat);
            % Save Frame
            finalMat(j,:,:) = nFrameMat;
            % Stuff
        else
            cutMat(j) = 1;
        end
    end
    finalMat(cutMat==1,:,:) = [];
    newLabels(cutMat==1) = [];

    maxDataset = cat(1, maxDataset, finalMat);
    maxLabels = [maxLabels newLabels];
    if length(maxLabels) > framesPerSet && rem(mainIter,4) ~= 0
      % Save as training data
      maxDataset = maxDataset(1:framesPerSet,:,:);
      maxLabels = maxLabels(1:framesPerSet);
      saveVidName = ['Train_Data_' num2str(trainSetIter) '_Session_' num2str(metaIter) '.npy'];
      saveName = [transferDir filesep saveVidName];
      writeNPY(maxDataset, saveName)
      labelName = ['Train_Labels_' num2str(trainSetIter) '_Session_' num2str(metaIter) '.npy'];
      saveLabelName = [transferDir filesep labelName];
      writeNPY(maxLabels, saveLabelName)
      trainSetIter = trainSetIter + 1;
      mainIter = mainIter + 1;
      maxDataset = [];
      maxLabels = [];
    elseif length(maxLabels) > framesPerSet && rem(mainIter,4) == 0
      % Save as validation data
      saveVidName = ['Valid_Data_' num2str(validSetIter) '_Session_' num2str(metaIter) '.npy'];
      saveName = [transferDir filesep saveVidName];
      writeNPY(maxDataset, saveName)
      labelName = ['Valid_Labels_' num2str(validSetIter) '_Session_' num2str(metaIter) '.npy'];
      saveLabelName = [transferDir filesep labelName];
      writeNPY(maxLabels, saveLabelName)
      validSetIter = validSetIter + 1;
      mainIter = mainIter + 1;
      maxDataset = [];
      maxLabels = [];
    end

    % Clear variables
    videoArray = [];
    finalMat = [];
    fullVidName = [];
  end
