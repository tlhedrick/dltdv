function [] = dvKeyPress(varargin)

% handle key presses in image axes
me=varargin{1}; % handle to figure
event=varargin{2}; % event data
app=varargin{3}; % app

% seem to get mouse clicks as ghost keypresses?
if isempty(event.Character)
  return
end

% start processing the event
cc=event.Character; % the character from the keypress
pl=get(0,'PointerLocation'); % pointer location on the screen
pos=get(me,'Position'); % get the figure position
fr=app.FrameNumberSlider.Value;
sp=app.sp;
% get autotrack mode #: 1=off, 2=advance, 3=semi, 4=auto, 5=multi
autoT=find(startsWith(app.AutotrackmodeDropDown.Items,app.AutotrackmodeDropDown.Value));

% calculate pointer location in normalized units
plocal=[(pl(1)-pos(1,1)+1)/pos(1,3), (pl(2)-pos(1,2)+1)/pos(1,4)];

% if the keypress is empty or is a lower-case x, shut off the
% auto-tracker
if cc=='x'
  app.drawVid(:)=true;
  
  if autoT<4 % autotrack menu
    app.AutotrackmodeDropDown.Value=app.AutotrackmodeDropDown.Items{autoT+1};
  else
    app.AutotrackmodeDropDown.Value=app.AutotrackmodeDropDown.Items{1};
  end
  return
elseif cc=='X'
  app.AutotrackmodeDropDown.Value=app.AutotrackmodeDropDown.Items{5};
  return
else % figure out what axis & video started the callback
  if plocal(1)<=0.99 && plocal(2)<=0.99
    vnum=getappdata(me,'videoNumber'); % video number
    axh=vnum+300; % address of axis handle in the handles array
    
    % store the axis handle and video number for use later
    app.lastaxh=axh;
    app.lastvnum=vnum;
  else
    %disp('The mouse pointer is not over a video.');
    %return
    try
      axh=app.lastaxh;
      vnum=app.lastvnum;
    catch
      estr=['The mouse pointer is not over a video & the last ', ...
        'identity is uncertain.'];
      disp(estr);
      return
    end
    
  end
end

% check for zoom keys
if (cc=='=' || cc=='-' || cc=='r') && axh~=0 
  
  % zoom in or out as indicated
  if axh~=0
    axpos=get(app.handles{axh},'Position'); % axis position in figure
    xl=xlim; yl=ylim; % x & y limits on axis
    % calculate the normalized position within the axis
    plocal2=[(plocal(1)-axpos(1,1))/axpos(1,3) 1-(plocal(2) ...
      -axpos(1,2))/axpos(1,4)];
    
    % check to make sure we're inside the figure!
    if sum(plocal2>0.99 | plocal2<0)>0
      disp('The pointer must be over a video during zoom operations.')
      return
    end
    
    % calculate the actual pixel postion of the pointer
    pixpos=round([(xl(2)-xl(1))*plocal2(1)+xl(1) ...
      (yl(2)-yl(1))*plocal2(2)+yl(1)]);
    
    % axis location in pixels (idealized)
    axpix(3)=pos(3)*axpos(3);
    axpix(4)=pos(4)*axpos(4);
    
    % set the figure xlimit and ylimit
    if cc=='=' % zoom in
      xlim([pixpos(1)-(xl(2)-xl(1))/3 pixpos(1)+(xl(2)-xl(1))/3]);
      ylim([pixpos(2)-(yl(2)-yl(1))/3 pixpos(2)+(yl(2)-yl(1))/3]);
    elseif cc=='-' % zoom out
      xlim([pixpos(1)-(xl(2)-xl(1))/1.5 pixpos(1)+(xl(2)-xl(1))/1.5]);
      ylim([pixpos(2)-(yl(2)-yl(1))/1.5 pixpos(2)+(yl(2)-yl(1))/1.5]);
    else % restore zoom
      xlim([0 app.movsizes(vnum,2)]);
      ylim([0 app.movsizes(vnum,1)]);
    end
    
    % set drawnow for the axis in question
    app.drawVid(vnum)=true;
    
  end
  
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
  cp=sp2full(app.xypts(fr,(axn*2-1:axn*2)+(sp-1)*2*app.nvid)); % set current point to xy value
  if cc=='f' && fr+stepSize <= smax
    if (autoT==3 || autoT==5) && isfinite(cp(1)) % semi-auto tracking
      keyadvance=1; % set keyadvance variable for DLTautotrack function
      DLTautotrack3fun(app,app.handles,keyadvance,axn,cp,fr,sp);
    end
    app.FrameNumberSlider.Value=fr+stepSize; % forward stepSize frame
    fr=fr+1; 
  elseif cc=='b' && fr-stepSize >= smin
    app.FrameNumberSlider.Value=fr-stepSize; % back stepSize frame
    fr=fr-1;
  elseif cc=='F' && fr+bigStepSize < smax
    app.FrameNumberSlider.Value=fr+50; % current frame + bigStepSize
    fr=fr+bigStepSize;
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
    ptval=app.sp; % selected point
    idx=find(app.xypts(:,vnum*2-1+(sp-1)*2*app.nvid)~=0);
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
  cp=app.xypts(fr,(vnum*2-1:vnum*2)+(sp-1)*2*app.nvid);
  updateSmallPlot(app,app.handles,vnum,cp);
  
elseif cc=='n' % add a new point
  yesNo=questdlg('Are you sure you want to add a point?',...
    'Add a point?','Yes','No','No');
  if strcmp(yesNo,'Yes')==1
    addPoint(app)
    return
  else
    return
  end
  
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
  
elseif cc=='i' || cc=='j' || cc=='k' || cc=='m' || cc=='4' || ...
    cc=='8' || cc=='6' || cc=='2' % nudge point
  % check and see if there is a point to nudge, get it's value if
  % possible
  
  if app.xypts(fr,vnum*2-1+(app.sp-1)*2*app.nvid)==0
    return % no point defined
  else
    pt=sp2full(app.xypts(fr,[vnum*2-1:vnum*2]+(app.sp-1)*2*app.nvid));
  end
  
  % modify pt based on the 'nudge' value
  nudge=0.5; % 1/2 pixel nudge
  if cc=='i' || cc=='8'
    pt(1,2)=pt(1,2)-nudge; % up
  elseif cc=='j' || cc=='4'
    pt(1,1)=pt(1,1)-nudge; % left
  elseif cc=='k' || cc=='6'
    pt(1,1)=pt(1,1)+nudge; % right
  else
    pt(1,2)=pt(1,2)+nudge; % down
  end
  
  % set the modified point
  app.xypts(fr,[vnum*2-1:vnum*2]+(app.sp-1)*2*app.nvid)=pt;
  
  % DLT update if 2 or more xy pts
  if sum(app.xypts(fr,(1:2*app.nvid)+(app.sp-1)*2*app.nvid)~=0) >= 4 && app.dlt==1
    
    % subframe interpolation
    try
      xy=sp2full(app.xypts(fr-1:fr+1,(1:2*app.nvid)+(sp-1)*2*app.nvid));
      sfi=mod(full(app.offset(fr,:)),1); % subframe interpolation
      skel=(-1:1)'; % interpolation sequence
      for i=1:app.nvid % loop through each camera
        ndx=find(isfinite(xy(:,i*2)));
        if numel(ndx)>1
          xyI(:,i*2-1:i*2)=interp1(skel(ndx),xy(ndx,i*2-1:i*2),skel+sfi(i),'linear','extrap');
        else
          xyI(:,i*2-1:i*2)=xy(:,i*2-1:i*2);
        end
      end
      udist=xyI(2,:);
    catch % fallback to no interpolation
      udist=sp2full(app.xypts(fr,(1:2*app.nvid)+(sp-1)*2*app.nvid));
    end
    
    % old version without subframe interpolation
    % udist=sp2full(app.xypts(fr,(1:2*app.nvid)+(app.sp-1)*2*app.nvid));
    for i=1:numel(udist)/2
      if isempty(app.camud{i})==false
        udist(1,i*2-1:i*2)=applyTform(app.camud{i},udist(1,i*2-1:i*2));
      end
    end
    [xyz,res]=dlt_reconstruct_v2(app.dltcoef,udist);
    app.dltpts(fr,app.sp*3-2:app.sp*3)=xyz(1:3); % get the DLT points
    app.dltres(fr,app.sp)=res; % get the DLT residual
  else
    app.dltpts(fr,app.sp*3-2:app.sp*3)=0; % set DLT points to 0
    app.dltres(fr,app.sp)=0; % set DLT residuals to 0
  end
  
  % new data available, change the recently saved parameter to false
  app.recentlysaved=0;
  
  % update the magnified point view
  updateSmallPlot(app,app.handles,vnum,pt);
  
  % update text fields
  updateTextFields(app);
  
  % do a quick screen redraw
  quickRedraw(app,app.handles,app.sp,fr);
  
elseif cc==' ' % space bar (digitize a point)
  
%   % handle button clicks in image axes
%   fh=varargin{1}; % handle to axis
%   event=varargin{2}; % event data
%   app=varargin{3}; % app

  axpos=get(app.handles{axh},'Position'); % axis position in figure
  xl=xlim(app.handles{axh}); yl=ylim(app.handles{axh}); % x & y limits on axis
  % calculate the normalized position within the axis
  plocal2=[(plocal(1)-axpos(1,1))/axpos(1,3) 1-(plocal(2) ...
    -axpos(1,2))/axpos(1,4)];
  
  % check to make sure we're inside the figure!
  if sum(plocal2>0.99 | plocal2<0)>0
    disp('The pointer must be over a video to digitize a point.')
    return
  end
  
  % calculate the actual pixel postion of the pointer
  pixpos=([(xl(2)-xl(1)+0)*plocal2(1)+xl(1) ...
    (yl(2)-yl(1)+0)*plocal2(2)+yl(1)]);

  % create a simulated left-click
  event2=[];
  event2.Button=1;
  dvButtonDown(app.handles{axh},event2,app,pixpos)

  return
  
elseif cc=='z' % delete the current point

  % create a simulated right-click
  event2=[];
  event2.Button=3;
  dvButtonDown(app.handles{axh},event2,app,[0,0])
  
  return
  
elseif cc=='R' % recompute 3D locations
  disp('Recomputing all 3D coordinates.')
  [filename, pathname] = uigetfile('*.csv', 'Load new coefficients?');
  if isempty(filename)==false && filename~=0
    app.dltcoef=importdata([pathname,filename]);
    app.dltFileName=[pathname,filename];
  end
  updateDLTdata(app,1:app.numpts); % update all DLT coefficients
  
elseif cc=='U' % undo prior whole-point delete/swap/split/join
  [button] = questdlg(['Undo the last whole-point delete/join/split/swap operation or neural network application?'],'Undo?');
  if strcmp(button,'Yes')
    restoreUndo(app);
    fullRedraw(app);
    
    disp('Undo processed')
  else
    disp('Undo cancelled')
  end
  
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
  
elseif cc=='S' % bring up swap interface
  ptList=[];
  ptSeq=(1:app.numpts);
  for i=1:numel(ptSeq)
    ptList{i}=['Point #',num2str(i)];
  end
  [selection,ok]=listdlg('liststring',ptList,'Name',...
    'Point picker','PromptString',...
    ['Pick a point to swap with point #',num2str(sp)],'listsize',...
    [300,200],'selectionmode','single');
  
  if ok==true && sp~=selection
    storeUndo(app);
    xytmp = app.xypts;
    dltpttmp = app.dltpts;
    dltrestmp = app.dltres;
    minsp = min([sp,selection]);
    maxsp = max([sp,selection]);
    app.xypts(:,(1:2*app.nvid)+(minsp-1)*2*app.nvid)=xytmp(:,(1:2*app.nvid)+(maxsp-1)*2*app.nvid);
    app.xypts(:,(1:2*app.nvid)+(maxsp-1)*2*app.nvid)=xytmp(:,(1:2*app.nvid)+(minsp-1)*2*app.nvid);
    
    app.dltpts(:,minsp*3-2:minsp*3)=dltpttmp(:,maxsp*3-2:maxsp*3);
    app.dltpts(:,maxsp*3-2:maxsp*3)=dltpttmp(:,minsp*3-2:minsp*3);
    
    app.dltres(:,minsp)=dltrestmp(:,maxsp);
    app.dltres(:,maxsp)=dltrestmp(:,minsp);
    
    fullRedraw(app);
    
    disp(['Points ',num2str(sp),' and ',num2str(selection),' swapped.'])
    
  elseif sp==selection
    disp('It does not make any sense to swap a point with itself.')
  else
    disp('Point swap canceled')
  end
  
elseif cc=='Y' % bring up point splitter interface
  % get the range of points to split out
  [rng]=inputdlg({'Start of points to split out','End of range'},'Set split range',1);
  
  if isempty(rng)==false
    try
      numrng(1)=str2num(rng{1});
      numrng(2)=min([size(app.xypts,1),str2num(rng{2})]);
    catch
      beep
      disp('Point splitting input error')
      return
    end
    
    % backup data
    storeUndo(app);
    
    % create a new point
    app.xypts(:,(1:2*app.nvid)+app.numpts*2*app.nvid)=0;
    
    % fill in the range
    app.xypts(numrng(1):numrng(2),(vnum*2-1:vnum*2)+app.numpts*2*app.nvid)= ...
      app.xypts(numrng(1):numrng(2),(vnum*2-1:vnum*2)+(sp-1)*2*app.nvid);
    
    % delete the split points
    app.xypts(numrng(1):numrng(2),(vnum*2-1:vnum*2)+(sp-1)*2*app.nvid)=0;
    
    app.numpts=app.numpts+1; % update number of points
    
    % update other data arrays
    app.dltpts(:,app.numpts*3-2:app.numpts*3)=0;
    app.dltres(:,app.numpts)=0;
    
    % update the drop-down menu
    ptstring={};
    for i=1:app.numpts
      ptstring{i}=num2str(i);
    end
    app.CurrentpointDropDown.Items=ptstring;
    app.CurrentpointDropDown.Value=ptstring{sp};
    
    % Compute 3D coordinates + residuals
    updateDLTdata(app,sp);
    
    disp(['Point ',num2str(sp),' camera ',num2str(vnum),...
      ' frames ',rng{1},' to ',rng{2},...
      ' moved to point #',num2str(app.numpts)])
    
    fullRedraw(app);
  else
    disp('Point splitting canceled.')
  end
  
elseif cc=='C' % clear the image cache & cache index
  for i=1:numel(app.cdataCacheIdx)
    app.cdataCacheIdx{i}(:)=NaN;
  end
  for i=1:numel(app.cdataCache)
    for j=1:numel(app.cdataCache{i})
      app.cdataCache{i}{j}=[];
    end
  end
  disp('Cleared image cache')
  
else
  % nothing
  
end % end of main keypress evaluation loop