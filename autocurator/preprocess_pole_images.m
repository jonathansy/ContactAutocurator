% PREPROCESS_POLE_IMAGES('distance', TARRAY) takes in a trial array and uses distance-to-pole
% metrics to eliminate obvious nontouches, speeding up the time it takes for autocuration
% PREPROCESS_POLE_IMAGES('pixel', IMAGEDIR) will reprocess based on number of pixels
function [contacts] = preprocess_pole_images(inType, var2)
% Check process method
switch inType
    % DISTANCE ONLY ---------------------------------------------------------
    case 'distance'
        T = load(var2); %The trial array used to preprocess
        T = T.T;
        if exist('T') == 0
            error('Cannot find trial array')
        end
        % load trial array for processing
        numTrials = length(T.trials);
        % Loop through trials and create contacts
        contacts = cell(1);
        contacts{1}.labels = [];
        contacts{1}.trialNum = [];
        contacts{1}.video = [];
        for i = 1:numTrials
            % Check that it's curatable
            if isempty(T.trials{i}.whiskerTrial) || ~ismember('whiskerTrial', properties(T.trials{i}))
                warning('Trial number %d has no distance to pole information', i)
                tContacts = zeros(1,4000);
                tContacts(:) = -1;
                contacts{i}.video = 'null';
            else % Trial safe to preprocess
                numPoints = length(T.trials{i}.whiskerTrial.barPos);
                tContacts = zeros(1, numPoints);
                poleDownTime = (T.trials{i}.pinDescentOnsetTime -.08)*1000; 
                poleUpTime = T.trials{i}.pinAscentOnsetTime*1000;
                % Sanity check 
                if poleUpTime > 4000
                    poleUpTime = 4000;
                end 
                if poleDownTime >4000
                    poleDownTime = 500;
                end
                % Determine minimum point to see if local tracking goes
                % below zero.  
%                 locMin = min(T.trials{i}.whiskerTrial.distanceToPoleCenter{1});
%                 if locMin > 0.5
%                     locMin = 0;
%                 end
                % Find valid times 
                validTimes = 1000*(T.trials{i}.whiskerTrial.time{1});
                for j = 1:numPoints %Loop through each point in trial
                    if ismember(j, validTimes)
                        currentPoint = T.trials{i}.whiskerTrial.distanceToPoleCenter{1}(j);
                    else
                        currentPoint = 0;
                    end
                    % Check if in pole up range
                    if j > poleDownTime && j < poleUpTime
                        inRange = 1;
                    else 
                        inRange = 0;
                    end 
                    % Check velocity
                    if j == 1
                        vPrevious = 0;
                    else
                        previousPoint = T.trials{i}.whiskerTrial.distanceToPoleCenter{1}(j-1);
                        vPrevious = abs(currentPoint - previousPoint);
                    end
                    if j == numPoints
                        vNext = 0;
                    else
                        nextPoint = T.trials{i}.whiskerTrial.distanceToPoleCenter{1}(j+1);
                        vNext = abs(currentPoint - nextPoint);
                    end
                    if vPrevious > 0.11 && vNext > 0.11
                        vOut = true;
                    elseif vPrevious > 0.11 && vNext > 0.05
                        vOut = true;
                    elseif vPrevious > 0.05 && vNext > 0.11
                        vOut = true;
                    else
                        vOut = false;
                    end
                    % Select based on pole up range and distance to pole
                    if currentPoint > 2 || inRange == 0
                        tContacts(j) = 0;
                    elseif currentPoint <= 2 && vOut == false
                        tContacts(j) = 2;
%                     elseif currentPoint <= 1 && vOut == false
%                         tContacts(j) = 3;
                    else
                        tContacts(j) = 0;
                    end
                end
                contacts{i}.video = T.trials{i}.whiskerTrial.trackerFileName;
            end
            contacts{i}.labels = tContacts;
            contacts{i}.trialNum = T.trials{i}.trialNum;
        end
        % PIXEL ONLY ------------------------------------------------------------
    case 'pixel'
%         % FUTURE SECTION
%         T = var2;
%         videoDir = var3;
%         if exist(videoDir) ~= 7
%             error('Cannot find video directory location')
%         end
%         if exist('T') == 0
%             error('Cannot find trial array')
%         end
%         % load trial array for processing
%         numTrials = length(T.trials);
%         % Loop through trials and create contacts
%         contacts = cell(1);
%         contacts{1}.labels = [];
%         contacts{1}.trialNum = [];
%         for i = 1:numTrials
%             contacts{i}.trialNum = T.trials{i}.trialNum;
%             % Check that it's curatable
%             if isempty(T.trials{i}.whiskerTrial) || ~ismember('whiskerTrial', properties(T.trials{i}))
%                 warning('Trial number %d has no distance to pole information', i)
%                 tContacts = zeros(1,4000);
%                 tContacts(:) = -1;
%             else % Trial safe to preprocess
%                 vidList
%             end
%         end
        
        % DISTANCE AND PIXEL
    case 'distance_WT'
        % Added version for using WT information, adjusted to Jinho's data
        if exist(var2) ~= 7
            error('Input must be a directory')
        end
        % TO-DO: Add ability to loop through WT files
        dirList = dir([var2 '/*.mat']);
        wtIdx = zeros(length(dirList), 1);
        for i = 1:length(dirList)
            % Retrieve only WT files since that's where data is stored
            dirName = dirList(i).name;
            fileEnd = dirName(end-5:end);
            if strcmp(fileEnd, 'WT.mat')
                wtIdx(i) = 1;
            else
                wtIdx(i) = 0;
            end
        end
        % Create mini contact array
        contacts = cell(1);
        contacts{1}.labels = [];
        contacts{1}.trialNum = [];
        contacts{1}.video = [];
        iterator = 1;
        for i = 1:length(dirList)
            if wtIdx(i) == 0
                continue
            end
            WT = load([var2 filesep dirList(i).name]);
            WT = WT.w;
            % Need to find only angles of 90 degrees
            if WT.angle ~= 90
                contacts{iterator}.labels = -1;
                contacts{iterator}.trialNum = WT.trialNum;
                contacts{iterator}.video = 'null';
                contacts{iterator}.barPos = barPos;
                iterator = iterator + 1;
                continue
            end
            
            numPoints = length(WT.dist2pole);
            tContacts = zeros(1, numPoints);
            barPos = zeros(2, numPoints);
            relFrames = [transpose(WT.poleMovingFrames) WT.poleUpFrames];
            for j = 1:numPoints
                currentPoint = WT.dist2pole(j);
                % Check if pole is up
                if ismember(j, relFrames)
                    % Find bar position, mark uncuratable if no bar
                    try
                        barPos(:,j) = WT.barPos(WT.barPos(:,1) == j,2:3);
                    catch
                        barPos(:,j) = nan;
                        tContacts(j) = 0;
                        continue
                    end
                    % If bar is nan, mark uncuratable 
                    if isnan(barPos(1,j)) || isnan(barPos(2,j))
                       barPos(:,j) = [0,0];
                       tContacts(j) = 0;
                        continue
                    end
                    % Run velocity filter, throw out fast movement as
                    % non-touch
                    lVelocity = WT.dist2pole(j) - WT.dist2pole(j-1);
                    rVelocity = WT.dist2pole(j+1) - WT.dist2pole(j);
                    avgSpeed = (abs(lVelocity) + abs(rVelocity))/2;
                    if lVelocity > 0 && rVelocity < 0
                        % Valid if change in direction
                        tContacts(j) = 2;
                    elseif lVelocity < 0 && rVelocity > 0
                        % Valid if change in direction
                        tContacts(j) = 2;
                    elseif avgSpeed < 1.9
                        % Valid if speed is slow
                        tContacts(j) = 2;
                    else
                        % Too fast, same direction, invalid
                        tContacts(j) = 0;
                    end
                    
                else %If pole out of range, mark uncuratable 
                    barPos(:,j) = nan;
                    tContacts(j) = 0;
                    continue
                end
            end
            contacts{iterator}.labels = tContacts;
            contacts{iterator}.trialNum = WT.trialNum;
            contacts{iterator}.video = num2str(WT.trialNum);
            contacts{iterator}.barPos = barPos;
            iterator = iterator + 1;
        end
        
        
    otherwise
        error('Invalid processing type')
end

end
