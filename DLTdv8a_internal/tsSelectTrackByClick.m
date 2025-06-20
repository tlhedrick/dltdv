function [] = tsSelectTrackByClick(varargin)

% need to figure out sp from the clicked location and the line ID info
% stored in the linegroup userdata

src=varargin{1};
eventdata=varargin{2};
app=varargin{3};

% figure out what the timeseries window is plotting
idx=get(app.handles{603},'value');

% get frame number
frClick=round(eventdata.IntersectionPoint(1));
fr=round(app.FrameNumberSlider.Value); % current frame #

if app.dlt && idx<=3
  % xyz data
  vals=sp2full(app.dltpts(frClick,(idx:3:end)));
  d=abs(vals-eventdata.IntersectionPoint(2));
  doXY=false;
elseif app.dlt==true
  doXY=true;
  idx=idx-3; % remove X-Y-Z index positions
else
  doXY=true;
end

if doXY
  % xy data
  vals=sp2full(app.xypts(frClick,(idx:app.nvid*2:end)));
  d=abs(vals-eventdata.IntersectionPoint(2));
end

sp=find(d==min(d));
sp=sp(1);

% update points pull-down menu
app.sp=sp;
app.CurrentpointDropDown.Value=app.sp; % update menu

% get new xy location in the frame in question (for magnified plot)
pt=app.xypts(fr,(app.lastvnum*2-1:app.lastvnum*2)+(sp-1)*2*app.nvid);

% update the magnified point view
cp=sp2full(app.xypts(fr,(app.lastvnum*2-1:app.lastvnum*2)+(sp-1)*2*app.nvid)); % set current point to xy value
updateSmallPlot(app,app.handles,app.lastvnum,cp);

% do a quick screen redraw
quickRedraw(app,app.handles,app.sp,fr);