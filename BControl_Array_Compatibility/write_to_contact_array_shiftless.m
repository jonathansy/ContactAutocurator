% WRITE_TO_CONTACT_ARRAY(NUMPY_LOCATION, CONTACTS, CONTACTARRAY, JOBNAME) takes
% .npy files in NUMPY_LOCATION with curation labels and uses those labels as well
% as preprocessed labels in CONTACTS to write to CONTACTARRAY. JOBNAME is used to
% find the names of the needed files
function write_to_contact_array(npLocation, contactLabels, contactArray, tArray)
  % Handle the contact array
  if exist(contactArray) ~= 2
    error('Cannot find contact array')
  else
    cArray = load(contactArray);
    T = load(tArray);
    T = T.T;
  end
  
  % Error check if sizes don't match
  if length(contactLabels) ~= length(cArray.contacts)
      error('Contact array size does not match')
  elseif length(T.trials) ~= length(cArray.contacts)
      error('Trial array size does not match contact array')
  end

  % Get list of .npy files
  npyList = dir([npLocation '/*.npy']);
  npyList = {npyList(:).name};
  numNPYs = length(npyList);
  % Now figure out our labels
% Now figure out our labels
  numTrials = length(contactLabels);
  for i = 1:numTrials % We want to iterate by trial     
    potentialPoints = contactLabels{i}.labels;
    contactPoints = zeros(1,length(potentialPoints));
    confidence = zeros(size(potentialPoints));
    trialNum = contactLabels{i}.trialNum;
    if potentialPoints(1) == -1
      cArray.contacts{i}.contactInds{1} = [];
      cArray.contacts{i}.trialNum = contactLabels{i}.trialNum;
      continue
      % A negative one indicates that the trial array had no data
      % and we should skip this trial
    elseif sum(find(potentialPoints==2)) == 0
        cArray.contacts{i}.contactInds{1} = [];
        cArray.contacts{i}.trialNum = contactLabels{i}.trialNum;
        continue
      % Indicates we don't need to do anything here
    end
    searchNum = contactLabels{i}.trialNum;
    
    %Find relevant .npy file
    fullNumpyName = [npLocation filesep contactLabels{i}.video '__curated_labels.npy'];
    predictions = readNPY(fullNumpyName); % Reads a Python npy file into MATLAB
    % Code courtesy of npy-matlab

 % Account for Lost Tracking ***
for jj = 1:length(cArray{1, i}.time)-1
dT(jj) = cArray{i}.time(jj+1)-cArray{i}.time(jj);
end
dT_Mean = mean(dT);
skipInds = find(dT > dT_Mean);
toAdd = 1:length(skipInds);
cArray{i}.lostTracking = skipInds + toAdd;
    
indicesToKeep = 1:length(predictions);
usablePredictions = predictions(~ismember(indicesToKeep,cArray{i}.lostTracking));
 

    iterator = 1; % Need iterator so we don't skip a prediction point when we
    % skip a pre-processed point. There should be less predictions than points
    % in the contact array as a result of our preprocessing. They should go in
    % order. Points needing predictions are marked with a 2.
    for j = 1:numel(usablePredictions) %Iterate through each usable point
        if iterator > length(usablePredictions)
            warning('Too many points for trial %d, left off on %d', i, j)
            break
        end
        if potentialPoints(j) == 2 || potentialPoints(j) == 3 % If it doesn't equal 2 or 3, we skip the point
            % Use predictions to change
            if potentialPoints(j) == 3
                %Leftover for rewrites
                contactPoints(j) = 0;
                confidence(j) = 0;
            % NOTE: Added confidence predictors to contact array 
            elseif potentialPoints(j) == 2 && usablePredictions(iterator, 2) > 0.65
                % Non-Touch point
                contactPoints(j) = 0;
                confidence(j) = usablePredictions(iterator, 2);
                iterator = iterator + 1;
            elseif potentialPoints(j) == 2 && usablePredictions(iterator, 2) < 0.65
                % Touch point
                contactPoints(j) = 1;
                confidence(j) = usablePredictions(iterator, 2);
                iterator = iterator + 1;
            else
                % This means the CNN determined the probability of touch vs non-touch
                % was exactly equal. Empirically we know the CNN is biased towards
                % touches so we will mark as a non-touch. Note that getting this
                % conditional should be HIGHLY unlikely
                contactPoints(j) = 0;
                iterator = iterator + 1;
                confidence(j) = 0.5;
            end
        else
            % Leave predetermined points as 0% confidence of touch
            confidence(j) = 0;
        end
    end
    % Remove lone touches
    loneTouch = strfind(contactPoints, [0, 1, 0]);
    loneTouch = loneTouch + 1;
    contactPoints(loneTouch) = 0;

    conIdx = find(contactPoints == 1); % Extract out indices of touches because
    %that's what the contact array uses
         % DISREGARD: trialNum = trialNum - 155;
    cArray.contacts{i}.contactInds = [];
    cArray.contacts{i}.prepross = potentialPoints;
    cArray.contacts{i}.contactInds{1} = conIdx;
    cArray.contacts{i}.touchConfidence = confidence;
    cArray.contacts{i}.trialNum = contactLabels{i}.trialNum;
  end
  
  % Save the contact array
  contacts = cArray.contacts;
  %params = cArray.params;
  save('Z:\Users\Garrett\New_Autocurator_Test\Current_cArray\CuratedConTA_AH0657_170321_JC1235_AAAA.mat', 'contacts')
