function makeAllDirectory_WhiskerTrial_2pad(d,trajectory_nums,varargin)
%
%   makeAllDirectory_WhiskerTrial(d,trajectory_nums,varargin)
%
%   USAGE:
%
%
%   INPUTS:
%
%   d: Directory path name as string.
%
%   trajectory_nums: Vector (or integer) of trajectory numbers to
%                    load in from the .whiskers files (e.g. 0, or [0 1 2]).
%                    Trajectories not in this argument are not loaded from
%                    the .whiskers file.
%
%
%
%   Optional parameter/value pair arguments (can be in any order):
%
%           'include_files': Optional cell array of strings giving file name prefixes
%                           of files in directory 'd' to process. Files will be processed
%                           in the order they are given within this cell array. *NOTE*: If
%                           this argument is not given, *all* .whiskers files in directory
%                           'd' will be processed.
%
%           'ignore_files': Optional cell array of strings giving file name prefixes
%                           (i.e., file names without the '.whiskers' extension) to ignore.
%                           Trumps 'include_files' argument.
%
%           'trial_nums': A vector of trial numbers to associate with each file, one element
%                         per trial, in the same order as elements of 'include_files'. This argument
%                         should be used only very carefully if this
%                         function is called without 'include_files' in order to process each
%                         .whiskers file in directory 'd', because the order the files are processed
%                         may or may not match the order of elements in 'trial_nums'.
%
%           'barRadius': The radius of the pole in pixel units. Default is 17.
%
%           'barPosOffset': Displacement from the center of the large pole to the 'contact point'
%                        (either on the edge of the large pole or small pole). Units of pixels.
%                         Default is [0 0] (no offset).
%
%           'faceSideInImage': One of: 'right','left','top','bottom'. Default is 'top'.
%
%           'protractionDirection':  One of: 'downward','upward','rightward','leftward'. Default is 'rightward'.
%
%           'imagePixelDimsXY': An 1x2 vector, e.g. [150 200].
%
%           'pxPerMm': The number of pixels per mm. Default is 22.68.
%
%           'framePeriodInSec': 0.002 for 500 Hz, 0.001 for 1000 Hz. Default is 0.002.
%
%           'mask': 2xN matrix giving x-values (in first row) and y-values (in second row)
%                   to fit a mask to for purposes of defining the arc-length origin. If a mask
%                   is given, arc-length zero occurs at the intersection of the mask and the whisker.
%                   If no mask is given, arc-length zero is the first tracked point on the whisker.
%                   Default is no mask.
%
%           'mouseName': Arbitrary string.
%
%           'sessionName': Arbitrary string.
%
%
%   DESCRIPTION:
%
%   Calls WhiskerTrial constructor on all .whiskers files in directory d, or all those specified
%   by argument 'include_list' if given,
%   excluding those in ignore_files. Saves WhiskerTrial objects, one per
%   .mat file, with same name as .whiskers file but with '_WT' appended
%   to name.  Existing files with the same names will be overwritten.
%
%
%
% 3/10, DHO.
%

% Sometimes there is an error with .whiskers file. In that or any other
% case when WhiskerTrial does not work correctly, throw an error
% (fname_errorWT.mat file with trial_num in it)
% 2017/05/15 JK

% Some updates for 2pad (also in WhiskerTrial_2pad):
% realtime pole axis detection including during pole moving frames
% automatic bar position for 90 degrees poles
% distance-to-pole calculation
% input parser for parameters
% 2018/04/13 JK

p = inputParser;

p.addRequired('d', @ischar);
p.addRequired('trajectory_nums', @isnumeric);
p.addParameter('include_files', {}, @(x) all(cellfun(@ischar,x)));
p.addParameter('ignore_files', {}, @(x) all(cellfun(@ischar,x)));
p.addParameter('trial_nums', NaN, @isnumeric);
p.addParameter('barRadius', 0.3, @(x) x>0);
p.addParameter('barPosOffset', [0 0], @(x) isnumeric(x) && numel(x)==2);
p.addParameter('faceSideInImage', 'bottom', @(x) any(strcmpi(x,{'right','left','top','bottom'})));
p.addParameter('protractionDirection', 'rightward', @(x) any(strcmpi(x,{'downward','upward','leftward','rightward'})));
p.addParameter('imagePixelDimsXY', [150 200], @(x) isnumeric(x) && numel(x)==2 );
p.addParameter('pxPerMm', 17.81, @(x) x>0);
p.addParameter('framePeriodInSec',1/311.24,@isnumeric);
p.addParameter('mask',[],@(x) isnumeric(x) | iscell(x));
p.addParameter('mouseName', '', @ischar);
p.addParameter('sessionName', '', @ischar);
p.addParameter('behavior', [], @(x) isa(x,'Solo.BehavTrial2padArray'));

p.parse(d,trajectory_nums,varargin{:});

disp 'List of all arguments:'
disp(p.Results)


if ~strcmp(d(end), filesep)
    d = [d filesep];
end

currentDir = pwd;
cd(d)

fnall = arrayfun(@(x) x.name(1:(end-9)), dir([d '*.whiskers']),'UniformOutput',false);

if ~isempty(p.Results.include_files) % Make sure files are found. If not, ignored.
    ind = ismember(p.Results.include_files,fnall);
    fnall = p.Results.include_files(ind);
    if sum(ind) ~= numel(ind)
        disp('The following files in ''include_files'' were not found in directory ''d'' and will be skipped:')
        disp(p.Results.include_files(~ind))
    end
end

if ~isempty(p.Results.ignore_files)
    ind = ~ismember(fnall,p.Results.ignore_files);
    fnall = fnall(ind);
end

inBoth = intersect(p.Results.include_files,p.Results.ignore_files);
if ~isempty(inBoth)
    disp('The following files were given in BOTH ''include_files'' and ''ignore files'' and will be ignored:')
    disp(inBoth)
end

% % % % if ~all(isnan(p.Results.trial_nums)) && isempty(p.Results.include_files)
% % % %     disp('WARNING: Argument ''trial_nums'' was given without specifying files in ''include_list''; order depends on operating system.')
% % % % end
% % % % if numel(p.Results.trial_nums)==1
% % % %     trial_nums = repmat(p.Results.trial_nums,1,nfiles);
% % % % elseif numel(p.Results.trial_nums) ~= nfiles
% % % %     error('Length of argument ''trial_nums'' does not match number of files specified.')
% % % % else
% % % %     trial_nums = p.Results.trial_nums;
% % % % end

% fnall = {'86'};
nfiles = numel(fnall);


if ~isempty(fnall)
    if exist('parfor','builtin') && ~contains(p.Results.sessionName, 'spont') % Parallel Computing Toolbox is installed.
        parfor k=1:nfiles
%         for k=1:nfiles
            fn = fnall{k};
            disp(['Processing .whiskers file ' fn ', ' int2str(k) ' of ' int2str(nfiles)])
            if ~isempty(p.Results.behavior)
                bInd = find(cellfun(@(x) x.trialNum == str2double(fn),p.Results.behavior.trials));
                %%
                %%
                bInd = bInd(1); % Temporary solution because of same trialNum of 'oo' trialType trials with one trial before
                %%
                %%
                w = Whisker.WhiskerTrial_2pad(fn, p.Results.behavior.trials{bInd}.trialNum, p.Results.trajectory_nums, 'mouseName', p.Results.mouseName, 'sessionName',...
                    p.Results.sessionName, 'trialType', p.Results.behavior.trials{bInd}.trialType, 'angle', p.Results.behavior.trials{bInd}.servoAngle, ...
                    'apUpPosition', p.Results.behavior.trials{bInd}.motorApPosition, 'radialDistance', p.Results.behavior.trials{bInd}.motorDistance, 'barRadius', p.Results.barRadius, 'pxPerMm', p.Results.pxPerMm);

                w.barPosOffset = p.Results.barPosOffset;
                w.faceSideInImage = p.Results.faceSideInImage;
                w.protractionDirection = p.Results.protractionDirection;
                w.imagePixelDimsXY = p.Results.imagePixelDimsXY;                
                w.framePeriodInSec = p.Results.framePeriodInSec;
                if ~isempty(p.Results.mask)
                    if iscell(p.Results.mask)
                        for q=1:numel(w.trajectoryIDs)
                            w.set_mask_from_points(w.trajectoryIDs(q),p.Results.mask{q}(1,:),p.Results.mask{q}(2,:));
                        end
                    else
                        w.set_mask_from_points(w.trajectoryIDs,p.Results.mask(1,:),p.Results.mask(2,:));
                    end
                end
            else
                w = Whisker.WhiskerTrial_2pad(fn, str2double(fn), p.Results.trajectory_nums, 'mouseName', p.Results.mouseName, 'sessionName', p.Results.sessionName);

                w.faceSideInImage = p.Results.faceSideInImage;
                w.protractionDirection = p.Results.protractionDirection;
                w.imagePixelDimsXY = p.Results.imagePixelDimsXY;
                w.pxPerMm = p.Results.pxPerMm;
                w.framePeriodInSec = p.Results.framePeriodInSec;
                if ~isempty(p.Results.mask)
                    if iscell(p.Results.mask)
                        for q=1:numel(w.trajectoryIDs)
                            w.set_mask_from_points(w.trajectoryIDs(q),p.Results.mask{q}(1,:),p.Results.mask{q}(2,:));
                        end
                    else
                        w.set_mask_from_points(w.trajectoryIDs,p.Results.mask(1,:),p.Results.mask(2,:));
                    end
                end
            end

            outfn = [fn '_WT.mat'];
            pctsave(outfn,w)
        end
    else
        for k=1:nfiles
            fn = fnall{k};
            disp(['Processing .whiskers file ' fn ', ' int2str(k) ' of ' int2str(nfiles)])
            if ~isempty(p.Results.behavior)
                bInd = find(cellfun(@(x) x.trialNum == str2double(fn),p.Results.behavior.trials));
                %%
                %%
                bInd = bInd(1); % Temporary solution because of same trialNum of 'oo' trialType trials with one trial before
                %%
                %%
                w = Whisker.WhiskerTrial_2pad(fn, p.Results.behavior.trials{bInd}.trialNum, p.Results.trajectory_nums, 'mouseName', p.Results.mouseName, 'sessionName',...
                    p.Results.sessionName, 'trialType', p.Results.behavior.trials{bInd}.trialType, 'angle', p.Results.behavior.trials{bInd}.servoAngle, ...
                    'apUpPosition', p.Results.behavior.trials{bInd}.motorApPosition, 'radialDistance', p.Results.behavior.trials{bInd}.motorDistance);

                w.barRadius = p.Results.barRadius;
                w.barPosOffset = p.Results.barPosOffset;
                w.faceSideInImage = p.Results.faceSideInImage;
                w.protractionDirection = p.Results.protractionDirection;
                w.imagePixelDimsXY = p.Results.imagePixelDimsXY;
                w.pxPerMm = p.Results.pxPerMm;
                w.framePeriodInSec = p.Results.framePeriodInSec;
                if ~isempty(p.Results.mask)
                    if iscell(p.Results.mask)
                        for q=1:numel(w.trajectoryIDs)
                            w.set_mask_from_points(w.trajectoryIDs(q),p.Results.mask{q}(1,:),p.Results.mask{q}(2,:));
                        end
                    else
                        w.set_mask_from_points(w.trajectoryIDs,p.Results.mask(1,:),p.Results.mask(2,:));
                    end
                end
            else
                w = Whisker.WhiskerTrial_2pad(fn, str2double(fn), p.Results.trajectory_nums, 'mouseName', p.Results.mouseName, 'sessionName', p.Results.sessionName);

                w.faceSideInImage = p.Results.faceSideInImage;
                w.protractionDirection = p.Results.protractionDirection;
                w.imagePixelDimsXY = p.Results.imagePixelDimsXY;
                w.pxPerMm = p.Results.pxPerMm;
                w.framePeriodInSec = p.Results.framePeriodInSec;
                if ~isempty(p.Results.mask)
                    if iscell(p.Results.mask)
                        for q=1:numel(w.trajectoryIDs)
                            w.set_mask_from_points(w.trajectoryIDs(q),p.Results.mask{q}(1,:),p.Results.mask{q}(2,:));
                        end
                    else
                        w.set_mask_from_points(w.trajectoryIDs,p.Results.mask(1,:),p.Results.mask(2,:));
                    end
                end
            end

            outfn = [fn '_WT.mat'];
            save(outfn,'w');
        end
    end
end

cd(currentDir)
end

function pctsave(outfn,w)
save(outfn,'w');
end





