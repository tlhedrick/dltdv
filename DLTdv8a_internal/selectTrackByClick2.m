function [] = selectTrackByClick2(src,eventdata,h,app,fr,vnum)

% function [] = selectTrackByClick2(src,eventdata,h,app,fr,vnum)
%
% Callback for clicks on digitized points

% need to figure out sp from the clicked location and the line ID info
% stored in the linegroup userdata

% clicked location
cp=get(get(gcbo,'Parent'),'CurrentPoint');
cp=cp(1,1:2);

% xy locations in this video
xy(:,1)=get(gcbo,'Xdata');
xy(:,2)=get(gcbo,'Ydata');
d=rnorm(repmat(cp,size(xy,1),1)-xy);
idx=find(d==min(d));
pnums=get(gcbo,'Userdata'); % point numbers stored as userdata on the line
sp=pnums(idx(1));

% update app
app.sp=sp;

% update pull-down menu
app.CurrentpointDropDown.Value=sp;

% get new xy location in the frame in question (for magnified plot)
pt=app.xypts(fr,(vnum*2-1:vnum*2)+(sp-1)*2*app.nvid);

% update the magnified point view
updateSmallPlot(app,h,vnum,pt);

% do a quick screen redraw
quickRedraw(app,h,sp,fr);