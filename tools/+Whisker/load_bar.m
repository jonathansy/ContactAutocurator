function [frame_nums, x, y] = load_bar(filename)

    A = importdata(filename,' ');
    frame_nums = A(:,1);
    x = A(:,2);
    y = A(:,3);
    
end