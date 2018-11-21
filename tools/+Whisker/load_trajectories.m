function [whisker_ids, frame_nums, segment_nums] = load_trajectories(filename)

    A = importdata(filename,',');

    whisker_ids = A(:,1);
    frame_nums = A(:,2);
    segment_nums = A(:,3);
    
end