function data=MB_Pupil(sPathNames,data,handles)

 if ~exist('sPathNames','var')
     % first parameter does not exist, so default it to something
     [fileName,path] = uigetfile('*','Chose the pupil video to analyse','MultiSelect','off');
     sPathNames.path=path;
     sPathNames.fileName=fileName;
 end
  if ~exist('data','var')
     % second parameter does not exist, so default it to something
      data = [];
  end
  if ~exist('handles','var')
     % third parameter does not exist, so default it to something
     handles=struct;
      h=figure();
      handles.axes_pupil=h
  end
  
try  
videolist=ls([sPathNames.rawPathePhys '\CameraPupil\' sPathNames.fileNameePhys(1:end-4)]);
videolist=videolist(3:end,:);
videoliststr=cellstr(videolist);
catch
end

pupil=struct;

%% select video
j=1;
for l=1:1%numel(videoliststr)
    %strFile=[sPathNames.rawPathePhys 'CameraPupil\' sPathNames.fileNameePhys(1:end-4) '\' videolist(l,:)];
    strFile=[sPathNames.path '\' sPathNames.fileName];
    v=VideoReader(strFile);%[path listing(3,1).name]);
    numimages(l)=v.NumberOfFrames;
    
    %% ask for pupil position
    if l==1
        ref=read(v,1);%0.4*v.NumberOfFrames);
        try
            imshow(ref,'Parent',handles.axes_pupil);
        catch
            gcf;
            handles.axes_pupil=gca;
            imshow(ref,'Parent',handles.axes_pupil);
        end
        gcf
    
        hm=msgbox('Please select the pupil roi and double click on the area');
        disp('double click on the area to validate the roi');
        h = imrect(handles.axes_pupil);
        position = wait(h);
        delete(hm);
        position = round(position)
        xmin = position(1);
        ymin = position(2);
        width = position(3);
        height = position(4);
    end

    for i=1:v.NumberOfFrames
        try
            set(handles.Pb,'Value',(i+l*v.NumberOfFrames)/(v.NumberOfFrames*numel(videoliststr))*100);
        catch
        end
        video=read(v,i);
        crop0=video(max(ymin,1):max(ymin,1)+height-1,max(xmin,1):max(xmin,1)+width-1);
        
        crop = uint8(255) - crop0;
        
        thresh=graythresh(crop);
        gcf;
        pupil0 = im2bw(crop,thresh);
        stat=regionprops(pupil0,'Centroid','Area','MajorAxisLength','MinorAxisLength','EulerNumber');

        if size(stat,1)==1
            cx(j)=stat.Centroid(1);
            cy(j)=stat.Centroid(2);
            majl(j)=stat.MajorAxisLength;
            minl(j)=stat.MinorAxisLength;
            euler(j)=stat.EulerNumber;
            area(j)=stat.Area;
        elseif size(stat,1)>1
            %disp('too much white')
            biggerArea=max(cat(1,stat.Area));
            bigger=find([stat.Area] == biggerArea,1);
            cx(j)=stat(bigger,1).Centroid(1);
            cy(j)=stat(bigger,1).Centroid(2);
            majl(j)=stat(bigger,1).MajorAxisLength;
            minl(j)=stat(bigger,1).MinorAxisLength;
            euler(j)=stat(bigger,1).EulerNumber;
            area(j)=stat(bigger,1).Area;
        else
            %disp('not enough white')
            cx(j)=NaN;
            cy(j)=NaN;
            majl(j)=NaN;
            minl(j)=NaN;
            euler(j)=NaN;
            area(j)=NaN;
        end
        crop1=imadjust(crop0);
        imshow(pupil0,'InitialMagnification','fit');
        %try viscircles([cx(j) cy(j)],majl(j)/2); catch ; end
       % try 
            theta = 0 : 0.01 : 2*pi;
            x = majl(j)/2 * cos(theta) + cx(j);
            y = minl(j)/2 * sin(theta) + cy(j);
            hold on
            plot(x, y, 'LineWidth', 3);
            hold off% catch ; end
            disp([max(majl/majl(1)*100) min(majl/majl(1)*100) max(minl/minl(1)*100) min(minl/minl(1)*100)])
    
    j=j+1;
    end

end
pupil.cx=cx;
pupil.cy=cy;
pupil.majl=majl;
pupil.minl=minl;
pupil.euler=euler;
pupil.position=position;
pupil.numimages=numimages;
pupil.area=area;

data.pupil=pupil;