clear all
close all
warning('off')
t=0;
Area_limit=500;
r = [0,0,0,0];
r1 = 0;
%%%%%%%%%%%%%%%%%%%%%%%%% taking input %%%%%%%%%%%%%%%%%%%%%%%%%
prompt = {'Enter length calibration factor (mm/pixel)','Enter frame rate in f.p.s.','Enter threshold senstivity(dark)','Enter threshold senstivity(light)','enter circle distance value(pixels)'};
dlgtitle = 'Input';
dims = [1 50];
definput = {'0.1194','36000','4','16','352'};  %(197/7.5)^-1 as provided
answer = inputdlg(prompt,dlgtitle,dims,definput);
calibration_factor = str2double(answer(1));
frame_rate = str2double(answer(2));
rcor = str2double(answer(3));
rcor1 = str2double(answer(4));
area_cal_fac = calibration_factor*calibration_factor;
frame_rate = frame_rate/1000; %frames per milli second
frame_rate = 1/frame_rate;
cds = str2double(answer(5));

data_filename = uigetdir; % filename for all folders
topLevelFolder = data_filename;  % Get a list of all files and folders in this folder.
files = dir(topLevelFolder);    % Get a logical vector that tells which is a directory.
dirFlags = [files.isdir];   % Extract only those that are directories.
subFolders = files(dirFlags);   % A structure with extra info. Get only the folder names into a cell array.
subFolderNames = {subFolders(3:end).name}; % Start at 3 to skip . and ..
xcl = strcat(data_filename,'\results_final_21_April.xlsx'); 
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
    tif_files = dir(fullfile(path,'*.tif'));
    l = length(tif_files);
    targetSize = [cds cds];

    destdirectory1 = strcat(path,'\processed BW');
    destdirectory3 = strcat(path,'\processed edge');
    destdirectory2 = strcat(path,'\processed contour');
    mkdir(destdirectory1); %create the directory
    mkdir(destdirectory2);
    mkdir(destdirectory3);
    
    org = [];
    area = [];
    peri = [];
    xp = [];
    xn = [];
    yp = [];
    yn = [];
    t = [];
    tc = 0;
    spark_frame = 0;
    bg_img = imread(fullfile(path,tif_files(1).name));
    bg_img = rgb2gray(bg_img);
    bg_img1 = bg_img<20;
%     bg_img1 = edge(bg_img1,"canny");
%     imshow(bg_img1)
    [rows ,cols ,~] = size(bg_img);
    se = strel('disk',5);
    se1 = strel('disk',5);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Writing data in excel sheets %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    nn = string(subFolderNames(index));
    nn = convertStringsToChars(nn);
    if ((nn(end) == "1") && (index ~= 1))
        matstd = std(matf,0,3);
        matavg = sum(matf,3);
        matavg = matavg/(count-1);
        matavg = array2table(matavg,'VariableNames',name_arr_avg);
        matstd = array2table(matstd,"VariableNames",name_arr_std);
        sheet = string(subFolderNames(index-1));
        sheet = strrep(sheet,'.','_');
        chr = convertStringsToChars(sheet);
        if (length(chr) > 29)
            sheet = string(chr(1:30));
        end
        mattoprin =[];
        lt1 = [];
        for i = 1:count-1
            name_arr = "";
            for j = 1:13
                name_arr(j) = strcat(name_arr1(j)," data ",num2str(i));
            end
            matp = matf(:,:,i);
            ltt = length(matp(:,1));
            matp = array2table(matp,'VariableNames',name_arr);
            lt1 = zeros(ltt,1);
            lt1 = lt1 + 32;
            lt1 = char(lt1);
            lt1 = array2table(lt1,'VariableNames',string(num2str(i)));
            mattoprin = [mattoprin matp lt1];
        end
        lt1 = zeros(ltt,1);
        lt1 = lt1 + 32;
        lt1 = char(lt1);
        lt1 = array2table(lt1,'VariableNames',string(num2str(50)));
        mattoprin = [mattoprin matavg lt1 matstd];
        writetable(mattoprin,xcl,'Sheet',sheet,"WriteMode","overwritesheet");
        count = 1;
        matf = [];
        disp("........................sheet completed........................")
    end

    for cnt = 2:l
        img = imread(fullfile(path,tif_files(cnt).name));
        img = rgb2gray(img);
        img = img-bg_img;
        img = img>50;
        i = find(img);
        if i>0
            spark_frame = cnt;
            img = imread(fullfile(path,tif_files(cnt+1).name));
            gray2 = rgb2gray(img);
            gray3 = bg_img-gray2; 
            gray31 = gray2 - bg_img;
            gray3 = medfilt2(gray3);
            gray31 = medfilt2(gray31);
            gray4 = imclose(gray3,se);
            gray41 = imclose(gray31,se1);
            bina = gray4>rcor;
            bina1 = gray41>rcor1;
            bina = bina+bina1;
            bina = bina>0;
            bina = medfilt2(bina);
            bina = bwconvhull(bina);
            bina = bina-bg_img1;
            bina = imfill(bina,"holes");
            org = center_of_area(bina);
            break;
        end
    end
%     disp(spark_frame)
    binaprev = zeros(rows,cols);

    img = imread(fullfile(path,tif_files(spark_frame).name));
    gray2 = rgb2gray(img);
    gray3 = gray2-bg_img; 
    gray3 = medfilt2(gray3);
    gray4 = imclose(gray3,se);
    thisimage = strcat('processed_contour_',tif_files(cnt).name);
    fulldestination = fullfile(destdirectory2, thisimage);  %name file relative to that directory
    rgbImage = ind2rgb(2*gray4,turbo);
    imwrite(rgbImage, fulldestination); 

    for cnt = (spark_frame+1):l %replace by l to iterate 
        t = [t; (cnt-spark_frame)*frame_rate];
        img = imread(fullfile(path,tif_files(cnt).name));
        gray2 = rgb2gray(img);
        gray3 = bg_img-gray2; 
        gray31 = gray2 - bg_img;
        gray3 = medfilt2(gray3);
        gray31 = medfilt2(gray31);
        gray4 = imclose(gray3,se);
        gray41 = imclose(gray31,se1);
        bina = gray4>rcor;
        bina1 = gray41>rcor1;
        bina = bina+binaprev+bina1;
        bina = bina>0;
        bina = medfilt2(bina);
        bina = bwconvhull(bina);
        bina = bina-bg_img1;
        bina = imfill(bina,"holes");
        binaprev = bina;
        imshow(bina)
        if cnt==l
            binaprev = [];
        end
        area = [area; area_cal_fac*bwarea(bina)];
        peri = [peri; calibration_factor*sum(sum(bwperim(bina)))];
        xp = [xp; calibration_factor*(cord_of_sprayxpos(bina)-org(1))];
        yp = [yp; calibration_factor*(-org(2)+cord_of_sprayypos(bina))];
        xn = [xn; calibration_factor*(org(1)-cord_of_sprayxneg(bina))];
        yn = [yn; calibration_factor*(-cord_of_sprayyneg(bina)+org(2))];

        thisimage = strcat('processed_BW_',tif_files(cnt).name);
        fulldestination = fullfile(destdirectory1, thisimage);  %name file relative to that directory
        imwrite((255-2*gray3), fulldestination); 
        
        thisimage = strcat('processed_contour_',tif_files(cnt).name);
        fulldestination = fullfile(destdirectory2, thisimage);  %name file relative to that directory
        rgbImage = ind2rgb(2*gray4,turbo);
        imwrite(rgbImage, fulldestination); 

        thisimage = strcat('processed_edger_',tif_files(cnt).name);
        fulldestination = fullfile(destdirectory3, thisimage);  %name file relative to that directory
        imwrite(bina, fulldestination); 
    end
    area_speed = (area(2:end)-area(1:end-1))/frame_rate;
    peri_speed = (peri(2:end)-peri(1:end-1))/frame_rate;
    speedxp = (xp(2:end)-xp(1:end-1))/frame_rate; 
    speedxn = (xn(2:end)-xn(1:end-1))/frame_rate;
    speedyp = (yp(2:end)-yp(1:end-1))/frame_rate;
    speedyn = (yn(2:end)-yn(1:end-1))/frame_rate; 

    matx = NaN(2000,13);
    matx(1:length(t),1) = t;
    matx(1:length(area),2) = area;
    matx(1:length(area_speed),3) = area_speed;
    matx(1:length(peri),4) = peri;
    matx(1:length(peri_speed),5) = peri_speed;
    matx(1:length(xp),6) = xp;
    matx(1:length(speedxp),7) = speedxp;
    matx(1:length(yp),8) = yp;
    matx(1:length(speedyp),9) = speedyp;
    matx(1:length(xn),10) = xn;
    matx(1:length(speedxn),11) = speedxn;
    matx(1:length(yn),12) = yn;
    matx(1:length(speedyn),13) = speedyn;
    matf(:,:,count) = matx;
    count = count +1;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Reporting ptogress %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    fprintf("%s folder data analysis completed. (%d/%d)\n",string(subFolderNames(index)),index,l2); 

    if index == l2
        matavg = sum(matf,3);
        matavg = matavg/(count-1);
        matavg = array2table(matavg,'VariableNames',name_arr_avg);
        sheet = string(subFolderNames(index));
        sheet = strrep(sheet,'.','_');
        chr = convertStringsToChars(sheet);
        if (length(chr) > 29)
            sheet = string(chr(1:30));
        end
        mattoprin =[];
        lt1 = [];
        for i = 1:count-1
            name_arr = "";
            for j = 1:13
                name_arr(j) = strcat(name_arr1(j)," data ",num2str(i));
            end
            matp = matf(:,:,i);
            ltt = length(matp(:,1));
            matp = array2table(matp,'VariableNames',name_arr);
            lt1 = zeros(ltt,1);
            lt1 = lt1 + 32;
            lt1 = char(lt1);
            lt1 = array2table(lt1,'VariableNames',string(num2str(i)));
            mattoprin = [mattoprin matp lt1];
        end

        mattoprin = [mattoprin matavg];
        writetable(mattoprin,xcl,'Sheet',sheet,"WriteMode","overwritesheet");
        count = 1;
        matf = [];
        disp("........................sheet completed........................")
    end

end
disp("................................................")
disp("Data analysis completed.")
disp("................................................")
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
