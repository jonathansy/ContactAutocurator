% RETURN_PATH_SETTINGS() returns dynamic full paths to all relevant files
% within ContactAutocurator so they do not need to be manually specified

function [paths] = return_path_settings()
% Establish full path to this m-file
fileFullPath = mfilename('fullpath');
[filePath,~,~] = fileparts(fileFullPath);
% Check if valid, script must be in 'tools' folder
if ~strcmp(filePath(end-23:end), ['ContactAutocurator' filesep 'tools'])
    error('Invalid file location, please place script in ContactAutocurator/tools')
end
basePath = filePath(1:end-6);

% Begin setting paths to important files
paths.curateConfigFile = [basePath filesep 'autocurator' filesep 'cloud' filesep 'cloud_config_curation.yaml'];
paths.trainConfigFile = [basePath filesep 'train_new_model' filesep 'cloud' filesep 'cloud_config_training.yaml'];
paths.cloudCurationScript = [basePath filesep 'autocurator']; 
paths.cloudTrainingScript = [basePath filesep 'train_new_model' filesep 'cloud']; 
paths.curatePreprocess = [basePath filesep 'autocurator' filesep 'preprocess_pole_images']; 
end
