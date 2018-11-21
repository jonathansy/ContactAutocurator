function writeFile_Whisk2Commands(d,outfn)
%
%  d: directory path name as string.
%   
%  outfn: string giving name of text file to output. Will be located in directory d.
%   Can be ommitted for default naming.
%
%   Makes a text file of whisk commands, one line per TIFF file in directory.
%
%   Will not overwrite exist file of same name.
%
%
% DHO, 1/09.
%

% d='C:\Documents and Settings\dan\My Documents\work\full\';
% outfn = 'whisk2_commands.txt';
% Whisker.writeFile_Whisk2Commands(d,outfn)
%

if ~strcmp(d(end), filesep)
    d = [d filesep];
end

% If no output file name is given, make default based on lowest-level directory:
if nargin==1
   ind = findstr(d, '\');
   if length(ind)==1
       dirname = d(1:(end-1));
   elseif length(ind) > 1
       dirname = d((ind(end-1)+1):(ind(end)-1));
   else
       error('Cannot parse bottom-level directory name.')
   end
   outfn = ['whisk2Commands_' dirname '.txt']; 
end


currentDir = pwd;
cd(d) 

fnall = dir([d '*tif']);
% fnall = dir([d '*seq']);

tiffnames = arrayfun(@(x) x.name, fnall, 'UniformOutput',false);
prefixes = arrayfun(@(x) x.name(1:(end-4)), fnall, 'UniformOutput',false);

nfiles = length(tiffnames);

if exist(outfn, 'file')
    outfn = [outfn '_2'];
    if exist(outfn, 'file')
        error(['Output file ' outfn ' exists.'])
    end
end

if ~isempty(tiffnames)
    fid = fopen(outfn,'w');
    for k=1:nfiles
%         disp(['Processing file ' int2str(k) ' of ' int2str(nfiles)]) 
        fn = tiffnames{k};
        fnprefix = prefixes{k};
        
%         if ~isempty(strfind(fn,'-cropContra'))
%             fprintf(fid,'whisk %s %s --no-traj --no-bar\n', fn, fnprefix);
%         end

%         if ~isempty(strfind(fn,'-cropIpsi'))
%             fprintf(fid,'whisk %s %s --no-traj --no-bar\n', fn, fnprefix);
%         end

          fprintf(fid,'whisk %s %s --no-traj --no-bar\n', fn, fnprefix);
            
    end
    fclose(fid)
end

cd(currentDir)






