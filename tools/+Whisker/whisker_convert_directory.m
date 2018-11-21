function whisker_convert_directory(d,format_string,suffix_string)
%
%   USAGE:
%
%   whisker_convert_directory(d,format_string)
%   whisker_convert_directory(d,format_string,suffix_string)
%
%   INPUTS:
%
%   d: directory path name as string. 
%   format_string: 'whisk1' for text, 'whiskbin1' for binary, 'whiskpoly1'
%                   for polynomial format.  See 'whisker_convert -h' for info.
%                   Note that conversion between
%                   'whisk1' and 'whiskbin1' formats is lossless but the
%                   conversion to 'whiskpoly1' discards original tracked
%                   (x,y) pair data. 
%   suffix_string: Optional argument giving string suffix to append to
%                   each file name after conversion. If not given, the
%                   original file is overwritten.
% 
%   
%   Calls whisker_convert on .whiskers file in directory d.
%   The whisker_convert executable must be on the Windows path or in the
%   directory d.
%

if nargin < 3
    suffix_string = '';
end

if ~ischar(d) || ~ischar(format_string) || ~ischar(suffix_string)
    error('All arguments must be strings.')
end

if ~any(strcmp(format_string,{'whisk1','whiskbin1','whiskpoly1'}))
    error('Invalid ''format_string'' argument.')
end

if ~strcmp(d(end), filesep)
    d = [d filesep];
end

currentDir = pwd;
cd(d) 

fnall = dir([d '*.whiskers']);
nfiles = length(fnall);

if ~isempty(fnall)
    for k=1:nfiles
        disp(['Processing file ' int2str(k) ' of ' int2str(nfiles)]) 
        fn = fnall(k).name;
        outfn = [fn(1:(end-9)) suffix_string '.whiskers'];
        syscall = ['whisker_convert ' fn ' ' outfn ' ' format_string];
%         disp(syscall)
        [status,result] = system(syscall);
    end
end

cd(currentDir)






