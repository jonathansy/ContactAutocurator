function [r, trackerFileFormat] = load_whiskers_file(filename)
%
% function whiskers = load_whiskers_file(filename)
%
%   filename:  String giving file name of a .whiskers file from
%       output from the whisker tracker.
%
%
%   r:  If filename is in the binary format ("whiskbin1") or the
%       *new* text format ("whisker1"),
%       r is cell array with each element
%       corresponding to a single frame, with data:
%       {frameNum, segID, xdat, ydat, thickdat, scoredat}.
%
%       If filename is a .whiskers file the *old* text format
%       ("whisker0"), r is cell array with each element
%       corresponding to a single frame, with data:
%       {frameNum, segID, xdat, ydat, thickdat, scoredat}.
%
%   trackerFileFormat: String giving type of tracker data format.
%       One of: 'whiskbin1','whisker1', or 'whisker0'.
%
%
% 2/10, DHO.
%

if ~exist(filename,'file')
    error(['File ' filename ' could not be found.'])
end


fid = fopen(filename,'rb');
str = fread(fid,12,'uint8=>char')'; % header is 12 bytes.


if ~isempty(strfind(str,'whiskbin1'))     % .whiskers file is in binary whiskbin1 format.
    
    trackerFileFormat = 'whiskbin1';
    
    % Get number of whiskers:
    fseek(fid,-4,'eof'); % 4 bytes for 'int' on Win32.
    nsegs = fread(fid,1,'int');
    
    fseek(fid,12,'bof'); % Start of non-header data.
    
    r = cell(1,nsegs);
    frameNum = zeros(nsegs,1,'single');
    segID = zeros(nsegs,1,'single');
    len = zeros(nsegs,1,'single');
    
    xdat = cell(nsegs,1);
    ydat = cell(nsegs,1);
    thickdat = cell(nsegs,1);
    scoredat = cell(nsegs,1);
       

    for k=1:nsegs
        segID(k) = fread(fid,1,'int')';
        frameNum(k) = fread(fid,1,'int')';
        len(k) = fread(fid,1,'int')';

        dat = fread(fid,4*double(len(k)),'float')';
        
        xdat{k} = dat(1:len(k))';
        ydat{k} = dat((len(k)+1):(2*len(k)))';
        thickdat{k} = dat((2*len(k)+1):(3*len(k)))';
        scoredat{k} = dat((3*len(k)+1):(4*len(k)))';
        
    end
    
    % Package whiskers into cell array, one element per
    % frame, with fields:
    frames = unique(frameNum);
    nframes = length(frames);
    r = cell(1,nframes);
    for k=1:nframes
        fr = frames(k); % 0 based.
        ind = find(frameNum==fr);
        r{k} = {fr, segID(ind), xdat(ind), ydat(ind), thickdat(ind), scoredat(ind)};
    end
    
    
elseif ~isempty(strfind(str,'whisker1')) || ~isempty(strfind(str,'whisker0'))  % .whiskers file is in a text format format.
    
    frewind(fid);
    % Check format of .whiskers file:
    s = textscan(fid,'%s',1);
    if strcmp(s{:},'whisker1')
        trackerFileFormat = 'whisker1'; % new format
    else
        trackerFileFormat = 'whisker0'; % old format
    end
    frewind(fid);
    
    
    switch trackerFileFormat
        
        case 'whisker1'
            % Format of whisker1: frame,id,time,n,x1,y1,thick1,score1...,xn,yn,thickn,scoren
            %
            % Read in frame id, whisker id, number of x,y pairs for all whiskers.
            % Discard "time" field which is currently redundant with frame id.
            %
            c = textscan(fid,'%n, %n, %*n, %n, %*[^\n]','Headerlines',1,'BufSize',16384);
            
            % Read in the x,y pairs:
            nlines = numel(c{1});
            x = cell(nlines,1);
            y = cell(nlines,1);
            thick = cell(nlines,1);
            score = cell(nlines,1);
            n = c{3}; % number of (x1,y1,thick1,score1) tuples.
            
            frewind(fid);
            t = textscan(fid,'%s%*[^\n]',1); % skip first (header) line
            for k=1:nlines
                t = textscan(fid, '%n %n %n %n',1, 'Delimiter', ','); % get rid of leading (frame,id,time,n) values
                t = textscan(fid, '%n %n %n %n',n(k), 'Delimiter', ',');
                x{k} = t{1};
                y{k} = t{2};
                thick{k} = t{3};
                score{k} = t{4};
            end
            
            
            % Package whiskers into cell array, one element per
            % frame, with fields:
            frames = unique(c{1});
            nframes = length(frames);
            r = cell(1,nframes);
            for k=1:nframes
                frameNum = frames(k); % 0 based.
                ind = find(c{1}==frameNum);
                segID = c{2}(ind);
                xdat = x(ind);
                ydat = y(ind);
                thickdat = thick(ind);
                scoredat = score(ind);
                r{k} = {frameNum, segID, xdat, ydat, thickdat, scoredat};
            end
            
            
        case 'whisker0' % Old .whiskers file format
            
            
            % read in frame id, whisker id, x0, x1 for all whiskers
            c = textscan(fid,'%n, %n, %n, %n, %*[^\n]');
            
            % read in the y values
            fseek(fid,0,-1);
            y = cell( size(c{1}) );
            n = c{4}-c{3}+1;
            for i = 1:length(c{1})
                t = textscan(fid, '%n,',4+n(i));
                y{i}=t{1}(5:end);
            end
            
            
            % Package whiskers into cell array, one element per
            % frame, with fields:
            frames = unique(c{1});
            nframes = length(frames);
            r = cell(1,nframes);
            for k=1:nframes
                frameNum = frames(k); % 0 based.
                ind = find(c{1}==frameNum);
                segID = c{2}(ind);
                xdat = [c{3}(ind), c{4}(ind)];
                ydat = y(ind);
                
                r{k} = {frameNum, segID, xdat, ydat};
            end
            
    end
    
    
else
    % Reject whiskpoly1 format.
    error(['File ' filename ' is not in binary (whiskbin1) or text (whisker1,whisker0) format.'])
end


fclose(fid);



