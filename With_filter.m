clear all
close all
warning('off')
t=0;
Area_limit=500;
r = [0,0,0,0];
r1 = 0;
%%%%%%%%%%%%%%%%%%%%%%%%% taking input %%%%%%%%%%%%%%%%%%%%%%%%%
prompt = {'Enter length calibration factor (mm/pixel)','Enter frame rate in f.p.s.','Enter threshold senstivity(dark)','Enter threshold senstivity(light)'};
dlgtitle = 'Input';
dims = [1 50];
definput = {'1','15000','7','4'};  %(197/7.5)^-1 as provided
answer = inputdlg(prompt,dlgtitle,dims,definput);
calibration_factor = str2double(answer(1));
frame_rate = str2double(answer(2));
rcor = str2double(answer(3));
rcor1 = str2double(answer(4));
area_cal_fac = calibration_factor*calibration_factor;
frame_rate = frame_rate/1000; %frames per milli second
frame_rate = 1/frame_rate;

data_filename = uigetdir; % filename for all folders
topLevelFolder = data_filename;  % Get a list of all files and folders in this folder.
files = dir(topLevelFolder);    % Get a logical vector that tells which is a directory.
dirFlags = [files.isdir];   % Extract only those that are directories.
subFolders = files(dirFlags);   % A structure with extra info. Get only the folder names into a cell array.
subFolderNames = {subFolders(3:end).name}; % Start at 3 to skip . and .. 
l2 = length(subFolderNames);

name_arr1 = ["time(ms)","area(mm2)","area speed(mm2/ms)","perimeter(mm)","perimeter speed(mm/ms)","positive x(mm)","speed xp(mm/ms)","positive y(mm)","speed yp(mm/ms)","negative x(mm)","speed xn(mm/ms)","negative y(mm)","speed yn(mm/ms)"];
name_arr_avg = ["Average time(ms)","Average area(mm2)","Average area speed(mm2/ms)","Average perimeter(mm)","Average perimeter speed(mm/ms)","Average positive x(mm)","Average speed xp(mm/ms)","Average positive y(mm)","Average speed yp(mm/ms)","Average negative x(mm)","Average speed xn(mm/ms)","Average negative y(mm)","Average speed yn(mm/ms)"];
name_arr_std = ["std time(ms)","std area(mm2)","std area speed(mm2/ms)","std perimeter(mm)","std perimeter speed(mm/ms)","std positive x(mm)","std speed xp(mm/ms)","std positive y(mm)","std speed yp(mm/ms)","std negative x(mm)","std speed xn(mm/ms)","std negative y(mm)","std speed yn(mm/ms)"];
matf = [];
count = 1;
for index = 1:l2
    blsh = '\';
    path = strcat(data_filename,blsh,subFolderNames(index));
    path = string(path);
    xcl = strcat(path,'\results.xlsx');
    tif_files = dir(fullfile(path,'*.tif'));
    l = length(tif_files);

    destdirectory1 = strcat(path,'\processed BW');
    destdirectory3 = strcat(path,'\processed edge');
    destdirectory2 = strcat(path,'\processed contour');
    mkdir(destdirectory1); %create the directory
    mkdir(destdirectory2);
    mkdir(destdirectory3);
    
    bg_img = imread(fullfile(path,tif_files(1).name));
    bg_img = rgb2gray(bg_img);
    edge_bg = bg_img>3;
    edge_bg = edge(edge_bg,'Prewitt');
    [rows ,cols ,~] = size(bg_img);
    edge_bg = uint8(255*(1-edge_bg));
    blank_img = uint8(zeros(rows,cols,3));
    blank_img(:,:,1) = edge_bg;
    blank_img(:,:,2) = edge_bg;
    blank_img(:,:,3) = edge_bg;

    spark_frame = 0;
    injection_frame = 0;
    for cnt = 2:l
        img = imread(fullfile(path,tif_files(cnt).name));
        img = rgb2gray(img);
        bin_img1 = (bg_img-img)>10;
        bin_img2 = (img-bg_img)>50;
        j1 = find(bin_img1);
        j2 = find(bin_img2);
        if (spark_frame == 0)
            if (j1>0)
                injection_frame = cnt;
                spark_frame = -1;
            end
        end
        if (j2>0)
            spark_frame = cnt;
            break;
        end
    end
    for cnt = (injection_frame-2):l
        img_og =  imread(fullfile(path,tif_files(cnt).name));
        img = rgb2gray(img_og);
        gray1 = bg_img - img;
        bin_img1 = gray1 > rcor;
        gray2 = 0;
        if (cnt >= spark_frame)
            gray2 = img - bg_img;
            bin_img2 = gray2 > rcor1;
        end
        
        img_og(:,:,3) = uint8(100*bin_img1) + img_og(:,:,3);
        img_og(:,:,1) = uint8(100*bin_img2) + img_og(:,:,1);
        img_og(:,:,2) = img_og(:,:,2) - uint8(50*bin_img2);
        
        blt = blank_img;
        blt(:,:,1) = blt(:,:,2) - uint8(255*bin_img1);
        blt(:,:,2) = blt(:,:,2) - uint8(255*bin_img1);
        blt(:,:,3) = blt(:,:,3) + uint8(255*bin_img1);
        
        blt(:,:,1) = blt(:,:,2) + uint8(255*bin_img2);
        blt(:,:,2) = blt(:,:,2) - uint8(255*bin_img2);
        blt(:,:,3) = blt(:,:,3) - uint8(255*bin_img2);

        thisimage = strcat('processed_BW_',tif_files(cnt).name);
        fulldestination = fullfile(destdirectory1, thisimage);  %name file relative to that directory
        imwrite(img, fulldestination); 
        
        thisimage = strcat('processed_contour_',tif_files(cnt).name);
        fulldestination = fullfile(destdirectory2, thisimage);  %name file relative to that directory
        imwrite(img_og, fulldestination); 
         
        thisimage = strcat('processed_edge_',tif_files(cnt).name);
        fulldestination = fullfile(destdirectory3, thisimage);  %name file relative to that directory
        imwrite(blt, fulldestination);
    end
     fprintf("%s folder data analysis completed. (%d/%d)\n",string(subFolderNames(index)),index,l2);
end
disp("......................................................")
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% cord. of spray front function %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
function a = cord_of_sprayxpos(img1)
    [~, columns] = find(img1);
    a = max(columns);
end

function a = cord_of_sprayypos(img1)
    [rows, ~] = find(img1);
    a = max(rows);
end

function a = cord_of_sprayxneg(img1)
    [~, columns] = find(img1);
    a = min(columns);
end

function a = cord_of_sprayyneg(img1)
    [rows, ~] = find(img1);
    a = min(rows);
end

function a = center_of_area(img1)
    measurements = regionprops(img1, 'Centroid');
    centroids = [measurements.Centroid];
    xCentroids = mean(centroids(1:2:end));
    yCentroids = mean(centroids(2:2:end));
    a = [xCentroids,yCentroids];
end
