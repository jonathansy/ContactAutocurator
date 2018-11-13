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
  numTrials = length(contactLabels);
  for i = 1:numTrials % We want to iterate by trial
    contactPoints = contactLabels{i}.labels;
    confidence = zeros(size(contactPoints));
    if contactPoints(1) == -1
      continue
      % A negative one indicates that the trial array had no data
      % and we should skip this trial
    elseif sum(find(contactPoints==2)) == 0
        cArray.contacts{i}.contactInds{1} = [];
        cArray.contacts{i}.trialNum = contactLabels{i}.trialNum;
        continue
      % Indicates we don't need to do anything here
    end
    searchNum = contactLabels{i}.trialNum;
    
    %Find relevant .npy file
    fullNumpyName = [npLocation filesep contactLabels{i}.video '__curated_labels.npy'];
    
% OLD SECTION FOR FINDING NUMPY ARRAYS
%     for j = 1:numNPYs
%       numpyName = npyList{j};
%       exprNum = '[0123456789]+__curated_labels.npy';
%       resultStr = regexp(numpyName, exprNum, 'match'); %Should return #.npy
%       numStr = resultStr{1}(1:(end-20)); %Strip '_curated_labels.npy' to leave just video number
%       numpyNumber = str2num(numStr);
%       if numpyNumber == searchNum
%         fullNumpyName = [npLocation filesep numpyName];
%         break
%       else
%         continue
%       end
%     end
%     
%     if isempty(fullNumpyName)
%       continue
%     end
    
    predictions = readNPY(fullNumpyName); % Reads a Python npy file into MATLAB
    % Code courtesy of npy-matlab
    iterator = 1; % Need iterator so we don't skip a prediction point when we
    % skip a pre-processed point. There should be less predictions than points
    % in the contact array as a result of our preprocessing. They should go in
    % order. Points needing predictions are marked with a 2.
    for j = 1:numel(contactPoints) %Iterate through each point
        if contactPoints(j) == 2 || contactPoints(j) == 3 % If it doesn't equal 2 or 3, we skip the point
            % Use predictions to change
            if contactPoints(j) == 3
                %Leftover for rewrites
                contactPoints(j) = 0;
                confidence(j) = 1;
            % NOTE: Added confidence predictors to contact array 
            elseif contactPoints(j) == 2 && predictions(iterator, 1) > 0.4
                % Non-Touch point
                contactPoints(j) = 0;
                if contactPoints(j-1) == 1
                    %
                    if contactPoints(j-3) == 0 %CHANGE FOR JINHO'S CODE
                        contactPoints(j-1) = 0;
                        contactPoints(j-2) = 0;
                    end
                end
                confidence(j) = predictions(iterator, 1) + .1; 
                iterator = iterator + 1;
            elseif contactPoints(j) == 2 && predictions(iterator, 1) < 0.4
                % Touch point
                contactPoints(j) = 1;
                confidence(j) = predictions(iterator, 2) - .1; 
                iterator = iterator + 1;
            else
                % This means the CNN determined the probability of touch vs non-touch
                % was exactly equal. Empirically we know the CNN is biased towards
                % touches so we will mark as a non-touch. Note that getting this
                % conditional should be HIGHLY unlikely
                contactPoints(j) = 0;
                iterator = iterator + 1;
            end
        else
            if j > 100
                if contactPoints(j-1) == 1
                    %
                    if contactPoints(j-3) == 0
                        contactPoints(j-1) = 0;
                        contactPoints(j-2) = 0;
                    end
                end
            end
            % Leave predetermined points as 100% confidence
            confidence(j) = 1;
        end
        
        % Check for lone non touches
        if j > 100
                if contactPoints(j-2) == 0
                    %
                    if contactPoints(j-1) == 1 || contactPoints(j) == 1 
                        touchR = 1;
                    else 
                        touchR = 0;
                    end
                    if contactPoints(j-3) == 1 || contactPoints(j-4) == 1 
                        touchL = 1;
                    else 
                        touchL = 0;
                    end
                    if touchR == 1 && touchL == 1
                        contactPoints(j-2) = 1; 
                    end
                end
        end
            
    end
    conIdx = find(contactPoints == 1); % Extract out indices of touches because
    %that's what the contact array uses
    cArray.contacts{i}.contactInds = [];
    cArray.contacts{i}.contactInds{1} = conIdx;
    cArray.contacts{i}.confidence = confidence;
    cArray.contacts{i}.trialNum = contactLabels{i}.trialNum;
  end
  % Re-error check 
   % Error check if sizes don't match
  if length(contactLabels) ~= length(cArray.contacts)
      error('Contact array size does not match')
  elseif length(T.trials) ~= length(cArray.contacts)
      error('Trial array size does not match contact array')
  end
  
  % Save the contact array
  contacts = cArray.contacts;
  params = cArray.params;
  save(contactArray, 'contacts', 'params')
