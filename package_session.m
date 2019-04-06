% [CURATIONARRAY] = PACKAGE_SESSION(VIDEODIR, DATADIR) returns a single
% structure (CURATIONARRAY) with all relevant data for training and
% curation. VIDEODIR is the path to a session of whisker video while
% DATADIR is the path to all tracking data. It is designed to be used with
% the Janelia Farm whisker Tracker. VIDEODIR and DATADIR can be the same
% if video and data files are stored in the same directory.


% Created: 2018-11-12 by J. Sy
% Last Updated: 2018-11-12 by J. Sy

function [curationArray] = package_session(videoDir, dataDir)

% Find videos in directory, accept mp4 or avi
mp4List = dir([videoDir '/*.mp4']);
aviList = dir([videoDir '/*.avi']);
if ~isempty(mp4List) || ~isempty(aviList)
    vidList = vertcat(mp4List, aviList);
else
    error('No avi or mp4 video files found in video directory')
end


% Loop through video list for packaging
curationArray = cell(1,length(vidList));
for i = 1:length(vidList)
    whiskerFileName = [dataDir filesep vidList(i).name(1:end-4) '.whiskers'];
    barFileName = [dataDir filesep vidList(i).name(1:end-4) '.bar'];
    fullVideoName = [videoDir filesep vidList(i).name];

    % Get number of frames in video, helps with dropped frame issues
    try % See if normal mp4
        lVideo = VideoReader(fullVideoName);
        numFrames = 0;
        while hasFrame(lVideo)
            readFrame(lVideo);
            numFrames = numFrames + 1;
        end
    catch % Attempt to use mmread, sometimes works on mp4s where VideoReader fails
        lVideo = mmread(fullVideoName);
        numFrames = length(lVideo.frames);

    [distanceInfo, tFrames, barCoords] = find_distance_info(whiskerFileName, barFileName);
    curationArray{i}.distance = distanceInfo;
    curationArray{i}.video = fullVideoName;
    curationArray{i}.numTrackedFrames = length(distanceInfo);
    curationArray{i}.numFrames = numFrames;
    curationArray{i}.bar = barCoords;
    curationArray{i}.trackedFrames = tFrames;
end

end

% FIND_DISTANCE_INFO reads a .whiskers file, extracts bar position, and
% finds distance to pole information
function [dist, trackedFrames, barPositions] = find_distance_info(whiskersFile, barFile)
try % Account for missing or corrupt files
    [whiskerInf, ~] = Whisker.load_whiskers_file(whiskersFile);
    barPositions = load(barFile,'-ASCII');
catch % Either bar file or whisker file missing or corrupt
    dist = [];
    trackedFrames = [];
    barPositions = [];
end
% And now to extract out distance to pole information
dist = zeros(1, length(whiskerInf));
trackedFrames = zeros(1, length(whiskerInf));
for timePt = 1:length(whiskerInf)
    % Get all x and y coordinates traced on whisker
    xPoints = whiskerInf{timePt}{3}{1};
    yPoints = whiskerInf{timePt}{4}{1};
    % Get bar position for current time
    barIdx = find(barPositions(:,1) == timePt);
    % Skip distance to pole for this point if no bar position
    if isempty(barIdx)
        dist(timePt) = nan;
        continue
    end
    xBar = barPositions(barIdx,2);
    yBar = barPositions(barIdx,3);
    % Now calculate rough distance to pole. This is not, strictly speaking,
    % the most accurate way to run this calculation, however, given we
    % only require rough measurements and the Janelia Farm Whisker tracker
    % provides many vertices in each trace, it's much faster to simply run
    % a simple distance calculation on each vertex rather than a fitted
    % line
    if length(xPoints) ~= length(yPoints)
        dist(timePt) = nan;
    else
        % Run brute force distance to pole calculation
        shortestDist = [];
        for vert = 1:length(xPoints)
            ptDist = sqrt((xBar - xPoints(vert)).^2 + (yBar - yPoints(vert)).^2);
            if vert == 1
                % First pass
                shortestDist = ptDist;
            elseif ptDist < shortestDist
                % Replace only if smaller distance
                shortestDist = ptDist;
            end
        end
        dist(timePt) = shortestDist;
    end
    % Finally, get index of this tracked frame
    trackedFrames(timePt) = whiskerInf{timePt}{1};
end
end
