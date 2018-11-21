classdef WhiskerTrial < handle
    %
    %   WhiskerTrial < handle
    %
    %
    % DHO, 5/08.
    %
    %
    %
    %
    
    properties
        trialNum = [];
        trialType = ''; % l, r, or n (no-go; for catch trials)
        whiskerNames = {};
        trajectoryIDs = []; % changed from {}, to reduce any confusion. 2017/09/16 JK (it's going to be numeric anyway, when called by trajectory_nums{1}
        trackerData = {};
        trackerFrames = {}; % contains information about which frames are at which index of trackerData (becaue quite many times tracker fails) 2018/03/22 JK
        barPos = []; % [frameNum XPosition YPosition]
%         barRadius = 3; % In pixels. Must be radius of bar tracked by the bar tracker. 
%         % 3 on 4/11/2018 (JK025~) 
%         % Defined in WT_2pad, instead of WT. 2018/07/19 JK
        barPosOffset = [0 0]; % In pixels. Displacement from the center of the large pole to the 'contact point'
        % (either on the edge of the large pole or small pole).
        
        
        
        % polyFits: Time-consuming to compute; not computed upon object construction;
        % need to resave object after computing.
        % Cell array of length length(trajectoryIDs), of format:
        % {{XPolyCoeffs_tid0, YPolyCoeffs_tid0},...,{XPolyCoeffs_tidN, YPolyCoeffs_tidN}};
        
        % Changed to apply mask, because noisy ugly tracking near whisker
        % pad leads to false fitting at the base 2017/09/16
        polyFits = {};
        
        polyFitsROI = {}; % Same format as polyFits but polynomials are fitted only to a
        % constant region of arc length, and in addition to x and y coefficients
        % there is stored the "q" values, i.e. the points along the normalized full
        % whisker ([0,1]) that the ROI fitting begins,as well as the two corresponding
        % values in units of pixels.  We store both for speed later. If a mask will be specified to define
        % the arc-length origin it must be applied prior to populating polyFitsROI.
        % Populated by method fit_polys_roi().
        % {x}{3} contains q(1) q(end) s(1) s(end). s contains pixel arc
        % lengths and q are corresponding values in [0 1] for polyval.
        %
        
        faceData = {}; % {[frameNumbers],{[x1, y1],[x2,y2], etc, one per frame}}
        
        faceSideInImage = 'bottom'; % 'top', 'bottom', 'left','right'
        protractionDirection = 'rightward'; % 'downward', 'upward', 'rightward','leftward'
        imagePixelDimsXY = [320 150]; % [NumberOfXPixels NumberOfYPixels]
        
%         pxPerMm = 17.81/2;
%         % Defined in WT_2pad, instead of WT. 2018/07/19 JK

        % polyFitsMask:
        % Cell array of length length(trajectoryIDs), of format:
        %
        % There is generally a noisy edge to the tracked
        % whiskers on the side of whisker pad, which can interfere
        % with proper measurement of radial distances. For each whisker
        % for each trial, can specify here a polynomial in image coordinate
        % space to "mask out" the noisy edge. That is, radial distance for
        % purposes of mean theta and mean kappa measurements will be measured starting
        % at the intersection of the tracked whisker with this masking polynomial
        % if the whisker in fact crosses the masking polynomial. I.e., the radial
        % distance is r_new = r - r_intersection where r_new is the
        % new radial distance used in mean theta and mean kappa measurements, r is the
        % original radial distance, and r_intersection is the point of intersection
        % between the fitted whisker and the masking polynomial. If there is no intersection,
        % then r_new = r.  Also, if polyFitsMask is empty (or is empty for a given whisker)
        % then r_new = r.
        %
        % Ultimately, may want to do this separately for every frame, perhaps after
        % face tracking.
        %
        % Polynomials can be of any order, and are reconstructed based on the number
        % of coefficients.
        % If polyFitsMask{k}{1} and polyFitsMask{k}{2} are NxM matrices where
        % M is the polynomial degree + 1 and N is the number of frames, then each frame
        % has its own mask. For instance, this could be used after face tracking.
        % If instead polyFitsMask{k}{1} and polyFitsMask{k}{2} are 1xM vectors
        % where M is the polynomial degree + 1, then the same mask is used for all
        % frames.
        %         polyFitsMask = {{[25 120],[157.5 31.5]},{[25 120],[157.5 31.5]},{[25 120],[157.5 31.5]}};
        polyFitsMask = {};
        
        
        %   maskTreatment: String describing treatment of mask. Or, can be cell array
        %                   of strings, of same length as obj.trajectoryIDs and with
        %                   matching entries, in order to set maskTreatment differently
        %                   for different trajectory IDs.
        %               Values: 'none', 'mask', 'maskNaN'.
        %                   none: Ignore the mask.
        %                   mask: Subtract from each radial distance in R
        %                      the radial distance at the intersection of
        %                      each fitted whisker with the mask.  If there is
        %                      no intersection for a given whisker, make no change
        %                      in the radial distance measurement: i.e. 0 is still
        %                      at the end. If obj.polyFitsMask is empty ({}), make
        %                      no change.
        %                   maskNaN: Same as mask except that if the whisker does
        %                      not intersect the mask in a given frame, set all its
        %                      values in R to NaN.
        maskTreatment = 'maskNaN'; % default defined in loadobj() also.
        
        framePeriodInSec = 1/310;
        mouseName = '';
        sessionName = '';
        trackerFileName = '';
        trackerFileFormat = 'whisker0'; % Format (version) of tracker file: whisker0 or whisker1
        useFlag = 1;
        
        stretched_mask = [];
        stretched_whisker = [];        
    end
    
    properties (Dependent = true)
        numFramesEachTrajectory
        allFrameNums
        numUniqueFrames
        whiskerPadOrigin
    end
    
    methods (Access = public)
        function obj = WhiskerTrial(tracker_file_name, trial_num, trajectory_nums, varargin)
            %
            %   obj = WhiskerTrial(tracker_file, trial_num, trajectory_nums)
            %   obj = WhiskerTrial(tracker_file, trial_num, trajectory_nums, mouse_name, session_name)
            %
            % trajectory_nums: Can be given in two forms: (a) a vector of
            %           trajectory numbers (e.g., [0 1 2]); or (b) a cell
            %           array of two elements with a vector of trajectory numbers
            %           in the first element, and a cell array of corresponding
            %           whisker names in the second element (e.g., {[0 1 2],{'D4,'D3','D2'}}).
            %           In the second case the number of trajectory IDs and whisker
            %           whisker names must match.
            %
            % varargin{1}: Optional mouse_name and session_name strings. If
            %           one is present both must be.
            %
            % varargin{2}: Optional mouse_name and session_name strings. If
            %           one is present both must be.
            %
            % varargin{3}: Optional integer-specified trial type (e.g., 0 for NoGo,
            %               1 for Go).
            %
            %
            %
            
            p = inputParser;

            p.addRequired('tracker_file_name', @ischar);
            p.addRequired('trial_num', @isnumeric);
            p.addRequired('trajectory_nums', @isnumeric);
            p.addParameter('mouseName', '', @ischar);
            p.addParameter('sessionName', '', @ischar);
            p.addParameter('trialType', '', @ischar);
            p.addParameter('behavior', [], @(x) isa(x,'Solo.BehavTrial2padArray'));

            p.parse(tracker_file_name, trial_num, trajectory_nums, varargin{:});
            
            obj.trackerFileName = p.Results.tracker_file_name;
            obj.trialNum = p.Results.trial_num;
            obj.mouseName = p.Results.mouseName;
            obj.sessionName = p.Results.sessionName;
            obj.trialType = p.Results.trialType;
            
            if iscell(p.Results.trajectory_nums)
                obj.trajectoryIDs = p.Results.trajectory_nums{1};
                obj.whiskerNames = p.Results.trajectory_nums{2};
                if numel(obj.trajectoryIDs) ~= numel(obj.whiskerNames)
                    error('Unequal number of whisker names and trajectory IDs in argument trajectory_nums')
                end
            elseif isnumeric(p.Results.trajectory_nums)
                obj.trajectoryIDs = p.Results.trajectory_nums;
            else
                error('Argument trajectory_nums is an invalid type.')
            end
            
            
            try
                %                 [r, obj.trackerFileFormat] = Whisker.load_segments([tracker_file_name '.whiskers']);
                [r, obj.trackerFileFormat] = Whisker.load_whiskers_file([p.Results.tracker_file_name '.whiskers']);
                
                % .measurements file is newer replacement for .trajectories.  If there's a .measurements
                % file, choose that.  If not, choose the .trajectories.  Give a message to alert user
                % if both are found.
                if exist([p.Results.tracker_file_name '.measurements'],'file')
                    M = Whisker.read_whisker_measurements_v3([p.Results.tracker_file_name '.measurements']);
                    trajectory_ids = M(:,1);
                    frame_nums = M(:,2);
                    segment_nums = M(:,3);
                    if exist([p.Results.tracker_file_name '.trajectories'],'file')
                        disp(['For ' p.Results.tracker_file_name 'found both .measurements and .trajectories files---using .measurements.'])
                    end
                else
                    % .measurements file not found; choose .trajectories file.
                    [trajectory_ids, frame_nums, segment_nums] = Whisker.load_trajectories([p.Results.tracker_file_name '.trajectories']);
                end
                
                if exist([p.Results.tracker_file_name '.bar'],'file')
                    [bar_f, bar_x, bar_y] = Whisker.load_bar([p.Results.tracker_file_name '.bar']);
                    obj.barPos = [bar_f, bar_x, bar_y];
                end
            catch ME
                disp(ME)
                error(['Cannot load tracker files for: ' p.Results.tracker_file_name])
            end
            
            sFrameNums = cellfun(@(x) x{1},r);
            
            D = cell(1,length(trajectory_ids));
            
            for k=1:length(trajectory_ids)
                frame = frame_nums(k);
                trajectory = trajectory_ids(k);
                segment = segment_nums(k);
                
                %                 indFrame = find(round(sFrameNums)==round(frame));
                indFrame = find(abs(sFrameNums-frame) < 1e-12);
                
                trialSegs = r{indFrame}{2};
                %                 indSeg = find(round(trialSegs)==round(segment));
                indSeg = find(abs(trialSegs-segment) < 1e-12);
                
                if isempty(indSeg)
                    xdat = single([]); ydat = single([]);
                else
                    if strcmp(obj.trackerFileFormat,'whisker0')
                        xdat = single(r{indFrame}{3}(indSeg,:));
                    else
                        xdat = single(r{indFrame}{3}{indSeg});
                    end
                    ydat = single(r{indFrame}{4}{indSeg});
                end
                
                D{k} = {trajectory, frame, segment, xdat, ydat};
            end
            
            %--- .trajectories files don't necessarily have frameNums in order,
            % so sort them here:
            f =  cellfun(@(x) x{2}, D);
            [~,ind] = sort(f,2,'ascend');
            D = D(ind);
            %-----------------------------------------------------------
            
            tr = cellfun(@(x) x{1}, D);
            ind = ismember(tr, obj.trajectoryIDs);
            D = D(ind); % restrict to trajectories specified in trajectory_nums input parameter.
            tr = tr(ind);
            
            % Package by trajectory:
            obj.trackerData = cell(1,length(obj.trajectoryIDs));
            obj.trackerFrames = cell(1,length(obj.trajectoryIDs));
            for k=1:length(obj.trajectoryIDs)
                obj.trackerData{k} = D(tr==obj.trajectoryIDs(k));
                obj.trackerFrames{k} = cellfun(@(x) x{2}, obj.trackerData{k});
            end            
        end
        
%         function r = saveobj(obj)
%             %
%             %   r = saveobj(obj)
%             %
%             r.trialNum = obj.trialNum;
%             r.trialType = obj.trialType;
%             r.whiskerNames = obj.whiskerNames;
%             r.trajectoryIDs = obj.trajectoryIDs;
%             r.trackerData = obj.trackerData;
%             r.trackerFrames = obj.trackerFrames;
%             r.polyFits = obj.polyFits;
%             r.polyFitsROI = obj.polyFitsROI;
%             r.maskTreatment = obj.maskTreatment;
%             r.faceData = obj.faceData;
%             r.framePeriodInSec = obj.framePeriodInSec;
%             r.mouseName = obj.mouseName;
%             r.sessionName = obj.sessionName;
%             r.trackerFileName = obj.trackerFileName;
%             r.trackerFileFormat = obj.trackerFileFormat;
%             r.useFlag = obj.useFlag;
%             r.faceSideInImage = obj.faceSideInImage;
%             r.protractionDirection = obj.protractionDirection;
%             r.imagePixelDimsXY = obj.imagePixelDimsXY;
%             r.pxPerMm = obj.pxPerMm;
%             r.barPos = obj.barPos;
%             r.barRadius = obj.barRadius;
%             r.barPosOffset = obj.barPosOffset;
%             r.polyFitsMask = obj.polyFitsMask;
%             r.stretched_mask = obj.stretched_mask;
%             r.stretched_whisker = obj.stretched_whisker; 
% 
%         end
        
        function tid = name2tid(obj, whisker_name)
            if ~ischar(whisker_name)
                error('Argument whisker_name must be a string.')
            end
            if length(obj.whiskerNames) ~= length(obj.trajectoryIDs)
                error('This WhiskerSignalTrial does not have matching whiskerNames and trajectoryIDs.')
            end
            tid = obj.trajectoryIDs( strmatch(whisker_name, obj.whiskerNames) );
        end
        
        function whisker_name = tid2name(obj, trajectory_id)
            if ~isnumeric(trajectory_id)
                error('Argument trajectory_id must be an integer.')
            end
            if length(trajectory_id) > 1
                error('Only one trajectory_id is allowed.')
            end
            whisker_name = obj.whiskerNames(obj.trajectoryIDs==trajectory_id);
        end
        
        function r = get_whisker_y_range(obj,tid,varargin)
            %
            %   r = get_whisker_y_range(obj,tid,varargin)
            %
            %
            % tid: Either trajectory ID (as an integer) or whisker name
            %      (as a string).
            %
            % varargin{1} - x-limits in form [xmin xmax].
            %               Can be empty ([]) to allow access to varargin{2}.
            %
            % varargin{2}: Optional 2 x 1 vector giving starting and ending times (in seconds) to include in
            %               range, inclusive, starting with 0.
            %               Of format: [startTimeInSec endTimeInSec].
            %
            %
            
            if isnumeric(tid) % Trajectory ID specified.
                ind = find(obj.trajectoryIDs == tid);
            elseif ischar(tid) % Whisker name specified.
                ind = strcmp(tid,obj.whiskerNames);
            else
                error('Invalid type for argument ''tid''.')
            end
            
            if isempty(ind)
                error('Could not find specified trajectory ID or whisker name.')
            elseif numel(ind) > 1
                error('Found multiple instances of specified trajectory ID or whisker name.')
            end
            
            frameNums = cellfun(@(x) x{2}, obj.trackerData{ind});
            if isempty(frameNums)
                % No whisker with this tid is in this trial, despite being in the list of tids
                % (for example if made as part of a WhiskerTrialArray where most/all other trials
                % have this tid and so it's given as a default).
                r = [NaN NaN];
                return
            end
            nframes = length(frameNums);
            
            if nargin > 2
                XValLims = varargin{1};
            else
                XValLims = [];
            end
            
            t = obj.get_time(tid);
            
            if nargin > 3
                restrictTime = varargin{2};
                if isempty(restrictTime)
                    restrictTime = [min(t) max(t)];
                elseif restrictTime(2) <= restrictTime(1)
                    error('Invalid format for varargin{2}.')
                elseif max(restrictTime) > max(t)
                    disp('Warning: varargin{2} exceeds max time; setting to max.')
                    restrictTime(restrictTime==max(restrictTime)) = max(t);
                    if restrictTime(1)==restrictTime(2)
                        error('varargin{2}: Both times exceed max time.')
                    end
                elseif min(restrictTime < 0)
                    disp('varargin{2}: times start at 0.')
                end
            else
                restrictTime = [min(t) max(t)];
            end
            
            ymin = zeros(1,nframes);
            ymax = zeros(1,nframes);
            
            trajectoryData = obj.trackerData{ind};
            for k=1:nframes
                f = trajectoryData{k};
                if numel(f{4})==2 % Tracker can sometimes (rarely) leave frame entries for a trajectory in whiskers file that have no pixels.
                    r = getYRange(f,XValLims);
                    ymin(k) = r(1);
                    ymax(k) = r(2);
                end
            end
            
            if length(t) ~= nframes
                error('Number of times and number of frames are not equal.')
            end
            
            frameInds = t >= restrictTime(1) & t <= restrictTime(2);
            ymin = ymin(frameInds);
            ymax = ymax(frameInds);
            
            r = [nanmin(ymin) nanmax(ymax)];
            
            function r = getYRange(frame,XValLims) % SUBFUNCTION
                %
                %
                x = frame{4};
                if strcmp(obj.trackerFileFormat,'whisker0')
                    x = (x(1):x(2))';
                end
                
                yy = frame{5};
                if ~isempty(XValLims)
                    ind = x >= XValLims(1) & x <= XValLims(2);
                    yy = yy(ind);
                    x = x(ind);
                end
                if length(x) > 1
                    r = [min(yy) max(yy)];
                else
                    %                     disp('Number of samples <1, returning NaN.')
                    r = [NaN NaN];
                end
            end
        end
        
        function t = get_time(obj,tid)
            %
            %   t = get_time(obj,tid)
            %
            %   USAGE:
            %       t = get_time(obj,tid)
            %
            %   INPUTS:
            %       tid:  Trajectory ID (as an integer) or whisker name (as a string).
            %
            %   OUTPUTS:
            %       t: time in seconds for each sample in this WhiskerTrial for given trajectory ID or whisker name.
            %
            if isnumeric(tid) % Trajectory ID specified.
                ind = find(obj.trajectoryIDs == tid);
            elseif ischar(tid) % Whisker name specified.
                ind = strcmp(tid,obj.whiskerNames);
            else
                error('Invalid type for argument ''tid''.')
            end
            
            if isempty(ind)
                error('Could not find specified trajectory ID.')
            end
            frameNums = cellfun(@(x) x{2}, obj.trackerData{ind});
            
            t = frameNums*obj.framePeriodInSec;
        end
        
        function f = get_videoFrames(obj)
            %
            % f = get_videoFrames(obj)
            %
            %   USAGE:
            %       f = get_videoFrames(obj)
            %
            %   INPUTS:
            %
            %   OUTPUTS:
            %       f: number of frames in the analyzed video, mp4 file.
            %
            %   2017/04/03 JK
            %   
            try
                fn = [obj.trackerFileName, '.mp4'];
                v = VideoReader(fn);                
            catch
                fn = [obj.trackerFileName, '.avi'];
                v = VideoReader(fn);                    
            end
            f = round(v.Duration*v.FrameRate);
        end
        
        function set_face_coords_all(obj, x, y)
            %
            %   set_face_coords_all(obj, x, y)
            %
            % obj.faceData: {[frameNumbers],{[x1, y1],[x2,y2], etc, one per frame}}
            %
            nframes = obj.numUniqueFrames;
            faceCoords = cell(1,nframes);
            for k=1:nframes
                faceCoords{k} = [x, y];
            end
            
            obj.faceData = {obj.allFrameNums, faceCoords};
        end
        
        function obj = set_bar_offset(obj,dx,dy)
            %
            % obj = set_bar_offset(obj,dx,dy)
            %
            % dx: Number of pixels to offset bar center in x.
            % dy: Number of pixels to offset bar center in y.
            %
            %
            %
            if length(dx) ~= 1 || length(dy) ~= 1
                error('Arguments dx and dy must both be scaler.')
            end
            
            obj.barPosOffset = [dx dy];
            
            % Should also add capability to set different offsets for
            % different frames.
        end
        
        function plot_face_coords(obj, frameNum)
            frames = obj.faceData{1};
            ind = find(frames==frameNum);
            if length(ind) > 1
                error(['Found duplicates for frame ' int2str(frameNum)])
            elseif isempty(ind)
                disp(['No face data for frame ' int2str(frameNum) ', not plotting.'])
            else
                dat = obj.faceData{2}{ind};
                x = dat(:,1); y = dat(:,2);
                plot(x,y,'k-')
            end
        end
        
        function obj = set_mask_from_points(obj,tid,x,y, varargin)
            %
            % Sets obj.polyFitsMask in order
            % to create a mask defined by the points in x and y.
            %
            % tid: Trajectory ID. Can be a vector with multiple trajectory
            %       IDs. In this case all will be set to have same mask.
            %
            % x: Row vector of x coordinates to define mask.
            % y: Row vector of y coordinates to define mask.
            %
            % If N points are selected, mask will be the (N-1)-th
            % degree polynomial fit to the points for N < 5. For N >= 6
            % the polynomial will be 5-th degree.
            %
            %
            % varargin about stretching the mask. 1.2 as 20% stretching in both sides 2018/03/01 JK
            %
            %
            
            qnum = length(x);            
            if length(x) ~= length(y)
                error('Inputs x and y must be of equal length.')
            end
            
            % Make x, y row vectors:
            if size(x,1) > size(x,2)
                x = x';
            end
            if size(y,1) > size(y,2)
                y = y';
            end
            
%             if qnum < 2
%                 error('Must define at least 2 points.')
%             elseif qnum < 6
%                 polyDegree = qnum-1;
%             else
%                 polyDegree = 5;
%             end
            polyDegree = 2;
            
            if nargin > 4
                q = ( 0-(varargin{1}-1) : (qnum-1)*varargin{1})./(qnum-1); % [0,1] stretched both ways
            else
                q = (0 : (qnum-1))./(qnum-1); % [0,1]
            end
            
            % polyfit() gives warnings that indicate that we don't need such a high degree
            % polynomials. Turn off.
            %             warning('off','MATLAB:polyfit:RepeatedPointsOrRescale');
            px = Whisker.polyfit(q,x,polyDegree);
            py = Whisker.polyfit(q,y,polyDegree);
            %             warning('on','MATLAB:polyfit:RepeatedPointsOrRescale');
            
            if isempty(obj.polyFitsMask)
                obj.polyFitsMask = cell(1,length(obj.trajectoryIDs));
            end
            
            for k=1:length(tid)
                ind = obj.trajectoryIDs==tid(k);
                if max(ind) < 1
                    error('Trajectory ID was not found.')
                end
                obj.polyFitsMask{ind} = {px,py};
            end
        end
        
        function plot_mask(obj,tid,varargin)
            %
            % Plots the polynomial mask defined by obj.polyFitsMask.
            %
            % tid: A single trajectory ID.
            %
            % varargin{1}: Plot symbol string, e.g., 'k-'.  A string
            %               that can be given as an argument to plot().
            %
            % varargin{2}: Tracked frame number, from 1 to the number of
            %        frames tracked. Not necessarily frame number from
            %        the original movie (unless all frames were tracked).
            %        If the mask is the same for all frames, this argument
            %        is ignored.
            %
            %
            %
            if isempty(obj.polyFitsMask)
                error('obj.polyFitsMask is empty.')
            end
            
            ind = obj.trajectoryIDs==tid;
            if max(ind) < 1
                error('Trajectory ID was not found.')
            end
            
            if length(tid) > 1
                error('Only a single trajectory ID allowed.')
            end
            
            if nargin > 4
                error('Too many input arguments.')
            end
            
            if nargin > 2
                plotString = varargin{1};
            else
                plotString = 'k-';
            end
            
            if nargin > 3
                frame = varargin{2};
                if frame > length(obj.time{ind})
                    error('varargin{2}, the frame number, exceeds the number of tracked frames.')
                end
            else
                frame = 1;
            end
            
            px = obj.polyFitsMask{ind}{1};
            py = obj.polyFitsMask{ind}{2};
            
            if size(px,1) > 1
                px = px(frame,:);
                py = py(frame,:);
            end
            
            q = linspace(0,1);
            
            x = polyval(px,q);
            y = polyval(py,q);
            
            plot(x,y,plotString,'LineWidth',2)
        end
        
        function [t,theta,kappa] = mean_theta_and_kappa(obj,tid,radial_window_theta,radial_window_kappa)
            %
            %  [t,theta,kappa] = mean_theta_and_kappa(obj,tid,radial_window_theta,radial_window_kappa)
            %
            %   The whisker is parameterized as c(q) = (x(q),y(q)), where q has length(x)
            %   and is in [0,1].
            %
            % INPUTS:
            %
            %   tid: Whisker trajectory ID.
            %
            %   radial_window_kappa: 2x1 vector giving arc length region of whisker to
            %   average over for mean kappa measurment, in format [startDistance stopDistance].
            %   Values are inclusive and in units of pixels. If empty ([]), averages over
            %   the whole whisker.
            %
            %   radial_window_theta: 2x1 vector giving arc length region of whisker to
            %   average over for mean kappa measurment, in format [startDistance stopDistance].
            %   Values are inclusive and in units of pixels. If empty ([]), averages over
            %   the whole whisker, which is not likely useful for theta.
            %
            %
            % RETURNS:
            %
            %   t:  Time in seconds corresponding to each frame.
            %
            %   theta: Angle of the line tangent to the whisker (i.e., to c(q)), averaged over
            %           radial distances (arc length) between and including radial_window_theta(1)
            %           and radial_window_theta(2).
            %
            %   kappa:  Signed curvature averaged over radials distances (arc length) between and including
            %           radial_window_kappa(1) and radial_window_kappa(2), for each frame.
            %           Units of 1/pixels. Abs(kappa(q)) is 1/X where X is
            %           the radius in pixels of the osculating circle at c(q).
            %
            %
            %
            
            [R,THETA,KAPPA] = obj.arc_length_theta_and_kappa(tid);
            
            if isempty(radial_window_kappa)
                kappa = cellfun(@mean, KAPPA);
            else
                %                 kappa = cellfun(@(x,y) mean(x(y >= radial_window_kappa(1) & y <= radial_window_kappa(2))),KAPPA,R);
                nframes = length(R);
                kappa = nan(1,nframes);
                for k=1:length(R)
                    if ~isnan(R{k}(1))
                        kappa(k) = mean(KAPPA{k}( R{k} >= radial_window_kappa(1) & R{k} <= radial_window_kappa(2) ));
                    end
                end
            end
            
            if isempty(radial_window_theta)
                theta = cellfun(@mean, THETA);
            else
                %                 theta = cellfun(@(x,y) mean(x(y >= radial_window_theta(1) & y <= radial_window_theta(2))),THETA,R);
                nframes = length(R);
                theta = nan(1,nframes);
                for k=1:length(R)
                    if ~isnan(R{k}(1))
                        theta(k) = mean(THETA{k}( R{k} >= radial_window_theta(1) & R{k} <= radial_window_theta(2) ));
                    end
                end
            end
            
            t = obj.get_time(tid);
            
            % Interpolate to fill missing (NaN) values, arising for instance if there
            % weren't enough pixels to do curve fitting. NaN also arise if obj.maskTreatment
            % is set to 'maskNaN'.
            missing = isnan(kappa);
            if sum(missing)==length(missing)
                kappa = NaN;
            elseif sum(~missing) > 1
                kappa = interp1(t(~missing),kappa(~missing),t,'linear','extrap');
            end
            
            missing = isnan(theta);
            if sum(missing)==length(missing)
                theta = NaN;
            elseif sum(~missing) > 1
                theta = interp1(t(~missing),theta(~missing),t,'linear','extrap');
            end
        end
        
        function [R,R0] = arc_length_and_intersection(obj,tid,varargin)
            %
            % Used instead of arc_length_theta_and_kappa to get R0 only, in
            % fit_polys_roi
            %
            % 2017/04/03 JK
            %
            if nargin < 3
                npoints = 100;
            else
                npoints = varargin{1};
                if isempty(npoints)
                    npoints = 100;
                end
            end
            
            ind = find(obj.trajectoryIDs == tid);
            if isempty(ind)
                error('Could not find specified trajectory ID.')
            end
            
            frameNums = cellfun(@(x) x{2}, obj.trackerData{ind});
            nframes = length(frameNums);
            
            if isempty(obj.polyFits)
                disp('obj.polyFits is empty, calling obj.fit_polys; probably want save this WhiskerTrial object afterward.')
                obj.fit_polys;
            end
            
            R = cell(1,nframes);
            R0 = zeros(1,nframes);
            
            fittedX = obj.polyFits{ind}{1};
            fittedY = obj.polyFits{ind}{2};
            
            q = linspace(0,1,npoints);
            
            for k=1:nframes                
                x = obj.trackerData{ind}{k}{4};
                if numel(x) < 2 % Tracker can sometimes (rarely) leave frame entries for a trajectory in whiskers file that have no pixels.
                    R{k} = NaN;
                    R0(k) = NaN;
                    continue
                end
                
                px = fittedX(k,:);
                py = fittedY(k,:);
                
                pxDot = polyder(px);
                pyDot = polyder(py);
                
                xDot = polyval(pxDot,q);
                yDot = polyval(pyDot,q);
                
                dq = [0 diff(q)];
                
                % Arc length as a function of q, after integration below:
                R{k} = cumsum(sqrt(xDot.^2 + yDot.^2) .* dq); % arc length segments, in pixels, times dq.
            end
            
            % Apply any mask:
            if iscell(obj.maskTreatment)
                if length(obj.maskTreatment) ~= length(obj.trajectoryIDs)
                    error('obj.maskTreatment and obj.trajectoryIDs must have the same length and matching entries.')
                end
                mask_treatment = obj.maskTreatment{ind};
            else
                mask_treatment = obj.maskTreatment;
            end
            if strcmp(mask_treatment,'none')
                return
            end
            
            % If there is a polynomial mask specified (see documentation for
            % object property 'polyFitsMask') and varargin{1} is given, subtract from each element of
            % R the radial distance at the intersection, if any, of the fitted
            % whisker and the polynomial mask.
            if isempty(obj.polyFitsMask)
                return
            else
                pm = obj.polyFitsMask{ind};
                if isempty(pm)
                    return
                end
            end
            
            fittedXMask = obj.polyFitsMask{ind}{1};
            fittedYMask = obj.polyFitsMask{ind}{2};
            
            for k=1:nframes                
                px = fittedX(k,:);
                py = fittedY(k,:);
                
                if size(fittedXMask,1) > 1
                    pxm = fittedXMask(k,:);
                    pym = fittedYMask(k,:);
                else
                    pxm = fittedXMask;
                    pym = fittedYMask;
                end
                
                C1 = [polyval(px,q); polyval(py,q)];
                C2 = [polyval(pxm,q); polyval(pym,q)];
                P = Whisker.InterX(C1,C2); % Find points where whisker and mask curves intersect. Slower but more
                %  accurate version that isn't limited in resolution by the number of
                %  points whisker and mask are evaluated at.
                if size(P,2) > 1   % Don't need for faster version, which handles this.
                    disp('Found more than 1 intersection of whisker and mask curves; using only first.')
                    P = P(:,1);
                end
                
                %                 P = Whisker.InterXFast(C1,C2); % Find points where whisker and mask curves intersect. Much faster version
                %                                                 % that is limited in resolution by the number of
                %                                                 % points whisker and mask are evaluated at (i.e., by number of points in q).
                
                if isempty(P)
                    if strcmp(mask_treatment,'maskNaN')
                        R{k} = nan(size(R{k}));
                        R0(k) = NaN;
                    end
                else
                    % Find at what q the whisker is at (P(1),P(2)), i.e., q s.t. x(q)=P(1),y(q)=P(2).
                    % Doesn't match exactly (maybe due to roundoff error), so find closest.
                    C = C1 - repmat(P,[1 size(C1,2)]);
                    err = sqrt(C(1,:).^2 + C(2,:).^2);
                    ind2 = err==min(err);
                    R0(k) = R{k}(ind2);
                    R{k} = R{k} - R{k}(ind2);
                end
            end
        end
            
        
        function [R,THETA,KAPPA,varargout] = arc_length_theta_and_kappa(obj,tid,varargin)
            %
            % [R,THETA,KAPPA] = arc_length_theta_and_kappa(obj,tid)
            % [R,THETA,KAPPA,R0] = arc_length_theta_and_kappa(obj,tid)
            % [R,THETA,KAPPA] = arc_length_theta_and_kappa(obj,tid,npoints)
            % [R,THETA,KAPPA,R0] = arc_length_theta_and_kappa(obj,tid,npoints)
            %
            %   The whisker is parameterized as c(q) = (x(q),y(q)), where q has length(x)
            %   and is in [0,1].
            %
            %
            % INPUTS:
            %
            %   tid: Whisker trajectory ID.
            %
            %   varargin{1}: Optional, integer giving number of points (values of q) to
            %        use in reconstructing each whisker. Default is 100 points.
            %
            %
            % RETURNS:
            %
            %   R:  A cell array where each element is the arc length, computed moving outward from
            %       whisker follicle along the whisker for a single frame. Units of pixels.
            %
            %   THETA: A cell array where each element theta is the angle of the line tangent to the
            %           whisker (i.e., to c(q)) at each value of q.
            %
            %   KAPPA: A cell array where each element kappa is the signed curvature at each point
            %           on the whisker (i.e., for each value of q). Units of 1/pixels. Abs(kappa(q)) is 1/X where X is
            %           the radius in pixels of the osculating circle at c(q).
            %
            %   OPTIONAL:
            %
            %   R0: A vector with one element per frame giving the arc-length at the point of intersection
            %       between the fitted whisker and the mask. I.e., the quantity subtracted from raw arc-length
            %       in order to get the values returned in R.
            %
            %
            %
            %
            %   kappa(q) = (x'y'' - y'x'') / (x'^2 + y'^2)^(3/2)
            %   theta(q) = atand(y'/x')
            %   arc_length(q) = cumsum(sqrt(x'^2 + y'^2))
            %
            %
            if nargin < 3
                npoints = 100;
            else
                npoints = varargin{1};
                if isempty(npoints)
                    npoints = 100;
                end
            end
            
            ind = find(obj.trajectoryIDs == tid);
            if isempty(ind)
                error('Could not find specified trajectory ID.')
            end
            
            frameNums = cellfun(@(x) x{2}, obj.trackerData{ind});
            nframes = length(frameNums);
            
            if isempty(obj.polyFits)
                disp('obj.polyFits is empty, calling obj.fit_polys; probably want save this WhiskerTrial object afterward.')
                obj.fit_polys;
            end
            
            R = cell(1,nframes);
            THETA = cell(1,nframes);
            KAPPA = cell(1,nframes);
            R0 = zeros(1,nframes);
            
            fittedX = obj.polyFits{ind}{1};
            fittedY = obj.polyFits{ind}{2};
            
            q = linspace(0,1,npoints);
            
            for k=1:nframes
                
                x = obj.trackerData{ind}{k}{4};
                if numel(x) < 2 % Tracker can sometimes (rarely) leave frame entries for a trajectory in whiskers file that have no pixels.
                    R{k} = NaN;
                    THETA{k} = NaN;
                    KAPPA{k} = NaN;
                    R0(k) = NaN;
                    continue
                end
                
                px = fittedX(k,:);
                py = fittedY(k,:);
                
                pxDot = polyder(px);
                pxDoubleDot = polyder(pxDot);
                
                pyDot = polyder(py);
                pyDoubleDot = polyder(pyDot);
                
                xDot = polyval(pxDot,q);
                xDoubleDot = polyval(pxDoubleDot,q);
                
                yDot = polyval(pyDot,q);
                yDoubleDot = polyval(pyDoubleDot,q);
                
                dq = [0 diff(q)];
                
                % Arc length as a function of q, after integration below:
                R{k} = cumsum(sqrt(xDot.^2 + yDot.^2) .* dq); % arc length segments, in pixels, times dq.
                
                
                % Angle (in degrees) as a function of q:
                % Protraction means theta is increasing.
                % Theta is 0 when perpendicular to the midline of the mouse.
                if strcmp(obj.faceSideInImage,'top') && strcmp(obj.protractionDirection,'rightward')
                    THETA{k} = atand(xDot ./ yDot);
                elseif strcmp(obj.faceSideInImage,'top') && strcmp(obj.protractionDirection,'leftward')
                    THETA{k} = -atand(xDot ./ yDot);
                elseif strcmp(obj.faceSideInImage,'left') && strcmp(obj.protractionDirection,'downward')
                    THETA{k} = atand(yDot ./ xDot);
                elseif strcmp(obj.faceSideInImage,'left') && strcmp(obj.protractionDirection,'upward')
                    THETA{k} = -atand(yDot ./ xDot);
                elseif strcmp(obj.faceSideInImage,'right') && strcmp(obj.protractionDirection,'upward')
                    THETA{k} = atand(yDot ./ xDot);
                elseif strcmp(obj.faceSideInImage,'right') && strcmp(obj.protractionDirection,'downward')
                    THETA{k} = -atand(yDot ./ xDot);
                elseif strcmp(obj.faceSideInImage,'bottom') && strcmp(obj.protractionDirection,'rightward')
                    THETA{k} = -atand(xDot ./ yDot);
                elseif strcmp(obj.faceSideInImage,'bottom') && strcmp(obj.protractionDirection,'leftward')
                    THETA{k} = atand(xDot ./ yDot);
                else
                    error('Invalid value of property ''faceSideInImage'' or ''protractionDirection''')
                end
                
                % Signed curvature as a function of q:
                KAPPA{k} = (xDot.*yDoubleDot - yDot.*xDoubleDot) ./ ((xDot.^2 + yDot.^2).^(3/2)); % SIGNED CURVATURE, in 1/pixels.
                %                 KAPPA{k} = abs(xDot.*yDoubleDot - yDot.*xDoubleDot) ./ ((xDot.^2 + yDot.^2).^(3/2)); % CURVATURE, in 1/pixels.
            end
            
            % Apply any mask:
            if iscell(obj.maskTreatment)
                if length(obj.maskTreatment) ~= length(obj.trajectoryIDs)
                    error('obj.maskTreatment and obj.trajectoryIDs must have the same length and matching entries.')
                end
                mask_treatment = obj.maskTreatment{ind};
            else
                mask_treatment = obj.maskTreatment;
            end
            if strcmp(mask_treatment,'none')
                return
            end
            
            % If there is a polynomial mask specified (see documentation for
            % object property 'polyFitsMask') and varargin{1} is given, subtract from each element of
            % R the radial distance at the intersection, if any, of the fitted
            % whisker and the polynomial mask.
            if isempty(obj.polyFitsMask)
                return
            else
                pm = obj.polyFitsMask{ind};
                if isempty(pm)
                    return
                end
            end
            
            fittedXMask = obj.polyFitsMask{ind}{1};
            fittedYMask = obj.polyFitsMask{ind}{2};
            
            q = linspace(0,1,npoints);
            
            for k=1:nframes
                
                px = fittedX(k,:);
                py = fittedY(k,:);
                
                if size(fittedXMask,1) > 1
                    pxm = fittedXMask(k,:);
                    pym = fittedYMask(k,:);
                else
                    pxm = fittedXMask;
                    pym = fittedYMask;
                end
                
                C1 = [polyval(px,q); polyval(py,q)];
                C2 = [polyval(pxm,q); polyval(pym,q)];
                P = Whisker.InterX(C1,C2); % Find points where whisker and mask curves intersect. Slower but more
                %  accurate version that isn't limited in resolution by the number of
                %  points whisker and mask are evaluated at.
                if size(P,2) > 1   % Don't need for faster version, which handles this.
                    disp('Found more than 1 intersection of whisker and mask curves; using only first.')
                    P = P(:,1);
                end
                
                %                 P = Whisker.InterXFast(C1,C2); % Find points where whisker and mask curves intersect. Much faster version
                %                                                 % that is limited in resolution by the number of
                %                                                 % points whisker and mask are evaluated at (i.e., by number of points in q).
                
                if isempty(P)
                    if strcmp(mask_treatment,'maskNaN')
                        R{k} = nan(size(R{k}));
                        R0(k) = NaN;
%                     elseif strcmp(mask_treatment,'maskEx') % extrapolate from the first point of whisker to the mask, just using the same polynomial fit. Extended 20% of the whole whisker at both ends
%                         q1 = linspace(-0.2, 1.2, floor(npoints*1.4));                        
%                         C1 = [polyval(px,q1); polyval(py,q1)];
%                         C2 = [polyval(pxm,q); polyval(pym,q)];
%                         P = Whisker.InterX(C1,C2);
%                         if size(P,2) > 1   % Don't need for faster version, which handles this.
%                             disp('Found more than 1 intersection of whisker and mask curves; using only first.')
%                             P = P(:,1);
%                         end
%                         if isempty(P)
%                             R{k} = nan(size(R{k}));
%                             R0(k) = NaN;
%                         else
%                             C1 = [polyval(px,0); polyval(py,0)]; % first point of the original whisker tracked
%                             R0(k) = -sqrt(sum((C1-P).^2)); % the distance from the first point to the mask. R0 in this case should be negative.
%                             R{k} = R{k} - R0(k);
%                         end
                    end
                else
                    % Find at what q the whisker is at (P(1),P(2)), i.e., q s.t. x(q)=P(1),y(q)=P(2).
                    % Doesn't match exactly (maybe due to roundoff error), so find closest.
                    C = C1 - repmat(P,[1 size(C1,2)]);
                    err = sqrt(C(1,:).^2 + C(2,:).^2);
                    ind2 = err==min(err);
                    R0(k) = R{k}(ind2);
                    R{k} = R{k} - R{k}(ind2);
                end
            end
            if nargout > 3
                varargout{1} = R0;
            end
        end
        
        function obj = fit_polys(obj)
            %
            % obj = fit_polys(obj)
            %
            % Parameterizes whisker for each frame as
            %
            %       c(q) = (x(q),y(q))
            %
            % where q = 0...1 and gives cumulative, normalized arc-length distance
            % along whisker.
            %
            % Then we fit 5th degree polynomials for both x and y:
            %
            % x(q) = B5q^5 +B4q^4 + B3q^3 + B2q^2 + B1q^1 +B0
            % y(q) = A5q^5 +A4q^4 + A3q^3 + A2q^2 + A1q^1 +A0
            %
            % for every whisker in obj.trajectoryIDs for every frame.
            %
            % Coefficients are stored in obj.polyFits.
            % The idea is to call fit_polys() once for each WhiskerTrial and
            % then save the new WhiskerTrial.
            %
            % The format of obj.polyFits is a cell array of length
            % length(obj.trajectoryIDs), one element per trajectory ID.
            % Each element of this cell array is an
            %
            
            % Changed to fit only after the mask. 2017/09/16 JK
            
            polyDegree = 5;
            
            numCoeff = polyDegree+1;
            numTid = length(obj.trajectoryIDs);
            fitted = cell(1,numTid);
            
            wpo = obj.whiskerPadOrigin;
            
            for h=1:numTid
                %                 disp(['Fitting for whisker ' int2str(obj.trajectoryIDs(h))])
                frameNums = cellfun(@(x) x{2}, obj.trackerData{h});
                nframes = length(frameNums);
                
                xp = zeros(nframes,numCoeff);
                yp = zeros(nframes,numCoeff);
                
                trajectoryData = obj.trackerData{h};
                
                % polyfit() gives warnings that indicate that we don't need such a high degree
                % polynomials. Turn off.
                %                 warning('off','MATLAB:polyfit:RepeatedPointsOrRescale');
                
                if exist('parfor','builtin')                
                    if strcmp(obj.trackerFileFormat,'whisker0')
                        whisker0Format = true;
                    else
                        whisker0Format = false;
                    end
                    parfor k=1:nframes
%                     for k=1:nframes
                        f = trajectoryData{k};
                        if numel(f{4}) > 1 % Tracker can sometimes (rarely) leave frame entries for a trajectory in whiskers file that have no pixels.
                            %                             [xp(k,:), yp(k,:), qp(k,:)] = doFits(f,R0(k));
                            %
                            %
                            x = f{4};
                            if whisker0Format==true
                                x = (x(1):x(2))';
                            end
                            
                            yy = f{5};
                            
                            % Make everything row vectors, to be consistent for polyfit, below.
                            if size(x,1) > size(x,2)
                                x = x';
                            end
                            if size(yy,1) > size(yy,2)
                                yy = yy';
                            end
                            
                            
                            % Check which end of the whisker is closer to the whisker pad origin; make
                            % sure that c(q) = (x(q),y(q)) pairs are moving away from follice as q increase:
                            x0 = x(1);
                            yy0 = yy(1);
                            
                            x1 = x(end);
                            yy1 = yy(end);
                            
                            if sqrt(sum((wpo-[x1 yy1]).^2)) < sqrt(sum((wpo-[x0 yy0]).^2))
                                % c(q_max) is closest to whisker pad origin, so reverse the (x,y) sequence
                                x = x(end:-1:1);
                                yy = yy(end:-1:1);
                            end
                            
                            % Applying the mask, if there is any 2017/09/16 JK
                            % This treatment affects x and yy only. 
                            if ~isempty(obj.polyFitsMask) 
                            % for multiple masks and whiskers, choose the
                            % mask that is closest to the point closest to wpo (calculated at just above this line) for safety
                            % (usually, it is better to have constraint on the order of whisker and mask (when numbering the whiskers and drawing masks)
                                if length(obj.polyFitsMask) > 1                                    
                                    wpo_dist = zeros(1,length(obj.polyFitsMask));
                                    for temp_m_ind = 1 : length(obj.polyFitsMask)
                                        fittedXMask = obj.polyFitsMask{temp_m_ind}{1};
                                        fittedYMask = obj.polyFitsMask{temp_m_ind}{2};
                                        if size(fittedXMask,1) > 1
                                            pxm = fittedXMask(k,:);
                                            pym = fittedYMask(k,:);
                                        else
                                            pxm = fittedXMask;
                                            pym = fittedYMask;
                                        end
                                        wpo_dist(temp_m_ind) = mean(sum(abs([x(1);yy(1)] - [polyval(pxm,linspace(0,1,100));polyval(pym,linspace(0,1,100))]))); % x and yy are already ordered to start from closest to wpo
                                    end
                                    [~, m_ind] = min(wpo_dist);
                                else 
                                    m_ind = 1;
                                end

                                if iscell(obj.maskTreatment)
                                    if length(obj.maskTreatment) ~= length(obj.trajectoryIDs)
                                        error('obj.maskTreatment and obj.trajectoryIDs must have the same length and matching entries.')
                                    end
                                    mask_treatment = obj.maskTreatment{m_ind};
                                else
                                    mask_treatment = obj.maskTreatment;
                                end

                                fittedXMask = obj.polyFitsMask{m_ind}{1};
                                fittedYMask = obj.polyFitsMask{m_ind}{2};
                                if size(fittedXMask,1) > 1
                                    pxm = fittedXMask(k,:);
                                    pym = fittedYMask(k,:);
                                else
                                    pxm = fittedXMask;
                                    pym = fittedYMask;
                                end

                                C1 = [x; yy];
                                C2 = [polyval(pxm,linspace(0,1,100)); polyval(pym,linspace(0,1,100))];
                                P = Whisker.InterX(C1,C2); % Find points where whisker and mask curves intersect. Slower but more
                                %  accurate version that isn't limited in resolution by the number of
                                %  points whisker and mask are evaluated at.
                                if size(P,2) > 1   % Don't need for faster version, which handles this.
                                    disp('Found more than 1 intersection of whisker and mask curves; using only first.')
                                    P = P(:,1);
                                end

                                %                 P = Whisker.InterXFast(C1,C2); % Find points where whisker and mask curves intersect. Much faster version
                                %                                                 % that is limited in resolution by the number of
                                %                                                 % points whisker and mask are evaluated at (i.e., by number of points in q).

                                if isempty(P)
                                    %
                                    % for debugging
                                    %                                    
%                                     disp(num2str(k))
                                    %
                                    %
                                    %
                                    % first, stretch the mask (30% for now) and see if there is any intersection
                                    disp('Stretching the mask fit 30% longer')
                                    C2 = [polyval(pxm,linspace(-0.3,1.3,100)); polyval(pym,linspace(-0.3,1.3,100))];
                                    P = Whisker.InterX(C1,C2);
                                    if size(P,2) > 1
                                        disp('Found more than 1 intersection of whisker and mask curves; using only first.')
                                        P = P(:,1);
                                    end
                                    if isempty(P)
                                        % if still the whisker and mask do not meet, stretch the whisker.
                                        % In order to do this, I need to first fit the whisker with existing data points.
                                        if length(x) <= polyDegree
                                            if strcmp(mask_treatment,'maskNaN')
                                            fprintf('No intersection with the mask, returning NaNs in frame #%d.\n', k)
                                            x = nan(size(x));
                                            yy = nan(size(yy));
                                            end % else x = x, yy = yy (no change)
                                        else
                                            coeffX = Whisker.polyfit(linspace(0,1,length(x)), x, polyDegree);
                                            coeffY = Whisker.polyfit(linspace(0,1,length(yy)), yy, polyDegree);
                                            % stretch whisker 30% to wpo.
                                            x = polyval(coeffX,linspace(-0.3,1,100));
                                            yy = polyval(coeffY,linspace(-0.3,1,100));
                                            C1 = [x;yy];
                                                P = Whisker.InterX(C1,C2);
                                            if size(P,2) > 1   % Don't need for faster version, which handles this.
                                                disp('Found more than 1 intersection of whisker and mask curves; using only first.')
                                                P = P(:,1);
                                            end
                                            if isempty(P)
                                                if strcmp(mask_treatment,'maskNaN')
                                                    fprintf('No intersection with the mask, returning NaNs in frame #%d.\n', k)
                                                    fprintf('No intersection after stretching mask and whisker, returning NaNs in frame #%d.\n', k)
                                                    x = nan(size(x));
                                                    yy = nan(size(yy));
                                                end
                                            else
                                                % starting from the point closest to the intersection (P)
                                                [~,c_ind] = min(abs([x;yy] - P));
                                                x = x(c_ind:end);
                                                yy = yy(c_ind:end);
                                            end
                                        end
                                    else
                                        % starting from the point closest to the intersection (P)
                                        [~,c_ind] = min(abs([x;yy] - P));
                                        x = x(c_ind:end);
                                        yy = yy(c_ind:end);
                                    end
                                else
                                    % starting from the point closest to the intersection (P)
                                    [~,c_ind] = min(abs([x;yy] - P));
                                    x = x(c_ind:end);
                                    yy = yy(c_ind:end);
                                end
                            end

                            % Need to fit x and y as function of radial
                            % distance (normalized to be [0,1]), not simply index values, since
                            % x values from the tracker are not necessarily
                            % evenly spaced.
                            %
                            s = cumsum(sqrt([0 diff(x)].^2 + [0 diff(yy)].^2));
                            q = s ./ max(s); % now [0,1].
                            
                            
                            if length(q) <= polyDegree
                                disp('Number of samples not more than polynomial order, returning NaNs.')
                                coeffX = nan(1,numCoeff);
                                coeffY = nan(1,numCoeff);
                            else
                                coeffX = Whisker.polyfit(q,x,polyDegree);
                                coeffY = Whisker.polyfit(q,yy,polyDegree);
                            end
                            xp(k,:) = coeffX;
                            yp(k,:) = coeffY;
                        else
                            xp(k,:) = nan(1,numCoeff);
                            yp(k,:) = nan(1,numCoeff);
                        end
                    end
                else % Do not have the Parallel Computing Toolbox
                    for k=1:nframes
                        %                     disp(['On frame ' int2str(k)])
                        f = trajectoryData{k};
                        if numel(f{4}) > 1 % Tracker can sometimes (rarely) leave frame entries for a trajectory in whiskers file that have no pixels.
                            [xp(k,:), yp(k,:)] = doFits(f,k);
                        else
                            xp(k,:) = nan(1,numCoeff);
                            yp(k,:) = nan(1,numCoeff);
                        end
                    end
                end
                fitted{h} = {xp,yp};
            end
            
            %             warning('on','MATLAB:polyfit:RepeatedPointsOrRescale');
            
            obj.polyFits = fitted;
            
            function [coeffX,coeffY] = doFits(frame,k) % SUBFUNCTION
                %
                %
                x = frame{4};
                if strcmp(obj.trackerFileFormat,'whisker0')
                    x = (x(1):x(2))';
                end
                
                yy = frame{5};
                
                % Make everything row vectors, to be consistent for polyfit, below.
                if size(x,1) > size(x,2)
                    x = x';
                end
                if size(yy,1) > size(yy,2)
                    yy = yy';
                end
                
                % Check which end of the whisker is closer to the whisker pad origin; make
                % sure that c(q) = (x(q),y(q)) pairs are moving away from follice as q increase:
                x0 = x(1);
                yy0 = yy(1);
                
                x1 = x(end);
                yy1 = yy(end);
                
                if sqrt(sum((wpo-[x1 yy1]).^2)) < sqrt(sum((wpo-[x0 yy0]).^2))
                    % c(q_max) is closest to whisker pad origin, so reverse the (x,y) sequence
                    x = x(end:-1:1);
                    yy = yy(end:-1:1);
                end
                
                % Applying the mask, if there is any 2017/09/16 JK
                % This treatment affects x and yy only. 
                if ~isempty(obj.polyFitsMask) 
                    % for multiple masks and whiskers, choose the
                    % mask that is closest to the point closest to wpo (calculated at just above this line) for safety
                    % (usually, it is better to have constraint on the order of whisker and mask (when numbering the whiskers and drawing masks)
                    if length(obj.polyFitsMask) > 1                                    
                        wpo_dist = zeros(1,length(obj.polyFitsMask));
                        for temp_m_ind = 1 : length(obj.polyFitsMask)
                            fittedXMask = obj.polyFitsMask{temp_m_ind}{1};
                            fittedYMask = obj.polyFitsMask{temp_m_ind}{2};
                            if size(fittedXMask,1) > 1
                                pxm = fittedXMask(k,:);
                                pym = fittedYMask(k,:);
                            else
                                pxm = fittedXMask;
                                pym = fittedYMask;
                            end
                            wpo_dist(temp_m_ind) = mean(sum(abs([x(1);yy(1)] - [polyval(pxm,linspace(0,1,100));polyval(pym,linspace(0,1,100))]))); % x and yy are already ordered to start from closest to wpo
                        end
                        [~, m_ind] = min(wpo_dist);
                    else 
                        m_ind = 1;
                    end
                    
                    if iscell(obj.maskTreatment)
                        if length(obj.maskTreatment) ~= length(obj.trajectoryIDs)
                            error('obj.maskTreatment and obj.trajectoryIDs must have the same length and matching entries.')
                        end
                        mask_treatment = obj.maskTreatment{m_ind};
                    else
                        mask_treatment = obj.maskTreatment;
                    end
                    
                    fittedXMask = obj.polyFitsMask{m_ind}{1};
                    fittedYMask = obj.polyFitsMask{m_ind}{2};
                    if size(fittedXMask,1) > 1
                        pxm = fittedXMask(k,:);
                        pym = fittedYMask(k,:);
                    else
                        pxm = fittedXMask;
                        pym = fittedYMask;
                    end

                    C1 = [x; yy];
                    C2 = [polyval(pxm,linspace(0,1,100)); polyval(pym,linspace(0,1,100))];
                    P = Whisker.InterX(C1,C2); % Find points where whisker and mask curves intersect. Slower but more
                    %  accurate version that isn't limited in resolution by the number of
                    %  points whisker and mask are evaluated at.
                    if size(P,2) > 1   % Don't need for faster version, which handles this.
                        disp('Found more than 1 intersection of whisker and mask curves; using only first.')
                        P = P(:,1);
                    end

                    %                 P = Whisker.InterXFast(C1,C2); % Find points where whisker and mask curves intersect. Much faster version
                    %                                                 % that is limited in resolution by the number of
                    %                                                 % points whisker and mask are evaluated at (i.e., by number of points in q).

                    if isempty(P)                                    
                        % first, stretch the mask (30% for now) and see if there is any intersection
                        disp('Stretching the mask fit 30% longer')
                        C2 = [polyval(pxm,linspace(-0.3,1.3,100)); polyval(pym,linspace(-0.3,1.3,100))];
                        P = Whisker.InterX(C1,C2);
                        if size(P,2) > 1
                            disp('Found more than 1 intersection of whisker and mask curves; using only first.')
                            P = P(:,1);
                        end
                        if isempty(P)
                            % if still the whisker and mask do not meet, stretch the whisker.
                            % In order to do this, I need to first fit the whisker with existing data points.
                            if length(x) <= polyDegree
                                if strcmp(mask_treatment,'maskNaN')
                                    fprintf('No intersection with the mask, returning NaNs in frame #%d.\n', k)
                                    x = nan(size(x));
                                    yy = nan(size(yy));
                                end % else x = x, yy = yy (no change)
                            else
                                coeffX = Whisker.polyfit(linspace(0,1,length(x)), x, polyDegree);
                                coeffY = Whisker.polyfit(linspace(0,1,length(yy)), yy, polyDegree);
                                % stretch whisker 30% to wpo.
                                x = polyval(coeffX,linspace(-0.3,1,round(length(x)*1.3)));
                                yy = polyval(coeffY,linspace(-0.3,1,round(length(yy)*1.3)));
                                C1 = [x;yy];
                                P = Whisker.InterX(C1,C2);
                                if size(P,2) > 1   % Don't need for faster version, which handles this.
                                    disp('Found more than 1 intersection of whisker and mask curves; using only first.')
                                    P = P(:,1);
                                end
                                if isempty(P)
                                    if strcmp(mask_treatment,'maskNaN')                                        
                                        frpintf('No intersection after stretching mask and whisker, returning NaNs in frame #%d.\n', k)
                                        x = nan(size(x));
                                        yy = nan(size(yy));
                                    end
                                else
                                    % starting from the point closest to the intersection (P)
                                    [~,c_ind] = min(abs([x;yy] - P));
                                    x = x(c_ind:end);
                                    yy = yy(c_ind:end);
                                    obj.stretched_whisker = [obj.stretched_whisker, k];
                                end
                            end
                        else
                            % starting from the point closest to the intersection (P)
                            [~,c_ind] = min(abs([x;yy] - P));
                            x = x(c_ind:end);
                            yy = yy(c_ind:end);
                            obj.stretched_mask = [obj.stretched_mask, k];
                        end
                    else
                        % starting from the point closest to the intersection (P)
                        [~,c_ind] = min(abs([x;yy] - P));
                        x = x(c_ind:end);
                        yy = yy(c_ind:end);
                    end
                end
                % Need to fit x and y as function of radial
                % distance (normalized to be [0,1]), not simply index values, since
                % x values from the tracker are not necessarily
                % evenly spaced.
                %
                s = cumsum(sqrt([0 diff(x)].^2 + [0 diff(yy)].^2));
                q = s ./ max(s); % now [0,1].
                
                
                if length(q) <= polyDegree
                    disp('Number of samples not more than polynomial order, returning NaNs.')
                    coeffX = nan(1,numCoeff);
                    coeffY = nan(1,numCoeff);
                else
                    coeffX = Whisker.polyfit(q,x,polyDegree);
                    coeffY = Whisker.polyfit(q,yy,polyDegree);
                end
                %                 disp(k); qq=linspace(0,1);
                %                 subplot(131); hold on; plot(x,yy,'k.-'); plot(polyval(coeffX,qq),polyval(coeffY,qq),'r.-');
                %                 title('Fitted vs measure whisker')
                %                 subplot(132); hold on; plot(q,x,'k.-'); plot(qq,polyval(coeffX,qq),'r.-');
                %                 title('X(q) vs. fitted, X''(q)')
                %                 subplot(133); hold on; plot(q,yy,'k.-'); plot(qq,polyval(coeffY,qq),'r.-');
                %                 title('Y(q) vs. fitted, Y''(q)')
                %                 pause; for z=1:3, subplot(1,2,z); cla; end
                
            end
        end
        
        %
        function obj = fit_polys_roi(obj,rad_lims)
            %
            % obj = fit_polys_roi(obj,rad_lims)
            %
            % Similar to obj.fit_polys() except that polynomials are fitted only
            % to whisker within a constant region of arc-length.
            %
            % INPUTS:
            %   rad_lims: If a 1x2 vector of format [startInPix stopInPix],
            %             then polynomials will be fitted for every trajectory ID
            %             over the longest segment within the interval [startInPix, stopInPix].
            %             Alternatively, rad_lims can be a cell array with as many elements as there are
            %             trajectory IDs, with each element a 1x2 vector giving the interval for one trajectory ID:
            %             {[startInPix_Tid0 stopInPix_Tid0],[startInPix_Tid1 stopInPix_Tid1],...
            %               [startInPix_TidN stopInPix_TidN]
            %             If rad_lims is a cell array, the elements of rad_lims and obj.trajectoryIDs must match.
            %
            %
            % If a mask will be specified to define the arc-length origin it must
            % be defined prior to calling this method (i.e. obj.polyFitsMask must be
            % populated).
            %
            % This method will call obj.poly_fits if it hasn't already been called.
            %
            % Coefficients are stored in obj.polyFitsROI.
            % The idea is to call fit_polys_roi() once for each WhiskerTrial and
            % then save the new WhiskerTrial.
            %
            %
%             polyDegree = 2;
            polyDegree = 5; % changed to fully capture whisker bending in different pole angles 2018/04/17 JK
            
            
            numCoeff = polyDegree+1;
            numTid = length(obj.trajectoryIDs);
            fitted = cell(1,numTid);
            
            if isempty(obj.polyFits)
                %                 disp('obj.polyFits is empty, calling obj.fit_polys; probably want save this WhiskerTrial object afterward.')
                obj.fit_polys;
            end
            
            if ~iscell(rad_lims)
                radLims = cell(1,numTid);
                for k=1:numTid
                    radLims{k} = rad_lims;
                end
            else
                radLims = rad_lims;
            end
            
            wpo = obj.whiskerPadOrigin;
            
            for h=1:numTid
                
                rstart = radLims{h}(1);
                rstop = radLims{h}(2);
                
                if rstart >= rstop
                    error('Invalid format of argument rad_lims.')
                end
                
                %                 disp(['Fitting ROI polys for whisker ' int2str(obj.trajectoryIDs(h))])
                frameNums = cellfun(@(x) x{2}, obj.trackerData{h});
                nframes = length(frameNums);
                
                xp = zeros(nframes,numCoeff);
                yp = zeros(nframes,numCoeff);
                qp = zeros(nframes,4); % First and last points in ROI along the [0,1] of full whisker, and first and last
                % points in units of pixels rather than normalized value. Can compute one from other
                % but this saves computation time later.
                
                trajectoryData = obj.trackerData{h};
                
                % Get arc-length origin previously determined by fit_polys():
                if isempty(obj.polyFitsMask)
                    R0 = zeros(1,nframes);
                else
%                     [~,~,~,R0] = obj.arc_length_theta_and_kappa(obj.trajectoryIDs(h));
                    [~,R0] = obj.arc_length_and_intersection(obj.trajectoryIDs(h)); % changed to an added function to make it faster 2017/04/03 JK
                end
                
                % polyfit() gives warnings that indicate that we don't need such a high degree
                % polynomials. Turn off.
                %                 warning('off','MATLAB:polyfit:RepeatedPointsOrRescale');
                
                if exist('parfor','builtin') % parfor to enhance speed (2017/04/03 JK)
                    if strcmp(obj.trackerFileFormat,'whisker0')
                        whisker0Format = true;
                    else
                        whisker0Format = false;
                    end
                    parfor k = 1 : nframes
%                     for k = 1 : nframes
                        f = trajectoryData{k};
                        x = f{4};
                        if whisker0Format == true
                            x = (x(1):x(2))';
                        end

                        yy = f{5};

                        % Make everything row vectors, to be consistent for polyfit, below.
                        if size(x,1) > size(x,2)
                            x = x';
                        end
                        if size(yy,1) > size(yy,2)
                            yy = yy';
                        end


                        % Check which end of the whisker is closer to the whisker pad origin; make
                        % sure that c(q) = (x(q),y(q)) pairs are moving away from follice as q increase:
                        x0 = x(1);
                        yy0 = yy(1);

                        x1 = x(end);
                        yy1 = yy(end);

                        if sqrt(sum((wpo-[x1 yy1]).^2)) < sqrt(sum((wpo-[x0 yy0]).^2))
                            % c(q_max) is closest to whisker pad origin, so reverse the (x,y) sequence
                            x = x(end:-1:1);
                            yy = yy(end:-1:1);
                        end

                        % We are fitting each whisker within
                        % an arc-length region of interest;
                        % find only those (x,y) pairs within the ROI, and fit to those
                        % pairs.  The arc-length origin needs to be determined by any mask if the
                        % user has defined one.
                        % If a mask is defined, subtract the arc-length at the intersection of the whisker
                        % and mask to (re)define the arc-length origin for fitting below:

                        s = cumsum(sqrt([0 diff(x)].^2 + [0 diff(yy)].^2));
                        q = s ./ max(s); % now [0,1].

                        % Find arc-length point closest to arc-length at intersection of whisker
                        % and intial fitted whisker:
                        %                 ind = find(s >= r0,1,'first'); % Or, first exceeding, rather than closest.
                        dist = (s-R0(k)).^2;
                        ind = find(dist==min(dist),1,'first');
                        if ~isempty(ind)
                            q = q - q(ind); % If there is a mask defined subtract arc-length where whisker crosses mask.
                            % If no mask is defined, r0 is set to 0 above.
                            s = s - s(ind);
                        end

                        ind = s >= rstart & s <= rstop;
                        q = q(ind);
                        s = s(ind);
                        x = x(ind);
                        yy = yy(ind);

                        if length(q) <= polyDegree
                            disp('Number of samples not more than polynomial order, returning NaNs.')
                            xp(k,:) = nan(1,numCoeff);
                            yp(k,:) = nan(1,numCoeff);
                            qp(k,:) = nan(1,4);
                        else
                            xp(k,:) = Whisker.polyfit(q,x,polyDegree);
                            yp(k,:) = Whisker.polyfit(q,yy,polyDegree);
                            qp(k,:) = [q(1) q(end) s(1) s(end)];
                        end
                    end
                else
                    for k=1:nframes
                        %                     disp(['On frame ' int2str(k)])
                        f = trajectoryData{k};
                        if numel(f{4}) > 1 % Tracker can sometimes (rarely) leave frame entries for a trajectory in whiskers file that have no pixels.
                            [xp(k,:), yp(k,:), qp(k,:)] = doFits(f,R0(k));
                        else
                            xp(k,:) = nan(1,numCoeff);
                            yp(k,:) = nan(1,numCoeff);
                            qp(k,:) = nan(1,4);
                        end
                    end
                end
                fitted{h} = {xp,yp,qp};
            end
            
            %             warning('on','MATLAB:polyfit:RepeatedPointsOrRescale');
            
            obj.polyFitsROI = fitted;
            
            function [coeffX,coeffY,qp] = doFits(frame,r0) % SUBFUNCTION
                %
                %
                x = frame{4};
                if strcmp(obj.trackerFileFormat,'whisker0')
                    x = (x(1):x(2))';
                end
                
                yy = frame{5};
                
                % Make everything row vectors, to be consistent for polyfit, below.
                if size(x,1) > size(x,2)
                    x = x';
                end
                if size(yy,1) > size(yy,2)
                    yy = yy';
                end
                
                
                % Check which end of the whisker is closer to the whisker pad origin; make
                % sure that c(q) = (x(q),y(q)) pairs are moving away from follice as q increase:
                x0 = x(1);
                yy0 = yy(1);
                
                x1 = x(end);
                yy1 = yy(end);
                
                if sqrt(sum((wpo-[x1 yy1]).^2)) < sqrt(sum((wpo-[x0 yy0]).^2))
                    % c(q_max) is closest to whisker pad origin, so reverse the (x,y) sequence
                    x = x(end:-1:1);
                    yy = yy(end:-1:1);
                end
                
                % We are fitting each whisker within
                % an arc-length region of interest;
                % find only those (x,y) pairs within the ROI, and fit to those
                % pairs.  The arc-length origin needs to be determined by any mask if the
                % user has defined one.
                % If a mask is defined, subtract the arc-length at the intersection of the whisker
                % and mask to (re)define the arc-length origin for fitting below:
                
                s = cumsum(sqrt([0 diff(x)].^2 + [0 diff(yy)].^2));
                q = s ./ max(s); % now [0,1].
                
                % Find arc-length point closest to arc-length at intersection of whisker
                % and intial fitted whisker:
                %                 ind = find(s >= r0,1,'first'); % Or, first exceeding, rather than closest.
                dist = (s-r0).^2;
                ind = find(dist==min(dist),1,'first');
                if ~isempty(ind)
                    q = q - q(ind); % If there is a mask defined subtract arc-length where whisker crosses mask.
                    % If no mask is defined, r0 is set to 0 above.
                    s = s - s(ind);
                end
                
                ind = s >= rstart & s <= rstop;
                q = q(ind);
                s = s(ind);
                x = x(ind);
                yy = yy(ind);
                
                if length(q) <= polyDegree
                    disp('Number of samples not more than polynomial order, returning NaNs.')
                    coeffX = nan(1,numCoeff);
                    coeffY = nan(1,numCoeff);
                    qp = nan(1,4);
                    return
                end
                
                coeffX = Whisker.polyfit(q,x,polyDegree);
                coeffY = Whisker.polyfit(q,yy,polyDegree);
                qp = [q(1) q(end) s(1) s(end)];
            end
        end
        
        function plot_whiskers(obj,frame,varargin)
            %
            %   plot_whiskers(obj,frame,varargin)
            %
            % varargin{1}: Optional vector of trajectory IDs.
            %   Can be empty matrix ([]) to allow access to varargin{2}.
            %
            % varargin{2}: Region of x-value pixels to plot in green color,
            %   to help evaluate regions of interest.
            %  Can be empty matrix ([]) to allow access to varargin{3}.
            %
            % varargin{3}: Plot color/symbol string for main whisker.
            %
            % varargin{4}: Plot color [r g b] vector for x-value ROI.
            %
            % varargin{5}: Pixel offset to add to all y-values, for use, e.g.,
            %   in aligning MATLAB plot() output with imshow().
            %
            %
            if nargin > 2
                tid = varargin{1};
                if isempty(tid)
                    tid = obj.trajectoryIDs;
                elseif ~isempty(setdiff(tid, obj.trajectoryIDs))
                    error('Could not find specified trajectory ID.')
                end
            else
                tid = obj.trajectoryIDs;
            end
            
            if nargin > 3
                XValColorLim = varargin{2};
            else
                XValColorLim = [];
            end
            
            if nargin > 4
                plotString = varargin{3};
            else
                plotString = 'k-';
            end
            
            if nargin > 5
                pixelOffset = varargin{4};
            else
                pixelOffset = 0;
            end
            
            hold on; axis ij
            for k=1:length(tid)
                %                 ind = tid(k)+1;
                ind = obj.trajectoryIDs==tid(k);
                frameNums = cellfun(@(x) x{2}, obj.trackerData{ind});
                indfr = frameNums==frame;
                if max(indfr) > 0
                    x = obj.trackerData{ind}{indfr}{4};
                    if strcmp(obj.trackerFileFormat,'whisker0')
                        x = x(1):x(2);
                    end
                    y = obj.trackerData{ind}{indfr}{5};
                    plot(x,y + pixelOffset,plotString)
                    if ~isempty(XValColorLim)
                        ind = x >= XValColorLim(1) & x <= XValColorLim(2);
                        if nargin > 5
                            plot(x(ind), y(ind), 'LineStyle','-', 'Color',varargin{4})
                        else
                            plot(x(ind), y(ind), 'g-')
                        end
                    end
                end
            end
        end
        
        
        function plot_whisker_time_projection(obj, tid, varargin)
            %
            %   plot_whisker_time_projection(obj, tid, varargin)
            %
            % tid: trajectory ID.  Only a single ID is allowed.
            %
            % varargin{1}: Plot color/symbol string.
            %
            % varargin{2}: Optional 2 x 1 vector giving starting and ending times (in seconds) to include in
            %               returned image, inclusive, starting with 0.
            %               Of format: [startTimeInSec endTimeInSec].
            %
            if numel(tid) > 1
                error('Only a single trajectory ID is alowed.')
            end
            
            if nargin > 2
                plotString = varargin{1};
            else
                plotString = 'k-';
            end
            
            t = obj.get_time(tid);
            
            if nargin > 3
                restrictTime = varargin{2};
                if restrictTime(2) <= restrictTime(1)
                    error('Invalid format for varargin{2}.')
                elseif max(restrictTime) > max(t)
                    disp('Warning: varargin{2} exceeds max time; setting to max.')
                    restrictTime(restrictTime==max(restrictTime)) = max(t);
                    if restrictTime(1)==restrictTime(2)
                        error('varargin{2}: Both times exceed max time.')
                    end
                elseif min(restrictTime < 0)
                    disp('varargin{2}: times start at 0.')
                end
            else
                restrictTime = [min(t) max(t)];
            end
            
            frameInds = find(t >= restrictTime(1) & t <= restrictTime(2));
            
            hold on; axis ij
            
            ind = obj.trajectoryIDs==tid;
            if max(ind) < 1
                error('Could not find specified trajectory ID.')
            end
            
            for f=frameInds %1:nframes
                x = obj.trackerData{ind}{f}{4};
                if numel(x) > 1
                    if strcmp(obj.trackerFileFormat,'whisker0')
                        x = x(1):x(2);
                    end
                    y = obj.trackerData{ind}{f}{5};
                    plot(x,y,plotString)
                end
            end
        end
        
        function r = whisker_time_projection_bitmap(obj, tid, image_dimensions, varargin)
            %
            %   r = whisker_time_projection_bitmap(obj, tid, image_dimensions, varargin)
            %
            % tid: trajectory ID.  Only a single ID is allowed.
            %
            % varargin{1}: Optional integer value to set whisker TID pixels to in the returned image.
            % varargin{2}: Optional 2 x 1 vector giving starting and ending times (in seconds) to include in
            %               returned image, inclusive, starting with 0.
            %               Of format: [startTimeInSec endTimeInSec].
            %
            % IMAGE LOSES WHISKER TRACKER'S SUB-PIXEL RESOLUTION, AS VALUES ARE ROUNDED!!
            %
            %
            if numel(tid) > 1
                error('Only a single trajectory ID is alowed.')
            end
            
            if numel(image_dimensions) ~= 2
                error('Argument image_dimensions must be of form [numXPix numYPix].')
            end
            
            if nargin > 3
                pixVal = varargin{1};
            else
                pixVal = 1;
            end
            
            ind = obj.trajectoryIDs==tid;
            if max(ind) < 1
                error('Could not find specified trajectory ID.')
            end
            
            t = obj.get_time(tid);
            
            if nargin > 4
                restrictTime = varargin{2};
                if restrictTime(2) <= restrictTime(1)
                    error('Invalid format for varargin{2}.')
                elseif max(restrictTime) > max(t)
                    disp('Warning: varargin{2} exceeds max time; setting to max.')
                    restrictTime(restrictTime==max(restrictTime)) = max(t);
                    if restrictTime(1)==restrictTime(2)
                        error('varargin{2}: Both times exceed max time.')
                    end
                elseif min(restrictTime < 0)
                    disp('varargin{2}: times start at 0.')
                end
            else
                restrictTime = [min(t) max(t)];
            end
            
            frameInds = find(t >= restrictTime(1) & t <= restrictTime(2));
            
            r = ones(image_dimensions(2),image_dimensions(1));
            
            for f=frameInds
                x = obj.trackerData{ind}{f}{4};
                if numel(x)==2
                    if strcmp(obj.trackerFileFormat,'whisker0')
                        x = x(1):x(2);
                    end
                    y = round(obj.trackerData{ind}{f}{5});
                    x = x + 1; % tracker's image coordinates are zero-based.
                    y = y + 1; % tracker's image coordinates are zero-based.
                    for n=1:length(x)
                        r(y(n),x(n)) = pixVal;
                    end
                    
                end
            end
        end
        
        
        
    end
    
    methods % Dependent property methods; cannot have attributes.
        
        function value = get.numFramesEachTrajectory(obj)
            value = cellfun(@length, obj.trackerData);
        end
        
        function value = get.allFrameNums(obj)
            value = unique(cell2mat(cellfun(@getFrames, obj.trackerData, 'UniformOutput',false)));
            
            function r = getFrames(c)
                r = cellfun(@(x) x{2}, c);
            end
        end
        
        function value = get.numUniqueFrames(obj)
            value = length(obj.allFrameNums);
        end
        
        function value = get.whiskerPadOrigin(obj)
            % Whisker pad "origin" will be corner of 45 deg triangle
            % made with corners of retangular image on the side of the
            % face.
            %
            % Image coordinates must have the top left corner as (0,0).
            %
            xdim = obj.imagePixelDimsXY(1);
            ydim = obj.imagePixelDimsXY(2);
            
            if strcmp(obj.faceSideInImage, 'top')
                value = [xdim/2 -xdim/2];
            elseif strcmp(obj.faceSideInImage, 'bottom')
                value = [xdim/2 ydim+xdim/2];
            elseif strcmp(obj.faceSideInImage, 'left')
                value = [-ydim/2 ydim/2];
            elseif strcmp(obj.faceSideInImage, 'right')
                value = [xdim+ydim/2 ydim/2];
            else
                error('Invalid value of obj.faceSideInImage.')
            end
            
            % Also, if needed can set obj.faceSideInImage to an
            % image point instead of a string and return that here.
        end
        
    end
    
    methods (Static = true)
%         function obj = loadobj(r)
%             %
%             %   obj = loadobj(r)
%             %
%             %
%             try
%                 obj = Whisker.WhiskerTrial;
%             catch
%                 obj = Whisker.WhiskerTrial_2pad;
%             end
%             obj.trialNum = r.trialNum;
%             obj.trialType = r.trialType;
%             obj.whiskerNames = r.whiskerNames;
%             obj.trajectoryIDs = r.trajectoryIDs;
%             obj.trackerData = r.trackerData;
%             obj.trackerFrames = r.trackerFrames;
%             obj.faceData = r.faceData;
%             obj.framePeriodInSec = r.framePeriodInSec;
%             obj.mouseName = r.mouseName;
%             obj.sessionName = r.sessionName;
%             obj.trackerFileName = r.trackerFileName;
%             obj.useFlag = r.useFlag;
%             obj.stretched_mask = r.stretched_mask;
%             obj.stretched_whisker = r.stretched_whisker; 
% 
%             % For properties below, need to check if properties exist,
%             % for backwards compatability, since in early (~2008) versions
%             % files may have been saved before these properties existed.
%             % At some point can delete these if-else statements as older
%             % objects become unused.
%             if isfield(r,'pxPerMm')
%                 obj.pxPerMm = r.pxPerMm;
%             else
%                 obj.pxPerMm = 22.68;
%             end
%             if isfield(r,'imagePixelDimsXY')
%                 obj.imagePixelDimsXY = r.imagePixelDimsXY;
%             else
%                 obj.imagePixelDimsXY = [150 200];
%             end
%             if isfield(r,'polyFits')
%                 obj.polyFits = r.polyFits;
%             else
%                 obj.polyFits = {};
%             end
%             if isfield(r,'polyFitsMask')
%                 obj.polyFitsMask = r.polyFitsMask;
%             else
%                 obj.polyFitsMask = {};
%             end
%             if isfield(r,'polyFitsROI')
%                 obj.polyFitsROI = r.polyFitsROI;
%             else
%                 obj.polyFitsROI = {};
%             end
%             if isfield(r,'maskTreatment')
%                 obj.maskTreatment = r.maskTreatment;
%             else
%                 obj.maskTreatment = 'maskNaN';
%             end
%             if isfield(r,'trackerFileFormat')
%                 obj.trackerFileFormat = r.trackerFileFormat;
%             else
%                 obj.trackerFileFormat = 'whisker0';
%             end
%             if isfield(r,'faceSideInImage')
%                 obj.faceSideInImage = r.faceSideInImage;
%             else
%                 obj.faceSideInImage = 'top';
%             end
%             if isfield(r,'protractionDirection')
%                 obj.protractionDirection = r.protractionDirection;
%             else
%                 obj.protractionDirection = 'rightward';
%             end
%             if isfield(r,'barPos')
%                 obj.barPos = r.barPos;
%             else
%                 obj.barPos = [];
%             end
%             if isfield(r,'barRadius')
%                 obj.barRadius = r.barRadius;
%             else
%                 obj.barRadius = 17;
%             end
%             if isfield(r,'barPosOffset')
%                 obj.barPosOffset = r.barPosOffset;
%             else
%                 obj.barPosOffset = [0 0];
%             end
%         end
    end
    
end


