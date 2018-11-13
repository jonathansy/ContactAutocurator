% Install all relevant files and change settings using MATLAB code
% Created: 2018-11-08 by J. Sy
% Last Updated: 2018-11-08 by J. Sy

% SETTINGS


% Add ContactAutocurator package to path
packageFullPath = mfilename('fullpath');
[packagePath,~,~] = fileparts(packageFullPath);
addpath(genpath(packagePath))

% OS-specific installation
if ispc
    %
    pythonSource = 'https://www.python.org/ftp/python/3.7.1/python-3.7.1-amd64.exe';
    
elseif isunix
    % Section under construction
else
    error('Unsupported Operating System')
end
