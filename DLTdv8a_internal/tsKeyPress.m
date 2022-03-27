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
  
  stepSize=app.StepsizeEditField.Value; % step size
  bigStepSize=app.BigstepsizeEditField.Value; % big step size
  
  if isnan(axn)
    disp('Error: The mouse pointer is not in an axis.')
    return
  end
  cp=sp2full(app.xypts(fr,(axn*2-1:axn*2)+(app.sp-1)*2*app.nvid)); % set current point to xy value
  if cc=='f' && fr+stepSize <= smax
    if autoT==3 || autoT==5 && isfinite(cp(1)) % semi-auto tracking
      keyadvance=1; % set keyadvance variable for DLTautotrack function
      DLTautotrack3fun(app,h,keyadvance,axn,cp,fr,sp);
    end
    app.FrameNumberSlider.Value=fr+stepSize; % forward stepSize frames
    fr=fr+1;
  elseif cc=='b' && fr-stepSize >= smin
    app.FrameNumberSlider.Value=fr-stepSize; % back stepSize frames
    fr=fr-1;
  elseif cc=='F' && fr+bigStepSize < smax
    app.FrameNumberSlider.Value=fr+bigStepSize; % current frame + bigStepSize
    fr=fr+50;
  elseif cc=='F' && fr+bigStepSize > smax
    app.FrameNumberSlider.Value=smax; % set to last frame
    fr=smax;
  elseif cc=='B' && fr-bigStepSize >= smin
    app.FrameNumberSlider.Value=fr-bigStepSize;% current frame - bigStepSize
    fr=fr-50;
  elseif cc=='B' && fr-bigStepSize < smin
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
  
  pt=app.xypts(fr,((axh-300)*2-1:(axh-300)*2)+(app.sp-1)*2*app.nvid);
  
  % update the magnified point view
  updateSmallPlot(app,app.handles,(axh-300),pt);
  
  % do a quick screen redraw
  quickRedraw(app,app.handles,app.sp,fr);
  
elseif cc=='D' % remove current point from the data array
  sp=app.sp; % store current selected point (will be deleted)
  if app.numpts==1
    beep
    disp('You need to have 2 or more points defined to remove one.')
  else
    [button] = questdlg(['Really remove point #',num2str(sp),' from the data?'],'Really?');
    
    if strcmp(button,'Yes')
      % store backup for undo
      storeUndo(app);
      
      % update number of points
      app.numpts=app.numpts-1;
      
      % update points pull-down menu
      ptstring={};
      for i=1:app.numpts
        ptstring{i}=num2str(i);
      end
      app.CurrentpointDropDown.Items=ptstring;
      app.CurrentpointDropDown.Value=ptstring{max([1,sp-1])};
      app.sp=max([1,sp-1]);
      
      % update the data matrices by removing the deleted point
      app.xypts(:,(1:2*app.nvid)+(sp-1)*2*app.nvid)=[];
      app.dltpts(:,sp*3-2:sp*3)=[];
      app.dltres(:,sp)=[];
      
      fullRedraw(app);
      disp('Point deleted.')
    else
      disp('Delete canceled.')
    end
  end
  
elseif cc=='J' % bring up joiner interface
  sp=app.sp; % store current selected point
  ptList=[];
  ptSeq=(1:app.numpts);
  for i=1:numel(ptSeq)
    ptList{i}=['Point #',num2str(i)];
  end
  [selection,ok]=listdlg('liststring',ptList,'Name',...
    'Point picker','PromptString',...
    ['Pick a point to join with point #',num2str(sp)],'listsize',...
    [300,200],'selectionmode','single');
  
  if ok==true && sp~=selection
    spD=max([sp,selection]); % will be deleted
    sp=min([sp,selection]); % will be kept
    storeUndo(app);
    
    % extract arrays and use nanmean to combine
    m = sp2full(app.xypts(:,(1:2*app.nvid)+(sp-1)*2*app.nvid));
    m(:,:,2) = sp2full(app.xypts(:,(1:2*app.nvid)+(spD-1)*2*app.nvid));
    m=nanmean(m,3);
    m(isnan(m))=0;
    app.xypts(:,(1:2*app.nvid)+(sp-1)*2*app.nvid)=m;
    
    % delete old points
    app.xypts(:,(1:2*app.nvid)+(spD-1)*2*app.nvid)=[];
    app.dltpts(:,spD*3-2:spD*3)=[];
    app.dltres(:,spD)=[];
    
    app.numpts=app.numpts-1; % update number of points
    
    % update the drop-down menu
    ptstring={};
    for i=1:app.numpts
      ptstring{i}=num2str(i);
    end
    app.CurrentpointDropDown.Items=ptstring;
    app.CurrentpointDropDown.Value=ptstring{app.sp};
    
    % Compute 3D coordinates + residuals
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if app.dlt
      %added dedistortion (Baier 1/16/06) (modified Hedrick 6/23/08)
      udist=m;
      udist(udist==0)=NaN;
      for j=1:size(udist,2)/2
        if isempty(app.camud{j})==false
          udist(:,j*2-1:j*2)=applyTform(app.camud{j},udist(:,j*2-1:j*2));
        end
      end
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      [rawResults,rawRes]=dlt_reconstruct_v2(app.dltcoef,udist);
      app.dltpts(:,sp*3-2:sp*3)=full2sp(rawResults(:,1:3));
      app.dltres(:,sp)=full2sp(rawRes);
    end
    
    fullRedraw(app);
    
  elseif sp==selection
    disp('You cannot join a point to itself.')
  else
    disp('Point joining canceled.')
  end
  
end

% fullRedraw(app)
% % update the magnified point view
% cp=sp2full(app.xypts(fr,(app.lastvnum*2-1:app.lastvnum*2)+(sp-1)*2*app.nvid)); % set current point to xy value
% updateSmallPlot(app,app.handles,app.lastvnum,cp);