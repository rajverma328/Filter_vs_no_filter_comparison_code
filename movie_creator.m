clear all
close all
warning('off')
%%%%%%%%%%%%%%%%%%%%%%%%% taking input %%%%%%%%%%%%%%%%%%%%%%%%%
data_filename = uigetdir; % filename for all folders
topLevelFolder = data_filename;  % Get a list of all files and folders in this folder.
files = dir(topLevelFolder);    % Get a logical vector that tells which is a directory.
dirFlags = [files.isdir];   % Extract only those that are directories.
subFolders = files(dirFlags);   % A structure with extra info. Get only the folder names into a cell array.
subFolderNames = {subFolders(3:end).name}; % Start at 3 to skip . and ..
l2 = length(subFolderNames);
infname = {'processed BW','processed contour','processed edge'};

for index = 1:l2
    blsh = '\';
    for inc = 1:length(infname)
        path = strcat(data_filename,blsh,subFolderNames(index),blsh,string(infname(inc)));
        path = string(path);
        tif_files = dir(fullfile(path,'*.tif'));
        l = length(tif_files);
        output_image_path = string(strcat(data_filename,blsh,subFolderNames(index),blsh,subFolderNames(index),"_",string(infname(inc)),".mp4"));
        video = VideoWriter(output_image_path,'MPEG-4');
        open(video);
        for cnt = 1:l %replace by l to iterate 
            img = im2uint8(imread(fullfile(path,tif_files(cnt).name)));
            writeVideo(video,img);
        end
        close(video);
        fprintf("%s sub folder completed\n",string(infname(inc)))
        clear("video")
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Reporting ptogress %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    fprintf("%s folder movie made successfull (%d/%d)\n",string(subFolderNames(index)),index,l2); 
    disp("................................................")
end

disp("Movie making completed for all folders")
disp("................................................")
