function [seq_info, fid] = read_seq_header(seq_file)
% [seq_info, fid] = read_seq_header(seq_file)
% this function reads a sequence header for a StreamPix .seq file
% seq_file is a string with the file name
% Thus far only tested on 8 bit monichrome sequences - MBR 6/19
% Added error message KS 122609

[fid, message] = fopen(seq_file, 'r');
if ~ isempty(message)
    error(message);
end

status = fseek(fid, 548, 'bof'); % the CImageInfo structure starts at byte 548

if status == 0
    CImageInfo = fread(fid, 6, 'uint32');       
    seq_info.Width = CImageInfo(1);            % Image width in pixel
    seq_info.Height = CImageInfo(2);           % Image height in pixel
    seq_info.BitDepth = CImageInfo(3);         % Image depth in bits (8,16,24,32)
    seq_info.BitDepthReal = CImageInfo(4);     % Precise Image depth (x bits)
    seq_info.SizeBytes = CImageInfo(5);        % Size used to store one image 
    seq_info.ImageFormat = CImageInfo(6);      % format information, should be 100 monochrome (LSB)
end

seq_info.NumberFrames = fread(fid, 1, 'uint32');
status = fseek(fid, 580, 'bof');
seq_info.TrueImageSize = fread(fid, 1, 'uint32');
seq_info.FrameRate = fread(fid, 1, 'double');
