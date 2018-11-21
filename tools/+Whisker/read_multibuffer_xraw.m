
inFileName = 'JF8410_041808.raw';
outFileNameBase = 'JF8410_041808';
nFramesPerTrial = 550;
nTrials = 300;


xraw_split_into_tiffs(inFileName, outFileNameBase, nFramesPerTrial, nTrials)


%----
cd('I:\DATA\whiskerVideo\TIFF\050508')

inFileName = 'JF8410_050508.raw'; outFileNameBase = 'JF8410_050508'; nFramesPerTrial = 550; nTrials = 300;
xraw_split_into_tiffs(inFileName, outFileNameBase, nFramesPerTrial, nTrials)



%
python C:\dan\analysis\whiskerTracking\whisker\ui\ui.py JF8410_041808_001.tif JF8410_041808_001.csv






















%%
%
%   Reads AOS camera's native X-RAW binary format movie files.
%
%
% DHO, 3/08.
%
clear
% cd('C:\dan\analysis\behav\analysis\whiskerTracking')
cd('I:\DATA\whiskerVideo\TIFF\041808')

fn = 'JF8410_041808.raw';

cmap = [(0:255)' (0:255)' (0:255)']./255;



fid = fopen(fn,'r');
% hdr = fread(fid, 37*4,'uint8=>uint8');

frameSize = [150 200];
nPix = frameSize(1)*frameSize(2);


% tic

nFrames = 550;
stack = zeros(frameSize(1),frameSize(2),nFrames,'uint8'); 
  
rawHeader = fread(fid, 1024,'uint8=>uint8'); % Once per file
p = zeros(nPix,1,'uint8');
nWordsInFrame = nPix/4; % 8-bit pixels
for f = 1:nFrames
    
    % First read X-RAW header for each frame:
    % xrawHeader = fread(fid,5*4,'uint8=>uint8'); % All together.
    TS_SECS = fread(fid, 1, 'uint32'); % TS_SEC_BitString = dec2bin(TS_SEC, 32);
    nextWord = fread(fid, 1, 'uint32'); nextWordBitString = dec2bin(nextWord,32);
    TS_SUBSECS = bin2dec(nextWordBitString(9:32));
    status4 = str2num(nextWordBitString(5));
    status3 = str2num(nextWordBitString(6));
    status2 = str2num(nextWordBitString(7));
    status1 = str2num(nextWordBitString(8));
    IRIGStuff = fread(fid, 3, 'uint32'); % read off 3 words of stuff we don't want.

%     display(['Status bits 1-4: ' int2str(status1) ',' int2str(status2) ',' int2str(status3) ',' int2str(status4)])
    
    %-----------------------
    % Now read pixel data:
%     n = 1;
%     for k=1:nWordsInFrame
%         w = fread(fid, 4,'uint8=>uint8');
%         p(n:(n+3)) = w(end:-1:1);
%         n = n+4;
%     end
    
    % Need optimized version:
    p = fread(fid,[4 nPix/4],'uint8=>uint8');
    p = flipud(p);
    frame = reshape(p,frameSize(2),frameSize(1))';

    %----------------------
%     frame = reshape(p,frameSize(2),frameSize(1))';
    stack(:,:,f) = frame;
    fudgeFactor = fread(fid, 5, 'uint32'); % There are five 32-bit words at end that are undocumented.
end

% Write to multi-image TIFF.  
% Should use 'Description' field to store timestamp, event codes, exposure, frame rate, pre-trigger, pixel dimensions.
for k=1:size(stack,3)
%     imwrite(stack(:,:,k),'out.tif','TIFF','Compression','none','WriteMode','append') % imwrite() is by far the speed bottleneck.
    imwrite(fliplr(flipud(stack(:,:,k)')),'out.tif','TIFF','Compression','none','WriteMode','append') % imwrite() is by far the speed bottleneck.
end

% imagesc(frame)
% toc

figure('Colormap',cmap)
for k=1:size(stack,3)
    image(fliplr(flipud(stack(:,:,k)')))
%     image(stack(:,:,k))
    pause
end

frewind(fid)
% 
% ftell(fid)
status = fclose(fid)


%{

As follows you find the concrete sizes of the BITMAPINFOHEADER and the bool type:

BITMAPINFOHEADER bi;    //  40 bytes
BOOL bwMode;            //   4 bytes

Regarding the five 32-bit words, that's correct, but they are at the beginning of each image. The content of these five 32-bit words can be found in the X-RAW specification and look like follows:

WORD 31 + 1 ... (time in seconds)
WORD 31 + 2 ... (subseconds, states, ...)
WORD 31 + 3 ... (IRIG-B information)
WORD 31 + 4 ... (IRIG-B information)

We are happy to hear that working with our cameras is nicely for you.

If you have further questions please do not hesitate to contact me.

Best regards
Stefan Odermatt
%}



