function mp42tiff(fn)
%
% Requires mmread by Micah Richert:
%   http://www.mathworks.com/matlabcentral/fileexchange/8028
%
% USAGE:
%   mp42tiff(filename)
%
% DHO, 12/10.
%


% fn = 'WDBP_ANM101853-2010_11_04-1_0207_20101104163043718.mp4';

m = mmread(fn);
outfn = [fn(1:(end-3)) 'tif'];

numFrames = length(m.frames);

for k=1:numFrames
    imwrite(m.frames(k).cdata,outfn,'TIFF','Compression','none',...
        'WriteMode','append');
end

