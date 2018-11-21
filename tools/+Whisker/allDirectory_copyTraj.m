function allDirectory_copyTraj(d,varargin)
%
%
%
%   USAGE:
%
%
%   INPUTS:
%
%   d: Directory path name as string. 
%  
%     
%   Optional parameter/value pair arguments:
%
%           'include_files': Optional cell array of strings giving file name prefixes 
%                           of files in directory 'd' to process. Files will be processed
%                           in the order they are given within this cell array. *NOTE*: If
%                           this argument is not given, *all* '_WT.mat' files in directory
%                           'd' will be processed.
%
%           'ignore_files': Optional cell array of strings giving file name prefixes 
%                           (i.e., file names without the '_WT.mat' suffix/extension) to ignore.
%                           Trumps 'include_files' argument.
%
%
%           'trajectoryIDPairs': An Nx2 matrix where each row is of form: [tid_to_copy tid_target].
%
%           'follicleExtrapDistInPix': Distance to extrapolate past the end of the tracked whisker
%                              in order to estimate follicle coordinates. If this argument is 
%                              given, follicle position will be estimated. Default is not to estimate.
%                              Presently can only give one value, which will be used for all TIDs. Need to
%                              improve this.
%
%   DESCRIPTION:
%   
%   Requires WhiskerSignalTrial objects to be saved, as .mat files, in the 
%   directory specified by argument 'd'.  These files are read in one at a time and modified
%   by copying trajectories, then saved to disk by overwriting the original file.
%   
%
% 3/10, DHO.
%

p = inputParser; 

p.addRequired('d', @ischar);
p.addParamValue('include_files', {}, @(x) all(cellfun(@ischar,x)));
p.addParamValue('ignore_files', {}, @(x) all(cellfun(@ischar,x)));
p.addParamValue('trajectoryIDPairs', [], @(x) isempty(x) || size(x,2)==2);
p.addParamValue('follicleExtrapDistInPix', NaN, @isnumeric);

p.parse(d,varargin{:});

disp 'List of all arguments:'
disp(p.Results)


if ~strcmp(d(end), filesep)
    d = [d filesep];
end

currentDir = pwd;
cd(d) 

fnall = arrayfun(@(x) x.name(1:(end-8)), dir([d '*_WST.mat']),'UniformOutput',false);

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

nfiles = length(fnall);
ncopy = size(p.Results.trajectoryIDPairs);

if ~isempty(fnall)
    for k=1:nfiles
        fn = fnall{k};
        disp(['Processing ''_WST.mat'' file '  fn ', ' int2str(k) ' of ' int2str(nfiles)]) 
        
        load([fn '_WST.mat'],'ws');
        
        for q=1:ncopy
            tid_to_copy = p.Results.trajectoryIDPairs(q,1);
            tid_target = p.Results.trajectoryIDPairs(q,2);
        	Whisker.copy_traj(ws,tid_to_copy,tid_target);
        end
        
        if ~isnan(p.Results.follicleExtrapDistInPix)
            ws.recompute_cached_follicle_coords(p.Results.follicleExtrapDistInPix,ws.trajectoryIDs); % Right now fits even "contact detection" tids, need to change format***
        end
        
        outfn = fn;
        
        save([outfn '_WST.mat'],'ws');
    end
end

cd(currentDir)






