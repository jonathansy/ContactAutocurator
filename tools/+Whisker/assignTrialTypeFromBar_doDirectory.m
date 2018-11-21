function assignTrialTypeFromBar_doDirectory(d,outfn)
%
%  d: directory path name as string.
%  outfn: string giving full-path file name for text file output. If full-path is not given
%         file will be created in the directory d.
%   
%   Reads in all .bar files and makes text file with trial type (based on pole position)
%   assigned from bar positions for all files in directory d.
%
%
% DHO, 11/09.
%

% d='C:\Documents and Settings\oconnord\My Documents\MATLAB\testMeasurements\';

if ~strcmp(d(end), '\')
    d = [d '\'];
end

currentDir = pwd;
cd(d) 

fnall = dir([d '*bar']);
 
% tiffnames = dir([d '*tif']);
% tiffnames = arrayfun(@(x) x.name, tiffnames, 'UniformOutput',false);

nfiles = length(fnall);

if ~isempty(fnall)
    
    if exist(outfn,'file')
        disp(['File ' outfn ' exists---overwriting.'])
    end
    
    fid = fopen(outfn,'w');
    if fid < 0 
        error(['Could not open output file ' outfn])
    end     
    
    for k=1:nfiles
%         disp(['Processing file ' int2str(k) ' of ' int2str(nfiles)])
        fn = fnall(k).name;
        
        [trialType, meanBarPos] = Whisker.assignTrialTypeFromBar(fn);
        
%         if trialType==1
%             trialTypeString = 'G';
%         elseif trialType==0
%             trialTypeString = 'N';
%         else
%             error('Invalid trialType returned.')
%         end
        
        imageFileNum = fn((end-6):(end-4));
        
%         disp(['trialType=' trialTypeString ', meanBarPos=' num2str(meanBarPos)])
        fprintf(fid,'%s\n',[imageFileNum ' ' int2str(trialType) ' ' num2str(meanBarPos)]);
        
    end
end

cd(currentDir)






