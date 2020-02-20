% Install all relevant files and change settings using MATLAB code
% Created: 2018-11-08 by J. Sy
% Last Updated: 2018-11-08 by J. Sy

% SETTINGS


% Add ContactAutocurator package to path
packageFullPath = mfilename('fullpath');
[packagePath,~,~] = fileparts(packageFullPath);
addpath(genpath(packagePath))

% OS-specific installation
fprintf('Do you wish to attempt automatic installation of Python 3.8?\n')
fprintf('[Y] Yes, install automatically\n')
fprintf('[N] No, I wish to install manually or already have Python installed.')
installChk = input('>');

if strcmpi(installChk, 'Y')
    installPy = true;
else
    installPy = false;
end

fprintf('Do you wish to attempt automatic installation of Google Cloud SDK?\n')
fprintf('[Y] Yes, install automatically\n')
fprintf('[N] No, I wish to install manually or already have CloudSDK installed.')
installChk = input('>');

if strcmpi(installChk, 'Y')
    installSDK = true;
else
    installSDK = false;
end

if ispc
    if installPy == true
        % Install Python
        pythonSource = 'https://www.python.org/ftp/python/3.8.1/python-3.8.1-amd64.exe';
        web(pythonSource)
    end
    if installSDK == true
        % Install Cloud SDK
        system(['powershell -inputformat none -Command '...
            '(New-Object Net.WebClient).DownloadFile("https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe",'...
            ' "$env:Temp\GoogleCloudSDKInstaller.exe")'])
        system(['powershell -inputformat none -Command '...
                '& $env:Temp\GoogleCloudSDKInstaller.exe'])
    end
    
elseif isunix
    if installPy == true
        % Install Python
        pythonSource = 'https://www.python.org/ftp/python/3.8.1/Python-3.8.1.tgz';
        web(pythonSource);
    end
    if installSDK == true
        % Install Cloud SDK
        system(['echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] '... 
                'https://packages.cloud.google.com/apt cloud-sdk main" | '...
                'sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list'])
        system('sudo apt-get install apt-transport-https ca-certificates gnupg')
        system(['curl https://packages.cloud.google.com/apt/doc/apt-key.gpg '...
        '| sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -'])
        system('sudo apt-get update && sudo apt-get install google-cloud-sdk')
    end
else
    error('Unsupported Operating System')
end

% Open config file

edit cloud_config.m
edit autocurator_config.m
