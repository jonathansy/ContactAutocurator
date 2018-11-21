
function frames=readSeqImages(seq_file, varargin)
% read image sequence from Norpix seq files
% read one or a range of image frames
% read full frames or a region of interest (roi) - [x y width height]
%   for horizontal linescan [1 y full_width 1] 
%   for vertical linescan [x 1 1 full_height] 
%
% INPUTS  
% name - filename - REQUIRED
% parameter-value pairs - ALL OPTIONAL
% firstFrame - first frame number; default - 1st frame
% lastFrame - last frame number; default - last frame
% increment - increment in frame number to read; default, 1
% roi - region of interest speficied as x,y,w,h; default, full 
%
% todo: compare seq_info.TrueImageSize compared to norpix2Matlab
%
% ks 122709; based on part on MR code  

p = inputParser;   % Create instance of inputParser class.

p.addRequired('seq_file', @ischar);
p.addParamValue('firstFrame', [], @(x)x>0 && mod(x,1)==0);
p.addParamValue('lastFrame', [], @(x)x>0 && mod(x,1)==0);
p.addParamValue('increment', [], @(x)x>0 && mod(x,1)==0);
p.addParamValue('roi', [], @(x)fix(mean(x>0)) && fix(mean(mod(x,1)==0)));
p.parse(seq_file, varargin{:});

[seq_info, fid] = Whisker.read_seq_header(seq_file);

if isempty(p.Results.firstFrame)
    firstF=1;
elseif 0 < round(p.Results.firstFrame) && round(p.Results.firstFrame) < seq_info.NumberFrames+1
    firstF=p.Results.firstFrame;
else
    error('firstFrame/lastFrame not specified correctly')
end

if isempty(p.Results.lastFrame)
    lastF=seq_info.NumberFrames;
elseif firstF < round(p.Results.lastFrame)+1 && round(p.Results.lastFrame) < seq_info.NumberFrames+1
    lastF=p.Results.lastFrame;
else
        error('firstFrame/lastFrame not specified correctly')
end

if isempty(p.Results.increment)
    incr=1;
elseif p.Results.increment < (lastF - firstF +1)
    incr=p.Results.increment;
else
        error('increment not specified correctly')
end

if isempty(p.Results.roi)
    roi=[1, 1, seq_info.Width seq_info.Height];
elseif p.Results.roi(1)+p.Results.roi(3) < seq_info.Width +2 && p.Results.roi(2)+p.Results.roi(4) < seq_info.Height + 2 
    roi=p.Results.roi;
else
        error('roi not compatible with image dimensions')
end

temp = uint8( zeros(seq_info.Height, seq_info.Width ) );
frames = uint8( zeros((lastF-firstF+1), roi(4), roi(3)) ); % nframes, width, height

for f=1:incr:(lastF-firstF+1)
    image_address = 1024 + (firstF+f-2)*seq_info.TrueImageSize;
    status = fseek(fid, image_address, 'bof');
    if status == -1 
        message = ferror(fid);
        error(message);
    end
    temp = fread(fid, [seq_info.Width, seq_info.Height], 'uint8')';
    frames(f, :, :) = temp(roi(2):(roi(2)+roi(4)-1), roi(1):(roi(1)+roi(3)-1));
end
frames=squeeze(frames);
% f
% image_address = 1024 + (firstF+f-1)*seq_info.TrueImageSize;
% i=1;
% while ~isequal(status, -1)
%     status = fseek(fid, image_address+i, 'bof');
%     i=i+1;
% end
% i
% 
