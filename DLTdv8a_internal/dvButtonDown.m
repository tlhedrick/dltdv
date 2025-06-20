function [] = dvButtonDown(varargin)

% handle button clicks in image axes
axh=varargin{1}; % handle to axis
event=varargin{2}; % event data
app=varargin{3}; % app

% get autotrack mode #: 1=off, 2=advance, 3=semi, 4=auto, 5=multi
autoT=find(startsWith(app.AutotrackmodeDropDown.Items,app.AutotrackmodeDropDown.Value));

cp=get(gcbo,'CurrentPoint'); % xy coordinates, not quite the same as event.IntersectionPoint??
p=get(gcbo,'Parent');
axn=getappdata(p,'videoNumber'); % axis handle number

% alternate location for the click data (if coming from keypresses)
if isempty(axn)
  cp=varargin{4};
  p=get(axh,'Parent');
  axn=getappdata(p,'videoNumber');
end

seltype=event.Button; % 1 = left, 3 = right, 2 = middle

fr=round(app.FrameNumberSlider.Value); % get the current frame
sp=app.sp;

% different actions depend on selection types
if seltype == 1 || seltype == 3 % left or right click
  % set NaN point for right click
  if seltype==3
    cp(:,:)=0;
    % scan for centroid if left click & GUI option set
  elseif seltype==1 && strcmp('none',app.MarkercentroidsearchDropDown.Value)==false
    [cp]=click2centroid(app,cp,axn);
  end
  
  % set the points for the current frame
  app.xypts(fr,axn*2-1+(sp-1)*2*app.nvid)=cp(1,1); % set x point
  app.xypts(fr,axn*2+(sp-1)*2*app.nvid)=cp(1,2); % set y point
  
  % DLT update if 2 or more xy pts
  if (sum(app.xypts(fr,(1:2*app.nvid)+(sp-1)*2*app.nvid)~=0) >= 4 && app.dlt==1) || app.dlt2d==true
    % subframe interpolation
    try
      xy=sp2full(app.xypts(fr-1:fr+1,(1:2*app.nvid)+(sp-1)*2*app.nvid));
      xyI=xy;
      sfi=mod(full(app.offset(fr,:)),1); % subframe interpolation
      skel=(-1:1)'; % interpolation sequence
      for i=1:app.nvid % loop through each camera
        ndx=find(isfinite(xy(:,i*2)));
        if numel(ndx)>1
          xyI(ndx,i*2-1:i*2)=interp1(skel(ndx),xy(ndx,i*2-1:i*2),skel(ndx)+sfi(i),'linear','extrap');
        end
      end
      udist=xyI(2,:);
    catch % fallback to no interpolation
      udist=sp2full(app.xypts(fr,(1:2*app.nvid)+(sp-1)*2*app.nvid));
    end
    for i=1:numel(udist)/2
      if isempty(app.camud{i})==false
        udist(1,i*2-1:i*2)=applyTform(app.camud{i},udist(1,i*2-1:i*2));
      end
    end
    [xyz,res]=dlt_reconstruct_v2(app.dltcoef,udist);
    app.dltpts(fr,sp*3-2:sp*3)=xyz(1:3); % get the DLT points
    app.dltres(fr,sp)=res; % get the DLT residual
  else
    app.dltpts(fr,sp*3-2:sp*3)=0; % set DLT points to 0
    app.dltres(fr,sp)=0; % set DLT residuals to 0
  end
  
  % new data available, change the recently saved parameter to false
  app.recentlysaved=0;
  
  % zoomed window update
  updateSmallPlot(app,app.handles,axn,cp);
  
  % quick screen refresh to show the new point & possibly DLT info if
  % we're not going to advance to the next frame automatically
  if autoT==1 || seltype==3
    quickRedraw(app,app.handles,sp,fr);
  end
end % end of click selection type processing for normal & alt clicks

% process auto-tracker options that depend on click
% seltypes:
% normal = left click
% alt = right click
% extend = middle click or left+right
if seltype==1 && autoT>1
    stepSize=app.FrameadvancestepsizeEditField.Value;
  if autoT==2 && fr+stepSize<=app.FrameNumberSlider.Limits(2) % auto-advance
    
    app.FrameNumberSlider.Value=fr+stepSize; % current frame + stepSize
    fr=fr+stepSize;
    % full redraw of the screen
    fullRedraw(app);
    % update the control / zoom window
    cp=app.xypts(fr,(axn*2-1:axn*2)+(sp-1)*2*app.nvid);
    updateSmallPlot(app,app.handles,axn,cp);
  elseif autoT>2 && autoT<5 % autoT = 3 (semi) or autoT = 4 (full)
    keyadvance=0; % set keyadvance variable for DLTautotrack3
    DLTautotrack3fun(app,app.handles,keyadvance,axn,cp,fr,sp);
    fullRedraw(app);
  else
    fullRedraw(app); % mostly for multi-track left or right click
  end
elseif seltype==2 && autoT==5
  keyadvance=2; % set keyadvance variable for DLTautotrack function
  %axn=1; % default axis
  DLTautotrack3fun(app,app.handles,keyadvance,axn,cp,fr,sp);
  
  % full redraw of the screen
  fullRedraw(app);
end