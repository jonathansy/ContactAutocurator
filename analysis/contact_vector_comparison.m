function [outMat] = contact_vector_comparison(machineArray, humanArray)

machineRow = [];
humanRow = [];

for i = 1:length(machineArray)
    if isempty(humanArray{i}.contactInds)
        continue
    end
    machineVector = zeros(1, length(humanArray{1}.M0combo{1}));
    humanVector = zeros(1, length(humanArray{1}.M0combo{1}));
    machineVector(machineArray{i}.contactInds{1}) = 1;
    humanVector(humanArray{i}.contactInds{1}) = 1;
    machineRow = [machineRow machineVector];
    humanRow = [humanRow humanVector];    
end
outMat = [machineRow; humanRow];
agreementRow = machineRow == humanRow;
outMat = [outMat; agreementRow];