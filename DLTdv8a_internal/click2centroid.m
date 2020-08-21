function [cp]=click2centroid(app,cp,axn,imdat)

% Use the centroid locating tools in the MATLAB image analysis toolbox to
% pull the mouse click to the centroid of a putative marker

psize=app.SearchareawidthEditField.Value; % search area size

% make sure we have our image data
if exist('imdat','var')==0
  kids=get(app.handles{axn+300},'Children'); % children of current axis
  imdat=get(kids(end),'CData'); % read current image
end
x=round(cp(1,1)); % get an integer X point
y=round(cp(1,2)); % get an integer Y point

% determine the base area around the mouse click to
% grab for centroid finding
try
  roi=double(imdat(y-psize:y+psize,x-psize:x+psize));
catch
  % if the above command fails return without adjusting cp
  return
end

% apply gamma and rescale
roi=roi.^app.VideoGammaSlider.Value;
roi=roi-min(min(roi));
roi=roi*(1/max(max(roi)));

% detrend the roibase to try and remove any image-wide edges
roibase=rot90(detrend(rot90(detrend(roi))),-1);

% rescale roibase again following the detrend
roibase=roibase-min(min(roibase));
roibase=roibase*(1/max(max(roibase)));

% threshhold for conversion to binary image
level=graythresh(roibase);

% convert to binary image
roiB=imbinarize(roibase,level+(1-level)*0.5);

% create alternative, inverted binary image
roiBi=imbinarize(roibase,level/1.5);
roiBi=logical(roiBi*-1+1);

% identify objects
[labeled_roiB]=bwlabel(roiB,4);
[labeled_roiBi]=bwlabel(roiBi,4);

% get object info
roiB_data=regionprops(labeled_roiB,'basic');
roiBi_data=regionprops(labeled_roiBi,'basic');

% for each roi*_data, find the largest object
roiB_sz(1:length(roiB_data))=NaN;
for i=1:length(roiB_data)
  roiB_sz(i)=roiB_data(i).Area;
end
roiB_dx=find(roiB_sz==max(roiB_sz));

roiBi_sz(1:length(roiBi_data))=NaN;
for i=1:length(roiBi_data)
  roiBi_sz(i)=roiBi_data(i).Area;
end
roiBi_dx=find(roiBi_sz==max(roiBi_sz));

% check "white" or "black" option from menu
% 1 == black, 2 == white
whiteBlack=app.MarkercentroidsearchDropDown.Value;
if strcmpi('black',whiteBlack)
  % black points
  % create weighted centroid from bounding box
  bb=roiBi_data(roiBi_dx(1)).BoundingBox;
  bb(1:2)=ceil(bb(1:2));
  bb(3:4)=(bb(3:4)-1)+bb(1:2);
  blk=1-roibase(bb(2):bb(4),bb(1):bb(3));
else
  % white points
  % create weighted centroid from bounding box
  bb=roiB_data(roiB_dx(1)).BoundingBox;
  bb(1:2)=ceil(bb(1:2));
  bb(3:4)=(bb(3:4)-1)+bb(1:2);
  blk=roibase(bb(2):bb(4),bb(1):bb(3));
end
ySeq=(bb(2):bb(4))';
yWeight=sum(blk,2);
cY=sum(ySeq.*yWeight)/sum(yWeight);
xSeq=(bb(1):bb(3));
xWeight=sum(blk,1);
cX=sum(xSeq.*xWeight)/sum(xWeight);
cp(1,1)=cp(1,1)+cX-psize-1;
cp(1,2)=cp(1,2)+cY-psize-1;