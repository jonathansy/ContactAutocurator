function [] = xraw_split_into_tiffs(inFileName, outFileNameBase, nFramesPerTrial, nTrials)
%
%   Splits AOS camera's native X-RAW binary format file into subsequent
%   TIFF files, each with nFramesPerTrial.
%   into separate TIFF files,
%
%
% DHO, 4/08.
%
%

tic


try
    fid = fopen(inFileName,'r');
catch
    error(['Could not open file ' inFileName])
end

try

    
    % Read RAW header and get image pixel dimensions:
%     rawHeader = fread(fid, 1024,'uint8=>uint8'); % Once per file
    bitmatinfoheader = fread(fid, 40,'uint8=>uint8');
    bwModeBool = fread(fid, 1,'uint32');  
    SizeX = fread(fid, 1,'uint32');
    SizeY = fread(fid, 1,'uint32');
    frameSize = [SizeY SizeX]; % get lost after this so have to rewind file, and read off whole header
    
    frewind(fid)
    rawHeader = fread(fid, 1024,'uint8=>uint8'); % Once per file
    
    
    %     frameSize = [150 200];
    nPix = frameSize(1)*frameSize(2);

    
    
    for k = 1:nTrials
        stack = zeros(frameSize(1),frameSize(2),nFramesPerTrial,'uint8');
        p = zeros(nPix,1,'uint8');
        nWordsInFrame = nPix/4; % 8-bit pixels

        for f = 1:nFramesPerTrial
 
            % First read X-RAW header for each frame:
            % xrawHeader = fread(fid,5*4,'uint8=>uint8'); % All together.
            TS_SECS = fread(fid, 1, 'uint32'); % TS_SEC_BitString = dec2bin(TS_SEC, 32);
            itv = fread(fid,1,'*bit1');
            junk = fread(fid,3,'*bit1');
            status4 = fread(fid, 1, '*bit1');
            status3 = fread(fid, 1, '*bit1');
            status2 = fread(fid, 1, '*bit1');
            status1 = fread(fid, 1, '*bit1');
                        
                       
            TS_SUBSECS = fread(fid, 1, 'ubit24');
            
            IRIGStuff = fread(fid, 3, 'uint32');  % read off 3 words of stuff we don't want.
            
%             disp(['Status bits 1-4: ' int2str(status1) ',' int2str(status2) ',' int2str(status3) ',' int2str(status4)])

            p = fread(fid,[4 nPix/4],'uint8=>uint8');
            p = flipud(p);
            frame = reshape(p,frameSize(2),frameSize(1))';

            stack(:,:,f) = frame;
            fudgeFactor = fread(fid, 5, 'uint32'); % There are five 32-bit words at end that are undocumented.
        end

        % Write to multi-image TIFF.
        % Should use 'Description' field to store timestamp, event codes, exposure, frame rate, pre-trigger, pixel dimensions.

        if k < 10
            numString = ['00' int2str(k)];
        elseif k < 100
            numString = ['0' int2str(k)];
        else
            numString = int2str(k);
        end

        outfn = [outFileNameBase '_' numString '.tif'];
        
        if exist(outfn,'file')
            disp(['File ' outfn ' exists, renaming to ' outfn(1:(end-4)) '_new_.tif'])
            outfn = [outfn(1:(end-4)) '_new_.tif'];
            if exist(outfn,'file')
                error(['File ' outfn ' exists.'])
            end
        end

        for k=1:size(stack,3)
            imwrite(fliplr(flipud(stack(:,:,k)')),outfn,'TIFF','Compression','none','WriteMode','append') % imwrite() is by far the speed bottleneck.
        end

    end

    status = fclose(fid);

catch
    status = fclose(fid);
end


toc









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


    % imagesc(frame)
    % toc

    % figure('Colormap',cmap)
    % for k=1:size(stack,3)
    %     image(fliplr(flipud(stack(:,:,k)')))
    % %     image(stack(:,:,k))
    %     pause
    % end
    %
    % frewind(fid)
    % %
    % ftell(fid)

    
    %%
    
%    tic

% 
% try
%     fid = fopen(inFileName,'r');
% catch
%     error(['Could not open file ' inFileName])
% end
% 
% try
%     frameSize = [150 200];
%     nPix = frameSize(1)*frameSize(2);
% 
%     rawHeader = fread(fid, 1024,'uint8=>uint8'); % Once per file
% 
%     for k = 1:nTrials
%         stack = zeros(frameSize(1),frameSize(2),nFramesPerTrial,'uint8');
%         p = zeros(nPix,1,'uint8');
%         nWordsInFrame = nPix/4; % 8-bit pixels
% 
%         for f = 1:nFramesPerTrial
%             % First read X-RAW header for each frame:
%             % xrawHeader = fread(fid,5*4,'uint8=>uint8'); % All together.
%             TS_SECS = fread(fid, 1, 'uint32'); % TS_SEC_BitString = dec2bin(TS_SEC, 32);
%             nextWord = fread(fid, 1, 'uint32'); nextWordBitString = dec2bin(nextWord,32);
%             TS_SUBSECS = bin2dec(nextWordBitString(9:32));
%             status4 = str2num(nextWordBitString(5));
%             status3 = str2num(nextWordBitString(6));
%             status2 = str2num(nextWordBitString(7));
%             status1 = str2num(nextWordBitString(8));
%             IRIGStuff = fread(fid, 3, 'uint32'); % read off 3 words of stuff we don't want.
%             %     display(['Status bits 1-4: ' int2str(status1) ',' int2str(status2) ',' int2str(status3) ',' int2str(status4)])
% 
%             p = fread(fid,[4 nPix/4],'uint8=>uint8');
%             p = flipud(p);
%             frame = reshape(p,frameSize(2),frameSize(1))';
% 
%             stack(:,:,f) = frame;
%             fudgeFactor = fread(fid, 5, 'uint32'); % There are five 32-bit words at end that are undocumented.
%         end
% 
%         % Write to multi-image TIFF.
%         % Should use 'Description' field to store timestamp, event codes, exposure, frame rate, pre-trigger, pixel dimensions.
% 
%         if k < 10
%             numString = ['00' int2str(k)];
%         elseif k < 100
%             numString = ['0' int2str(k)];
%         else
%             numString = int2str(k);
%         end
% 
%         outfn = [outFileNameBase '_' numString '.tif'];
% 
%         for k=1:size(stack,3)
%             imwrite(fliplr(flipud(stack(:,:,k)')),outfn,'TIFF','Compression','none','WriteMode','append') % imwrite() is by far the speed bottleneck.
%         end
% 
%     end
% 
%     status = fclose(fid);
% 
% catch
%     status = fclose(fid);
% end
% 
% 
% toc

    
    
   
