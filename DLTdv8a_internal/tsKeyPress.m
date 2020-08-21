function [] = tsKeyPress(varargin)

% unpack inputs
app=varargin{3};
event=varargin{2};
fh=varargin{1};
cc=event.Character;

% set a reasonable figure axis handle
axh=app.lastaxh;

fr=round(app.FrameNumberSlider.Value); % get current slider value

% get autotrack mode #: 1=off, 2=advance, 3=semi, 4=auto, 5=multi
autoT=find(startsWith(app.AutotrackmodeDropDown.Items,app.AutotrackmodeDropDown.Value));

if isempty(cc)
  return
elseif cc=='x' % autotrack shift
  
  
  if autoT<4 % autotrack menu
    app.AutotrackmodeDropDown.Value=app.AutotrackmodeDropDown.Items{autoT+1};
  else
    app.AutotrackmodeDropDown.Value=app.AutotrackmodeDropDown.Items{1};
  end
  return
elseif cc=='X' % got to multitrack
  app.AutotrackmodeDropDown.Value=app.AutotrackmodeDropDown.Items{5};
  return
  % check for valid movement keys
elseif cc=='f' || cc=='b' || cc=='F' || cc=='B' || cc=='<' || cc=='>' && axh~=0
  fr=round(app.FrameNumberSlider.Value); % get current slider value
  smax=app.FrameNumberSlider.Limits(2); % max slider value
  smin=app.FrameNumberSlider.Limits(1); % min slider value
  axn=axh-300; % axis number
  
  if isnan(axn)
    disp('Error: The mouse pointer is not in an axis.')
    return
  end
  cp=sp2full(app.xypts(fr,(axn*2-1:axn*2)+(app.sp-1)*2*app.nvid)); % set current point to xy value
  if cc=='f' && fr+1 <= smax
    if autoT==3 || autoT==5 && isfinite(cp(1)) % semi-auto tracking
      keyadvance=1; % set keyadvance variable for DLTautotrack function
      DLTautotrack3fun(app,h,keyadvance,axn,cp,fr,sp);
    end
    app.FrameNumberSlider.Value=fr+1; % forward 1 frame
    fr=fr+1;
  elseif cc=='b' && fr-1 >= smin
    app.FrameNumberSlider.Value=fr-1; % back 1 frame
    fr=fr-1;
  elseif cc=='F' && fr+50 < smax
    app.FrameNumberSlider.Value=fr+50; % current frame + 50
    fr=fr+50;
  elseif cc=='F' && fr+50 > smax
    app.FrameNumberSlider.Value=smax; % set to last frame
    fr=smax;
  elseif cc=='B' && fr-50 >= smin
    app.FrameNumberSlider.Value=fr-50;% current frame - 50
    fr=fr-50;
  elseif cc=='B' && fr-50 < smin
    app.FrameNumberSlider.Value=smin; % set to first frame
    fr=smin;
  elseif cc=='<' || cc=='>' % switch to start or end of this point in this camera
    vnum=axh-300;
    idx=find(app.xypts(:,vnum*2-1+(app.sp-1)*2*app.nvid)~=0);
    if numel(idx)>0
      if cc=='<'
        app.FrameNumberSlider.Value=idx(1);
      else
        app.FrameNumberSlider.Value=idx(end);
      end
    end
  end
  
  % full redraw of the screen
  fullRedraw(app);
  
  % update the control / zoom window
  % 1st retrieve the cp from the data file in case the autotracker
  % changed it
  cp=app.xypts(fr,(app.lastvnum*2-1:app.lastvnum*2)+(app.sp-1)*2*app.nvid);
  updateSmallPlot(app,app.handles,app.lastvnum,cp);
  
elseif cc=='.' || cc==',' % change point
  % get current pull-down list (available points)
  ptnum=numel(app.CurrentpointDropDown.Items); % number of points
  if cc==',' && app.sp>1 % decrease point value if able
    app.sp=app.sp-1;
  elseif cc=='.' && app.sp<ptnum % increase pt value if able
    app.sp=app.sp+1;
  else
    % do nothing
  end
  app.CurrentpointDropDown.Value=num2str(app.sp); % update menu
  
  pt=app.xypts(fr,(vnum*2-1:vnum*2)+(app.sp-1)*2*app.nvid);
  
  % update the magnified point view
  updateSmallPlot(app,app.handles,vnum,pt);
  
  % do a quick screen redraw
  quickRedraw(app,app.handles,app.sp,fr);
end

% fullRedraw(app)
% % update the magnified point view
% cp=sp2full(app.xypts(fr,(app.lastvnum*2-1:app.lastvnum*2)+(sp-1)*2*app.nvid)); % set current point to xy value
% updateSmallPlot(app,app.handles,app.lastvnum,cp);