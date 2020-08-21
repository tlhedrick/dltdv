function [] = DLTcal5(varargin)

% function [] = DLTcal5()
%
% DLTcal5 is a graphic interface for creating DLT calibration coefficients
% from an arbitrary frame specification and image series.
%
%	See the associated RTF document for complete usage information
%
% Version 1 - Ty Hedrick 8/1/04
% Version 2 - Ty Hedrick 8/4/05
% Version 3 - Ty Hedrick 3/27/08
% Version 5 - Ty Hedrick 7/12/10

if nargin==0 % no inputs, run the gui initialization routine
  
  % check Matlab version and don't start if not >= 7.  Many of the figure
  % and gui controls changed in the 6.5 --> 7.0 jump and it is no longer
  % possible to support the older versions.
  v=version;
  if str2double(v(1:3))<7
    beep
    disp('DLTcal5 requires MATLAB version 7 or later.')
    return
  end
  
  % check to make sure that mmreader is available
  if exist('mmreader')~=2 && exist('VideoReader')~=2
    beep
    disp('DLTcal5 requires mmreader or VideoReader to read AVIs or other')
    disp('standard video files. Those functions are not available to you')
    disp('so you will only be able to read uncompressed Phantom cine and')
    disp('IDT mrf high speed camera files.')
    disp('Check the Mathworks online documentation to learn about mmreader')
    disp('and VideoReader. Use DLTcal3 if you have an older MATLAB version')
    disp('that has the aviread function.')
  end
  
  call=99; % go creat the GUI (see the Switch statement below)
  
elseif nargin==1 % assume a switchyard call but no data
  call=varargin{1};
  ud=get(gcbo,'Userdata'); % get simple userdata
  h=ud.handles; % get the handles
  uda=get(h(1),'Userdata'); % get complete userdata
  h=uda.handles; % get complete handles
  sp=get(h(32),'Value'); % get the selected point
  
elseif nargin==2 % assume a switchyard call and data
  call=varargin{1};
  uda=varargin{2};
  h=uda.handles; % get complete handles
  sp=get(h(32),'Value'); % get the selected point
  
elseif nargin==3 % switchyard call, data & subfunction specific data
  call=varargin{1};
  uda=varargin{2};
  h=uda.handles; % get complete handles
  sp=get(h(32),'Value'); % get the selected point
  oData=varargin{3}; % store the misc. other variable in oData
else
  disp('DLTcal5: incorrect number of input arguments')
  return
end


% switchyard to handle updating & processing tasks for the figure
switch call
  %% case 99 - GUI figure creation
  case {99} % Initialize the GUI
    
    disp(sprintf('\n'))
    disp('DLTcal5 (updated March 13, 2015)')
    disp(sprintf('\n'))
    disp('Visit http://www.unc.edu/~thedrick/ for more information,')
    disp('tutorials, sample data & updates to this program.')
    disp(sprintf('\n'))
    
    top=20.2; % top of the controls layout
    
    h(1) = figure('Units','characters',... % control figure
      'Color',[0.831 0.815 0.784]','Doublebuffer','on', ...
      'IntegerHandle','off','MenuBar','none',...
      'Name','DLTcal5 controls','NumberTitle','off',...
      'Position',[10 10 58 36.73],'Resize','off',...
      'HandleVisibility','callback','Tag','figure1',...
      'UserData',[],'Visible','on','deletefcn','DLTcal5(13)');
    
    h(29) = uicontrol('Parent',h(1),'Units','characters',... % Video frame
      'Position',[3 top+2.5 51.5 8],'Style','frame','BackgroundColor',...
      [0.568 0.784 1],'string','Points and calibration');
    
    % Points frame part 1
    h(30) = uicontrol('Parent',h(1),'Units','characters',...
      'Position',[3 top-5.7 51.5 7.3],'Style','frame', ...
      'BackgroundColor',[0.788 1 0.576],'string','Points and calibration');
    
    uicontrol('Parent',h(1),'Units','characters',... % Points frame part 2
      'Position',[3 top-19.2 30.5 13.6],'Style','frame',...
      'BackgroundColor',[0.788 1 0.576],'string','Points and calibration');
    
    uicontrol('Parent',h(1),'Units','characters',... % blank string
      'Position',[3.1 top-8.6 30.3 4.6],'Style','text',...
      'BackgroundColor',[0.788 1 0.576],'string','');
    
    uicontrol('Parent',h(1),'Units','characters',... % Points frame part 3
      'Position',[10 top-19.2 44.5 7.0],'Style','frame',...
      'BackgroundColor',[0.788 1 0.576],'string','Points and auto-tracking');
    
    uicontrol('Parent',h(1),'Units','characters',... % blank string
      'Position',[3.1 top-19.1 30.3 14.1],'Style','text',...
      'BackgroundColor',[0.788 1 0.576],'string','');
    
    h(5) = uicontrol('Parent',h(1),'Units','characters',... % frame slider
      'Position',[7.2 top+3.4 44.2 1.2],'String',{  'frame' },...
      'Style','slider','Tag','slider2','Callback',...
      'DLTcal5(1)','Enable','off','Value',1);
    
    % initialize button
    h(6) = uicontrol('Parent',h(1),'Units','characters',...
      'Position',[2.2 top+12.1 22 3],'String','Initialize',...
      'Callback','DLTcal5(0)','ToolTipString', ...
      'Load the frame specification and calibration image files',...
      'Tag','pushbutton1');
    
    % Save data button
    h(7) = uicontrol('Parent',h(1),'Units','characters',...
      'Position',[27 top+13.8 14.4 1.8],'String','Save Data','Tag',...
      'pushbutton3','Callback','DLTcal5(5)','Enable','off');
    
    h(12)=uicontrol('Parent',h(1),... % Color display checkbox
      'Units','characters','BackgroundColor',[0.568 0.784 1],...
      'Position',[43 top+7.3 4 1],'Value',0,'Style','checkbox','Tag',...
      'colorVideos','enable','off','Callback','DLTcal5(9)');
    
    % video gamma slider
    h(13) = uicontrol('Parent',h(1),'Units','characters',...
      'Position',[7.2 top+7.1 28 1.3],'String',{  'gamma' },...
      'Style','slider','Tag','slider1','Min',.1','Max',2,'Value',1,...
      'Callback','DLTcal5(1)', ...
      'Enable','off', 'ToolTipString','Video Gamma slider');
    
    h(14) = uicontrol('Parent',h(1),'Units','characters',... % quit button
      'Position',[43.8 top+12.1 11.2 3],'String','Quit',...
      'Tag','pushbutton4','Callback','DLTcal5(11)','enable','on');
    
    % gamma control label
    h(18) = uicontrol('Parent',h(1),'Units','characters',...
      'BackgroundColor',[0.568 0.784 1],'HorizontalAlignment','left',...
      'Position',[7 top+8.5 20.4 1.3],'String','Video gamma','Style',...
      'text','Tag','text1');
    
    uicontrol('Parent',h(1),'Units','characters',... % color video label
      'BackgroundColor',[0.568 0.784 1],'HorizontalAlignment','left',...
      'Position',[37 top+8.5 15.4 1.3],'String','Display in color',...
      'Style','text','Tag','text1');
    
    % frame slider label
    h(21) = uicontrol('Parent',h(1),'Units','characters',...
      'BackgroundColor',[0.568 0.784 1],'HorizontalAlignment','left',...
      'Position',[7 top+5.0 24.6 1.1],'String','Frame number: NaN/NaN',...
      'Style','text','Tag','text6');
    
    % load previous data button
    h(22) = uicontrol('Parent',h(1),'Units','characters',...
      'Position',[27 top+11.3 14.4 1.7],'String','Load Data',...
      'Tag','pushbutton5','enable','off','Callback','DLTcal5(6)');
    
    h(23) = uicontrol('Parent',h(1),... % Calibration type label
      'Units','characters','BackgroundColor',[0.788 1 0.576],...
      'HorizontalAlignment','left','Position',[7 top-10.5 20.6 1.3],...
      'String','DLT calibration type:','Style','text',...
      'Tag','text15');
    
    menuString='11 parameter | modified 11 parameter';
    h(25) = uicontrol('Parent',h(1),... % Calibration type menu
      'Units','characters',...
      'HorizontalAlignment','left','Position',[7 top-12.2 24.6 1.3],...
      'String',menuString,'Style','popupmenu',...
      'Value',1,'Tag','text16');
    
    h(27) = uicontrol('Parent',h(1),... % DLT average residuals
      'Units','characters','BackgroundColor',[0.788 1 0.576],...
      'HorizontalAlignment','left','Position',[34.5 top-18.0 19 2.6],...
      'String',sprintf('Calibration \nresidual: --'), ...
      'Style','text','Tag','text17');
    
    h(31) = uicontrol('Parent',h(1),... % Current point label
      'Units','characters','BackgroundColor',[0.788 1 0.576],...
      'HorizontalAlignment','left','Position',[7 top-0.5 14.2 1.3],...
      'String','Current point','Style','text','Tag','text13');
    
    h(32) = uicontrol(... % Current point pull-down menu
      'Parent',h(1),'Units','characters','Position',[7 top-2.3 12 1.6],...
      'String',' 1','Style','popupmenu','Value',1,'Tag','popupmenu1', ...
      'Enable','off','Callback','DLTcal5(1)');
    
    % compute coefficients button
    h(33) = uicontrol('Parent',h(1),'Units','characters',...
      'Position',[7 top-15.8 24.6 2.2],'String','Compute coefficients',...
      'Callback','DLTcal5(7)','ToolTipString', ...
      'Compute the DLT coefficients','Tag','pushbutton1', ...
      'enable','off','HorizontalAlignment','center');
    
    h(34) = uicontrol('Parent',h(1), ... % Advance on click label
      'Units','characters','Position',[28 top-3 24.2 3],...
      'BackgroundColor',[0.788 1 0.576],'HorizontalAlignment','left',...
      'Style','text','String',sprintf('Auto-advance \non click:'));
    
    % Advance on click checkbox
    h(35) = uicontrol('Parent',h(1),'Units','characters',...
      'BackgroundColor',[0.788 1 0.576],'Position',[47 top-1.6 3 1.3],...
      'String','','Style','checkbox','Value',0,'Tag','AoC checkbox',...
      'enable','off');
    
    % DLT error analysis button
    h(36) = uicontrol('Parent',h(1),'Units','characters',...
      'Position',[7 top-18.5 24.6 2.2],'String','Semi','Style', ...
      'pushbutton','Tag','radiobutton2','enable','off','Callback', ...
      'DLTcal5(8)','String',sprintf('Error analysis'));
    
    % h(40) movie axes in video figure
    
    h(50) = uicontrol('Parent',h(1),... % Magnified image label
      'Units','characters','BackgroundColor',[0.788 1 0.576],...
      'HorizontalAlignment','left','Position',[34 top-14.0 18.6 1.3],...
      'String','Magnified image:','Style','text','Tag','text18');
    
    % zoomed image axis
    h(51)=axes('Position',[.61 .225 .30 .165],'XTickLabel','', ...
      'YTickLabel','','Visible','on','Parent',h(1),'box','off');
    checkerBoard=chex(1,21,21).*255;
    c=(repmat((0:1/254:1)',1,3)); % grayscale color map
    % display the default image
    image('Parent',h(51),'Cdata',checkerBoard,'CDataMapping','direct');
    colormap(h(51),c)
    xlim(h(51),[1 21]);
    ylim(h(51),[1 21]);
    
    h(54)=uicontrol('Parent',h(1), ... % Centroid finding label
      'Units','characters','Position',[7 top-6.5 24.2 3],...
      'BackgroundColor',[0.788 1 0.576],'HorizontalAlignment','left',...
      'Style','text','String',sprintf('Find marker centroid:'));
    
    % Centroid finding checkbox
    h(55)=uicontrol('Parent',h(1),'Units','characters',...
      'BackgroundColor',[0.788 1 0.576],'Position',[32 top-4.5 4 1],...
      'Value',0,'Style','checkbox','Tag','findCentroidBox',...
      'enable','off','Callback','DLTcal5(14)');
    
    h(56) = uicontrol('Parent',h(1), ... % Centroid color label
      'Units','characters','Position',[8 top-6.4 24.2 1.3],...
      'BackgroundColor',[0.788 1 0.576],'HorizontalAlignment','left',...
      'Style','text','String','Color');
    
    h(57) = uicontrol(... % Centroid color menu
      'Parent',h(1),'Units','characters','Position',[17 top-6.4 15 1.6],...
      'String',{'black','white'},'Style','popupmenu','Value',1, ...
      'Tag','popupmenu3','Enable','off');
    
    h(58) = uicontrol('Parent',h(1),... % Autotrack search width label
      'Units','characters','BackgroundColor',[0.788 1 0.576],...
      'HorizontalAlignment','left','Position',[7 top-8.5 24.2 1.3],...
      'String','Search width','Style','text',...
      'Tag','text15');
    
    h(59) = uicontrol('Parent',h(1),... % Autotrack search area size
      'Units','characters','BackgroundColor',[1 1 1],'Position',...
      [22 top-8.5 7 1.6],'String','9','Style','edit','Tag',...
      'edit7','Callback','DLTcal5(1)','enable','off');
    
    ud.handles=h; % simple userdata object
    
    % for each handle set all handle info in userdata
    for i=1:numel(h)
      try
        set(h(i),'Userdata',ud);
      catch
        % do nothing
      end
    end
    
    return
    
    %% case 0 - Initialize button
  case {0} % Initialize button press from the GUI
    
    % get the calibration frame specification file if necessary
    if isfield(uda,'specdata')==0
      [specfile,specpath]=uigetfile({'*.csv','comma separated values'}, ...
        'Please select your calibration object specification file');
      specdata=dlmread([specpath,specfile],',',1,0); % read the cal. file
      if size(specdata,2)==3 % got a good spec file
        uda.specdata=specdata; % put it in userdata
        uda.specpath=specpath; % keep the path too
        
        % tell the user
        msg=sprintf(...
          'Loaded a %d point calibration object specification file.',...
          size(specdata,1));
        uiwait(msgbox(msg,'Success'));
        % write back any modifications to the main figure userdata
        set(h(1),'Userdata',uda);
        
        cd(specpath); % change to spec path directory
      else
        msg=['The calibration object specification file must have 3 ', ...
          'data columns. Aborting.'];
        msgbox(msg,'Error','error');
        return
      end
      uda.cNum=1; % initial camera # is 1 (first camera)
      
    else % adding a camera to an ongoing calibration run
      set(h(2),'deletefcn','');
      close(h(2)) % close the old video window
      uda.cNum=uda.cNum+1; % increment camera number
      uda.cp=1; % set current point back to 1
    end
    
    % get the image files
    [calfnames,uda.calpname]=uigetfile( {'*.bmp;*.tif;*.jpg;*.avi;*.cin;*.mp4;*.mov', ...
      'Image and movie files (*.bmp, *.tif, *.jpg, *.avi, *.cin, *.mp4, *.mov)'}, ...
      ['Select the calibration image files. (Ctrl-click to pick',...
      ' several)'],'MultiSelect','on');
    if iscell(calfnames)==0 % convert strings to cells
      uda.calfnames={calfnames};
    else
      for i=2:numel(calfnames)
        uda.calfnames{i-1}=calfnames{i};
        uda.calfnames{end+1}=calfnames{1};
      end
    end
    
    % sort the image file names - Matlab's multi-select does an uncertain
    % job of returning the selection order, so we just sort to give a
    % consistent output every time
    uda.calfnames=sort(uda.calfnames);
    
    % Create a new figure for movie display
    h(2) = figure('Units','characters',... % movie figure
      'Color',[0.831 0.815 0.784]','Doublebuffer','on', ...
      'KeyPressFcn','DLTcal5(2)', ...
      'IntegerHandle','off','MenuBar','none',...
      'Name','DLTcal5 images','NumberTitle','off',...
      'HandleVisibility','callback','Tag','figure1',...
      'UserData',uda,'Visible','on','Units','Pixels', ...
      'deletefcn','DLTcal5(13)','pointer','cross', ...
      'Tag','VideoFigure');
    
    h(40)=axes('Position',[.01 .01 .99 .95],'XTickLabel','', ...
      'YTickLabel','','ButtonDownFcn','DLTcal5(3)', ...
      'Visible','off'); % create movie1 axis
    
    % Initialize the data arrays
    %
    % set the slider size
    if length(uda.calfnames)>1
      set(h(5),'Max',length(uda.calfnames),'Min',1,'Value',1,...
        'SliderStep',[1/(length(uda.calfnames)-1) ...
        1/(length(uda.calfnames)-1)]);
      set(h(5),'Enable','on'); % turn slider on
    else
      set(h(5),'Enable','off') % turn off the slider if only 1 image
    end
    
    uda.numpts=size(uda.specdata,1); % number of pts to digitize per camera
    uda.xypts(1:uda.numpts,2*uda.cNum-1:2*uda.cNum)=NaN; % digitized point
    uda.sp=1; % selected point
    uda.recentlysaved=true; % start the "saved" flag at true
    figure(h(2)) % make the video figure active
    
    % update the number of points settings
    ptstring=char(ones(1,uda.numpts*2+uda.numpts-1));
    for i=1:uda.numpts-1
      ptstring(1,i*4-3:i*4)=sprintf('%3d|',i);
    end
    ptstring(1,uda.numpts*4-3:uda.numpts*4-1)=sprintf('%3d',uda.numpts);
    set(h(32),'String',ptstring);
    
    % read & plot the first image
    im=calimread([uda.calpname,uda.calfnames{1}],true);
    
    % detect color
    if size(im,3)>1
      set(h(12),'Value',true);
    end
    set(h(40),'Visible','on');
    set(h(2),'CurrentAxes',h(40));
    redlakeplot(im);
    uda.movsizes(1,1)=size(im,1);
    uda.movsizes(1,2)=size(im,2);
    
    set(h(40),'XTickLabel','');
    set(h(40),'YTickLabel','');
    set(get(h(40),'Children'),'ButtonDownFcn','DLTcal5(3)');
    set(get(h(40),'Children'),'UserData',uda);
    set(h(40),'Userdata',uda);
    title(h(40),uda.calfnames{1},'Interpreter','none');
    
    % turn on the other controls
    set(h(7),'enable','on'); % save button
    set(h(13),'enable','on'); % video gamma control
    set(h(22),'enable','on'); % load previous data button
    set(h(32),'enable','on'); % point # pulldown menu
    set(h(35),'enable','on'); % advance on click checkbox
    set(h(59),'enable','on'); % search area size
    set(h(12),'enable','on'); % color display
    
    % turn on Centroid finding & set value to "On" if the image analysis
    % toolbox functions that it depends on are available
    if exist('im2bw','file')>1 && exist('regionprops','file')>1 ...
        && exist('bwlabel','file')>1
      set(h(55),'enable','on','Value',0);
      disp('Detected Image Analysis toolbox, centroid localization is')
      disp('available, enable it via the checkbox in the Controls window.')
    else
      disp('The Image Analysis toolbox is not available, centroid ')
      disp('localization has been disabled.')
    end
    
    % turn off the Initialize button
    set(h(6),'enable','off');
    
    % write the userdata back
    uda.handles=h; % copy in new handles
    set(h(1),'Userdata',uda);
    
    % call self to update the string fields
    DLTcal5(4,uda);
    
    %% case 1 - video frame refresh
  case {1} % refresh the video frames
    
    cfh=gcf; % handle to current figure
    colorVal=get(h(12),'Value'); % get color mode info
    fr=round(get(h(5),'Value')); % get the frame # from the slider
    
    figure(h(2)); % activate the video figure
    set(h(2),'CurrentAxes',h(40)); % activate the video axis
    
    xl=xlim; % current x & y axis limits
    yl=ylim;
    
    % read the image
    im=calimread([uda.calpname,uda.calfnames{fr}],colorVal);
    
    % plot the new image data
    hold off
    if colorVal==0 %gray
      redlakeplot(im(:,:,1));
      % set the figure gamma
      c=colormap(gray);
      cnew=c.^get(h(13),'Value');
      colormap(cnew);
    elseif colorVal==1 && size(im,3)==1 % color w/ gray video
      redlakeplot(repmat(im(:,:,1)+(1-get(h(13),'Value'))*128,[1,1,3]));
    else
      redlakeplot(im+(1-get(h(13),'Value'))*128);
    end
    
    % fix other figure parameters
    set(h(40),'XTickLabel','');
    set(h(40),'YTickLabel','');
    set(h(40),'Userdata',uda);
    set(get(h(40),'Children'),'ButtonDownFcn','DLTcal5(3)');
    set(get(h(40),'Children'),'UserData',uda);
    xlim(xl); ylim(yl); % restore axis zoom
    hold on
    title(uda.calfnames{fr},'Interpreter','none');
    
    % plot any existing digitized points (in a loop, ick!)
    idx=find(isnan(uda.xypts(:,uda.cNum*2))==0);
    idx(idx==sp)=[];
    for i=1:length(idx)
      % red dot on the point
      plot(uda.xypts(idx(i),uda.cNum*2-1), ...
        uda.xypts(idx(i),uda.cNum*2),'r.','HitTest','off');
      
      % text label of point # slightly up & left
      text(uda.xypts(idx(i),uda.cNum*2-1)+2, ...
        uda.xypts(idx(i),uda.cNum*2)+2,num2str(idx(i)), ...
        'Color','r','HitTest','off');
    end
    
    % plot the selected point
    plot(uda.xypts(sp,uda.cNum*2-1), ...
      uda.xypts(sp,uda.cNum*2),'ro','MarkerFaceColor','r', ...
      'HitTest','off');
    text(uda.xypts(sp,uda.cNum*2-1)+2,uda.xypts(sp,uda.cNum*2)+2, ...
      num2str(sp),'Color','r','FontSize',14,'HitTest','off');
    
    % write back any modifications to the main figure userdata
    set(h(1),'Userdata',uda);
    
    % restore the pre-existing top figure
    figure(cfh);
    
    % call self to update the text fields
    DLTcal5(4,uda);
    
    % update the small plot
    updateSmallPlot(h,1,uda.xypts(sp,uda.cNum*2-1:uda.cNum*2));
    
    %% case 2 - keypress callback
  case {2} % handle keypresses in the figure window - zoom & unzoom axes
    % disp('case 2: handle keypresses')
    cc=get(h(2),'CurrentCharacter'); % the key pressed
    pl=get(0,'PointerLocation'); % pointer location on the screen
    pos=get(h(2),'Position'); % get the figure position
    
    % calculate pointer location in normalized units
    plocal=[(pl(1)-pos(1,1)+1)/pos(1,3), (pl(2)-pos(1,2)+1)/pos(1,4)];
    
    % if the keypress is empty set it to some value
    if isempty(cc)
      cc='X'; % any value that we don't look for later would do
      axh=0; % set handle to active axis to zero
    else
      if plocal(1)<=0.99 && plocal(2)<=0.99, axh=h(40); vnum=1;
      else
        disp('The mouse pointer is not over an image.')
        return
      end
    end
    
    % process the key press
    if (cc=='=' || cc=='-' || cc=='r') && axh~=0; % check for zoom keys
      
      % zoom in or out as indicated
      if axh~=0
        set(h(2),'CurrentAxes',axh); % set the current axis
        axpos=get(axh,'Position'); % axis position in figure
        xl=xlim; yl=ylim; % x & y limits on axis
        % calculate the normalized position within the axis
        plocal2=[(plocal(1)-axpos(1,1))/axpos(1,3) (plocal(2) ...
          -axpos(1,2))/axpos(1,4)];
        
        % calculate the actual pixel postion of the pointer
        pixpos=round([(xl(2)-xl(1))*plocal2(1)+xl(1) ...
          (yl(2)-yl(1))*plocal2(2)+yl(1)]);
        
        % axis location in pixels (idealized)
        axpix(3)=pos(3)*axpos(3);
        axpix(4)=pos(4)*axpos(4);
        
        % adjust pixels for distortion due to normalized axes
        xRatio=(axpix(3)/axpix(4))/(diff(xl)/diff(yl));
        yRatio=(axpix(4)/axpix(3))/(diff(yl)/diff(xl));
        if xRatio > 1
          xmp=xl(1)+(xl(2)-xl(1))/2;
          xmpd=pixpos(1)-xmp;
          pixpos(1)=pixpos(1)+xmpd*(xRatio-1);
        elseif yRatio > 1
          ymp=yl(1)+(yl(2)-yl(1))/2;
          ympd=pixpos(2)-ymp;
          pixpos(2)=pixpos(2)+ympd*(yRatio-1);
        end
        
        % set the figure xlimit and ylimit
        if cc=='=' % zoom in
          xlim([pixpos(1)-(xl(2)-xl(1))/3 pixpos(1)+(xl(2)-xl(1))/3]);
          ylim([pixpos(2)-(yl(2)-yl(1))/3 pixpos(2)+(yl(2)-yl(1))/3]);
        elseif cc=='-' % zoom out
          xlim([pixpos(1)-(xl(2)-xl(1))/1.5 pixpos(1)+(xl(2)-xl(1))/1.5]);
          ylim([pixpos(2)-(yl(2)-yl(1))/1.5 pixpos(2)+(yl(2)-yl(1))/1.5]);
        else % restore zoom
          xlim([0 uda.movsizes(vnum,2)]);
          ylim([0 uda.movsizes(vnum,1)]);
        end
        
        % update the zoomed plot
        cp=uda.xypts(sp,uda.cNum*2-1:uda.cNum*2);
        updateSmallPlot(h,1,cp);
        
      end
      
    elseif cc=='f' || cc=='b' && axh~=0 % check for valid movement keys
      fr=round(get(h(5),'Value')); % get current slider value
      smax=get(h(5),'Max'); % max slider value
      smin=get(h(5),'Min'); % min slider value
      if smin==0, return, end % avoid edge case
      axn=find(h==axh)-39; % axis number
      if isnan(axn),
        disp('Error: The mouse pointer is not in an axis.')
        return
      end
      
      if cc=='f' && fr+1 <= smax
        set(h(5),'Value',fr+1); % current frame + 1
      elseif cc=='b' && fr-1 >= smin
        set(h(5),'Value',fr-1); % current frame - 1
      end
      
      % full redraw of the screen
      DLTcal5(1,uda);
      
      % update the control / zoom window
      % 1st retrieve the cp from the data file in case the autotracker
      % changed it
      cp=uda.xypts(sp,uda.cNum*2-1:uda.cNum*2);
      updateSmallPlot(h,axn,cp);
      
    elseif cc=='.' || cc==',' % change point
      ptnum=numel(get(h(32),'String'))/2; % # of points defined
      ptval=get(h(32),'Value'); % selected point
      
      if cc==',' && ptval>1 % decrease point value if possible
        set(h(32),'Value',ptval-1);
        ptval=ptval-1;
      elseif cc=='.' && ptval<ptnum % increase point value if possible
        set(h(32),'Value',ptval+1);
        ptval=ptval+1;
      end
      
      pt=uda.xypts(ptval,uda.cNum*2-1:uda.cNum*2);
      
      % update the magnified point view
      updateSmallPlot(h,vnum,pt);
      
      % do a quick screen redraw
      quickRedraw(uda,h,ptval);
      
    elseif cc=='i' || cc=='j' || cc=='k' || cc=='m' || cc=='4' || ...
        cc=='8' || cc=='6' || cc=='2' % nudge point
      % check and see if there is a point to nudge, get it's value if
      % possible
      if isnan(uda.xypts(sp,uda.cNum*2-1))
        return
      else
        pt=uda.xypts(sp,uda.cNum*2-1:uda.cNum*2);
      end
      
      % modify pt based on the 'nudge' value
      nudge=0.5; % 1/2 pixel nudge
      if cc=='i' || cc=='8'
        pt(1,2)=pt(1,2)+nudge; % up
      elseif cc=='j' || cc=='4'
        pt(1,1)=pt(1,1)-nudge; % left
      elseif cc=='k' || cc=='6'
        pt(1,1)=pt(1,1)+nudge; % right
      else
        pt(1,2)=pt(1,2)-nudge; % down
      end
      
      % set the modified point
      uda.xypts(sp,uda.cNum*2-1:uda.cNum*2)=pt;
      
      % update the magnified point view
      updateSmallPlot(h,vnum,pt);
      
      % do a quick screen redraw
      quickRedraw(uda,h,sp);
      
      
    elseif cc==' ' % space bar (digitize a point)
      set(h(2),'CurrentAxes',axh); % set the current axis
      axpos=get(axh,'Position'); % axis position in figure
      xl=xlim; yl=ylim; % x & y limits on axis
      % calculate the normalized position within the axis
      plocal2=[(plocal(1)-axpos(1,1))/axpos(1,3) (plocal(2) ...
        -axpos(1,2))/axpos(1,4)];
      
      % calculate the actual pixel postion of the pointer
      pixpos=([(xl(2)-xl(1)+0)*plocal2(1)+xl(1) ...
        (yl(2)-yl(1)+0)*plocal2(2)+yl(1)]);
      
      % axis location in pixels (idealized)
      axpix(3)=pos(3)*axpos(3);
      axpix(4)=pos(4)*axpos(4);
      
      % adjust pixels for distortion due to normalized axes
      xRatio=(axpix(3)/axpix(4))/(diff(xl)/diff(yl));
      yRatio=(axpix(4)/axpix(3))/(diff(yl)/diff(xl));
      if xRatio > 1
        xmp=xl(1)+(xl(2)-xl(1))/2;
        xmpd=pixpos(1)-xmp;
        pixpos(1)=pixpos(1)+xmpd*(xRatio-1);
      elseif yRatio > 1
        ymp=yl(1)+(yl(2)-yl(1))/2;
        ympd=pixpos(2)-ymp;
        pixpos(2)=pixpos(2)+ympd*(yRatio-1);
      end
      
      % setup oData for the digitization routine
      oData.seltype='standard';
      oData.cp=pixpos;
      DLTcal5(3,uda,oData); % digitize a point
      return
      
    elseif cc=='z' % delete the current point
      oData.seltype='alt';
      oData.cp=[NaN,NaN];
      DLTcal5(3,uda,oData); % digitize a point
      return
    end
    
    
    % write back any modifications to the main figure userdata
    set(h(1),'Userdata',uda);
    
    %% case 3 - axis mouse click callback
  case {3} % handle button clicks in axes
    
    if strcmp(get(gcbo,'Tag'),'VideoFigure')
      % entered the function via space bar, not mouse click
      seltype=oData.seltype;
      cp=oData.cp;
    else
      % entered via mouse click
      set(h(2),'CurrentAxes',get(gcbo,'Parent')); % set the current axis
      cp=get(get(gcbo,'Parent'),'CurrentPoint'); % get the xy coordinates
      seltype=cellstr(get(h(2),'SelectionType')); % selection type
    end
    
    % if detect right button click, erase the point
    if strcmp(seltype,'normal')==false
      cp(:,:)=NaN;
    end
    
    % Search for a marker centroid (if desired & possible)
    findCent=get(h(55),'Value'); % check the UI for permission
    if isnan(cp(1))==0 && findCent==1
      [cp]=click2centroid(h,cp);
    end
    
    % set the points for the current frame
    uda.xypts(sp,uda.cNum*2-1)=cp(1,1); % set x point
    uda.xypts(sp,uda.cNum*2)=cp(1,2); % set y point
    
    % new data available, change the recently saved parameter to false
    uda.recentlysaved=0;
    
    % zoomed window update
    updateSmallPlot(h,1,cp);
    
    % auto-advance on click
    if(get(h(35),'Value')==1)
      ptnum=numel(get(h(32),'String'))/2; % get # of points in list
      ptval=get(h(32),'Value'); % selected point
      if ptval<uda.numpts % increase point value if possible
        set(h(32),'Value',ptval+1);
        ptval=ptval+1;
      end
    else
      ptval=sp;
    end
    
    % enable computation buttons if appropriate
    goodpts=find(isnan(uda.xypts(:,uda.cNum*2))==0);
    if length(goodpts)>=6
      set(h(33),'Enable','on')
      set(h(36),'Enable','on')
    else
      set(h(33),'Enable','off')
      set(h(36),'Enable','off')
    end
    
    set(h(1),'Userdata',uda); % pass back complete user data
    
    % quick screen refresh to show the new point & possibly DLT info
    quickRedraw(uda,h,ptval);
    
    %% case 4 - update GUI text fields
  case {4}	% update the text fields
    % set the frame # string
    fr=round(get(h(5),'Value')); % get current & max frame from slider
    frmax=get(h(5),'Max');
    set(h(21),'String',['Frame number: ' num2str(fr) '/' num2str(frmax)]);
    
    %% case 5 - save data
  case {5} % save data
    
    % get a place to save it
    pname=uigetdir(pwd,'Pick a directory to contain the output files');
    pause(0.1); % make sure that the uigetdir ran (MATLAB bug workaround)
    
    % get a prefix
    pfix=inputdlg({'Enter a prefix for the data files'},'Data prefix',...
      1,{'cal01_'});
    if numel(pfix)==0
      return
    else
      pfix=pfix{1};
    end
    
    % test for existing files
    if exist([pname,filesep,pfix,'xypts.csv'],'file')~=0
      overwrite=questdlg('Overwrite existing data?', ...
        'Overwrite?','Yes','No','No');
    else
      overwrite='Yes';
    end
    
    % create headers (xypts)
    xyh=cell(uda.cNum*2,1);
    for i=1:uda.cNum
      xyh{i*2-1}=sprintf('cam%s_X',num2str(i));
      xyh{i*2}=sprintf('cam%s_Y',num2str(i));
    end
    
    if strcmp(overwrite,'Yes')==1
      % xypts
      f1=fopen([pname,filesep,pfix,'xypts.csv'],'w');
      % header
      for i=1:numel(xyh)-1
        fprintf(f1,'%s,',xyh{i});
      end
      fprintf(f1,'%s\n',xyh{end});
      % data
      for i=1:size(uda.xypts,1);
        tempData=squeeze(uda.xypts(i,:,:));
        for j=1:numel(tempData)-1
          fprintf(f1,'%.6f,',tempData(j));
        end
        fprintf(f1,'%.6f\n',tempData(end));
      end
      fclose(f1);
      
      % dltcoefs
      if isfield(uda,'coefs')
        dlmwrite([pname,filesep,pfix,'DLTcoefs.csv'],uda.coefs,',');
      end
      
      uda.recentlysaved=1;
      set(h(1),'Userdata',uda); % pass back complete user data
      
      msgbox('Data saved.');
    end
    
    %% case 6 - load saved data
  case {6} % load previously saved points
    
    [fname1,pname1]=uigetfile('*xypts*.csv',...
      'Select the [prefix]xypts.csv file');
    pause(0.1); % make sure that the uigetfile ran (MATLAB bug workaround)
    pfix=[pname1,fname1];
    
    % check for cancel button
    if numel(fname1)==1 && fname1==0
      disp('File load canceled.')
      return
    end
    
    % load the exported xy points
    tempData=dlmread(pfix,',',1,0);
    
    % check for similarity with video data
    if size(tempData,1)~=size(uda.xypts,1)
      msgbox(['WARNING - the digitized point file size does not match',...
        'the frame, aborting.'],'Warning','warn','modal')
      return
    else
      if size(tempData,2)/2>=uda.cNum;
        tempData=tempData(:,uda.cNum*2-1:uda.cNum*2);
        
      else
        tempData=tempData(:,1:2);
      end
      uda.xypts(:,uda.cNum*2-1:uda.cNum*2)=tempData;
      
      % enable computation buttons if appropriate
      goodpts=find(isnan(tempData(:,1))==0);
      if length(goodpts)>=9
        set(h(33),'Enable','on')
        set(h(36),'Enable','on')
      else
        set(h(33),'Enable','off')
        set(h(36),'Enable','off')
      end
      
    end
    
    % call self to update the video fields
    DLTcal5(1,uda);
    
    %% case 7 - compute DLT coefficients
  case {7} % compute DLT coefficients
    if uda.cNum==1
      uda.coefs=[];
    end
    
    set(gcf,'Pointer','watch')
    data=uda.xypts(:,uda.cNum*2-1:uda.cNum*2);
    goodpts=find(isnan(data(:,1))==0);
    
    if length(goodpts)<6
      msgbox(['You should use at least 6 digitized points for 11',...
        'parameter DLT'])
      return
    end
    
    if get(h(25),'Value')==1 % 11 parameter DLT
      [uda.coefs(:,uda.cNum),uda.avgres(uda.cNum)]= ...
        dlt_computeCoefficients(uda.specdata,data);
    else % modified DLT
      [uda.coefs(:,uda.cNum),uda.avgres(uda.cNum)]= ...
        mdlt2(uda.specdata,data);
    end
    set(gcf,'Pointer','arrow')
    
    % update the user interface
    set(h(27),'String',sprintf('Calibration \nresidual: %0.3f',...
      uda.avgres(uda.cNum)));
    
    % write back any modifications to the main figure userdata
    set(h(1),'Userdata',uda);
    
    set(h(6),'Enable','on'); % enable the "calibrate another camera" option
    set(h(6),'String','Add a camera')
    
    %% case 8 - DLT error analysis
  case {8} % DLT error analysis
    msg{1}='This function computes the DLT coefficients and residuals';
    msg{2}='with one of the calibration points removed.  Calibration';
    msg{3}='point # is shown on the X axis and DLT residual without that';
    msg{4}='point is on the Y axis.  A large drop in the residual';
    msg{5}='indicates that the calibration point in question may be';
    msg{6}='badly digitized or incorrectly specified in the calibration';
    msg{7}='object file.  This function does not modify any of the';
    msg{8}='existing calibration points, it only shows the outcome of';
    msg{9}='potential modifications.';
    
    uiwait(msgbox(msg,'Information','modal'));
    
    % start processing
    wh=waitbar(0,'Processing error values');
    rescheck(1:size(uda.specdata,1),1:2)=NaN;
    for i=1:size(uda.specdata,1)
      waitbar(i/size(uda.xypts,1)); % update waitbar size
      ptstemp=uda.xypts(:,uda.cNum*2-1:uda.cNum*2);
      rescheck(i,1)=i; % build X axis column
      if isnan(ptstemp(i,1))==1 % no value anyway
        rescheck(i,2)=NaN; % no need to process
      else
        ptstemp(i,1:2)=NaN; % set to NaN and recalculate
        if get(h(25),'Value')==1 % standard DLT
          [coefs,rescheck(i,2)]=dlt_computeCoefficients(uda.specdata,...
            ptstemp);
        else % modified DLT
          [coefs,rescheck(i,2)]=mdlt2(uda.specdata,ptstemp);
        end
      end
    end
    close(wh)
    figure
    plot(rescheck(:,1),rescheck(:,2),'rd','MarkerFaceColor','r')
    ylabel('DLT residual with 1 calibration point removed')
    xlabel('Calibration point')
    
    
    %% case 9 - Color video checkbox
  case {9} % Click / unclick color video checkbox
    if get(h(12),'Value')==0
      set(h(55),'enable','on')
      set(h(57),'enable','on')
    else
      set(h(55),'value',false)
      set(h(55),'enable','off')
      set(h(57),'enable','off')
    end
    DLTcal5(1,uda); % redraw screen
    
  case {10} % unused
    
    %% case 11 - Quit button callback
  case {11} % Quit button
    reallyquit=questdlg('Are you sure you want to quit?','Quit?',...
      'yes','no','no');
    pause(0.1); % make sure that the questdlg ran (MATLAB bug workaround)
    if strcmp(reallyquit,'yes')==1
      try
        close(h(2));
      catch
      end
      try
        close(h(1));
      catch
      end
    end
    
  case {12} % unused
    
    %% case 13 - Window close via non-Matlab event
  case {13} % Window close via non-Matlab method
    % if initialization completed and there is data to save
    if h(2)~=0 && uda.recentlysaved==0;
      savefirst=questdlg('Would you like to save your data now?', ...
        'Save?','yes','no','yes');
      pause(0.1); % make sure that the questdlg ran (MATLAB bug workaround)
      if strcmp(savefirst,'yes')
        DLTcal5(5,uda); % call self to save data
      else
        % consider the data saved anyway to avoid asking again
        uda.recentlysaved=1;
        set(h(1),'Userdata',uda);
      end
    end
    try
      delete(h(2));
    catch
    end
    try
      delete(h(1));
    catch
    end
    
  case {14} % Click / unclick Centroid finding checkbox
    % enable or disable color menu
    if get(h(55),'Value')==1
      set(h(57),'enable','on')
    else
      set(h(57),'enable','off')
    end
    
end % end of switch / case statement

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Begin subfunctions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% redlakeplot
function [h] = redlakeplot(varargin)

% function [h] = redlakeplot(rltiff,xy)
%
% Description:	Quick function to plot images from Redlake tiffs
% 	This function was formerly named birdplot
%
% Version history:
% 1.0 - Ty Hedrick 3/5/2002 - initial version

if nargin ~= 1 && nargin ~= 2
  disp('Incorrect number of inputs.')
  return
end

h=image(varargin{1},'CDataMapping','scaled');
%set(h,'EraseMode','normal');
colormap(gray)
axis xy
axis equal
hold on
ha=get(h,'Parent');
set(ha,'XTick',[],'YTick',[],'XColor',[0.8314 0.8157 0.7843],'YColor', ...
  [0.8314 0.8157 0.7843],'Color',[0.8314 0.8157 0.7843]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% updateSmallPlot
function updateSmallPlot(h,vnum,cp,roi)

% update the magnified plot in the "Controls" window.  If the cp input is a
% NaN the function displays a checkerboard, if roi is not given the
% function grabs one from the appropriate plot using the other included
% information.

if isnan(cp(1))
  roi=chex(1,21,21).*255;
end

x=round(cp(1,1)); % get an integer X point
y=round(cp(1,2)); % get an integer Y point
psize=str2double(get(h(59),'String'));

if exist('roi','var')~=1 % don't have roi yet, go get it
  kids=get(h(vnum+39),'Children'); % children of current axis
  imdat=get(kids(end),'CData'); % read current image
  try
    roi=imdat(y-psize:y+psize,x-psize:x+psize,:);
  catch
    return
  end
end

if isnan(roi(1))
  return
end

% update the roi viewer in the controls frame
delete(get(h(51),'Children'))

% scale roi to gamma
gamma=get(h(13),'Value');
if size(roi,3)==1 % grayscale
  roi2=(double(roi).^gamma).*(255/255^gamma);
  image('Parent',h(51),'Cdata',roi2,'CDataMapping','scaled');
else % color
  roi2=roi+(1-gamma)*128;
  image('Parent',h(51),'Cdata',roi2);
end

edgelen=size(roi,1);
xlim(h(51),[1 edgelen]);
ylim(h(51),[1 edgelen]);

% put a crosshair on the target image
hold(h(51),'on')
plot(h(51),[1;2*psize+1],[psize+1+cp(1,2)-y,psize+1+cp(1,2)-y],'r-');
plot(h(51),[psize+1+cp(1,1)-x,psize+1+cp(1,1)-x],[1;2*psize+1],'r-');
hold(h(51),'off')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% click2centroid
function [cp]=click2centroid(h,cp)

% Use the centroid locating tools in the MATLAB image analysis toolbox to
% pull the mouse click to the centroid of a putative marker

psize=round(str2double(get(h(59),'String'))); % search area size

% set more variables within the loop
kids=get(h(40),'Children'); % children of current axis
imdat=get(kids(end),'CData'); % read current image
x=round(cp(1,1)); % get an integer X point
y=round(cp(1,2)); % get an integer Y point

% copy imdat, apply gamma to imdat & rescale
imdat=double(imdat(:,:,1)); % convert from uint8 to double

% determine the base area around the mouse click to
% grab for centroid finding
try
  roi=imdat(y-psize:y+psize,x-psize:x+psize);
catch
  return
end

% apply gamma and rescale
roi=roi.^get(h(13),'Value');
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
roiB=im2bw(roibase,level+(1-level)*0.5);

% create alternative, inverted binary image
roiBi=im2bw(roibase,level/1.5);
roiBi=logical(roiBi*-1+1);

% identify objects
[labeled_roiB]=bwlabel(roiB,4);
[labeled_roiBi]=bwlabel(roiBi,4);

% get object info
roiB_data=regionprops(labeled_roiB,'basic');
roiBi_data=regionprops(labeled_roiBi,'basic');

% for each roi*_data, find the largest object
roiB_sz=zeros(length(roiB_data),1);
for i=1:length(roiB_data)
  roiB_sz(i)=roiB_data(i).Area;
end
roiB_dx=find(roiB_sz==max(roiB_sz));

roiBi_sz=zeros(length(roiBi_data),1);
for i=1:length(roiBi_data)
  roiBi_sz(i)=roiBi_data(i).Area;
end
roiBi_dx=find(roiBi_sz==max(roiBi_sz));

% check "white" or "black" option from menu
% 1 == black, 2 == white
whiteBlack=get(h(57),'Value');
if whiteBlack==1
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
cp(1,1)=x+cX-psize-1;
cp(1,2)=y+cY-psize-1;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% quickRedraw
function quickRedraw(uda,h,sp)

cfh=gcf; % handle to current figure
uda.nvid=1; % only one video frame in the digitizing program

% loop through each axes and update it
for i=1:uda.nvid
  % make the video figure active
  figure(h(2));
  
  % make the axis of interest active
  set(h(2),'CurrentAxes',h(i+39));
  
  % get the kids & delete everything but the image
  kids=get(h(i+39),'Children');
  if length(kids)>1
    delete(kids(1:end-1)); % assume the bottom of the stack is the image
  end
  
  % plot any existing digitized points (in a loop, ick!)
  idx=find(isnan(uda.xypts(:,uda.cNum*2))==0);
  idx(idx==sp)=[];
  
  for j=1:numel(idx)
    % red dot on the point
    plot(uda.xypts(idx(j),uda.cNum*2-1), ...
      uda.xypts(idx(j),uda.cNum*2),'r.','HitTest','off');
    
    % text label of point # slightly up & left
    text(uda.xypts(idx(j),uda.cNum*2-1)+2, ...
      uda.xypts(idx(j),uda.cNum*2)+2,num2str(idx(j)), ...
      'Color','r','HitTest','off');
  end
  
  % plot the selected point
  plot(uda.xypts(sp,uda.cNum*2-1), ...
    uda.xypts(sp,uda.cNum*2),'ro','MarkerFaceColor','r', ...
    'HitTest','off');
  text(uda.xypts(sp,uda.cNum*2-1)+2,uda.xypts(sp,uda.cNum*2)+2, ...
    num2str(sp),'Color','r','FontSize',14,'HitTest','off');
  
end % end for loop through the video axes

% restore the pre-existing top figure
figure(cfh);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% calimread
function [image]=calimread(fpathname,incolor)

% function [image]=calimread(fpathname,incolor)
%
% Reads and returns a calibration image

if ischar(fpathname)
  % check the file extension
  if strcmpi('avi',fpathname(end-2:end)) || ...
      strcmpi('mp4',fpathname(end-2:end)) || ...
      strcmpi('mov',fpathname(end-2:end)) || ...
      strcmpi('cin',fpathname(end-2:end)) || ...
      strcmpi('cine',fpathname(end-3:end))
    mov=mediaRead(fpathname,1,incolor,false);
    image=mov.cdata;
  else
    image=imread(fpathname);
    if incolor==false
      image=image(:,:,1);
    end
    for i=1:size(image,3)
      image(:,:,i)=flipud(image(:,:,i));
    end
  end
else
  mov=mediaRead(fpathname,1,incolor,false);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% dlt_computeCoefficients
function  [c,rmse] = dlt_computeCoefficients(frame,camPts)

% function  [c,rmse] = dlt_computeCoefficients(frame,camPts)
%
% A basic implementation of 11 parameter DLT
%
% Inputs:
%  frame - an array of x,y,z calibration point coordinates
%  camPts - an array of u,v pixel coordinates from the camera
%
% Outputs:
%  c - the 11 DLT coefficients
%  rmse - root mean square error for the reconstruction; units =
%
% Notes - frame and camPts must have the same number of rows.  A minimum of
% 6 rows are required to compute the coefficients.  The frame points must
% not all lie within a single plane
%
% Ty Hedrick

% check for any NaN rows (missing data) in the frame or camPts
ndx=find(sum(isnan([frame,camPts]),2)>0);

% remove any missing data rows
frame(ndx,:)=[];
camPts(ndx,:)=[];

% re-arrange the frame matrix to facilitate the linear least squares
% solution
M=zeros(size(frame,1)*2,11);
for i=1:size(frame,1)
  M(2*i-1,1:3)=frame(i,1:3);
  M(2*i,5:7)=frame(i,1:3);
  M(2*i-1,4)=1;
  M(2*i,8)=1;
  M(2*i-1,9:11)=frame(i,1:3).*-camPts(i,1);
  M(2*i,9:11)=frame(i,1:3).*-camPts(i,2);
end

% re-arrange the camPts array for the linear solution
camPtsF=reshape(flipud(rot90(camPts)),numel(camPts),1);

% get the linear solution to the 11 parameters
c=linsolve(M,camPtsF);

% compute the position of the frame in u,v coordinates given the linear
% solution from the previous line
Muv=dlt_inverse(c,frame);

% compute the root mean square error between the ideal frame u,v and the
% recorded frame u,v
rmse=(sum(sum((Muv-camPts).^2))./numel(camPts))^0.5;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% chex
function [I] = chex(n,p,q)

% draw a checkerboard

bs = zeros(n);
ws = ones(n);
twobytwo = [bs ws; ws bs];
I = repmat(twobytwo,p,q);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% mdlt2
function [coefs,avgres] = mdlt2(frame,xypts)

% function [coefs,avgres] = mdlt2(frame,xypts)
%
% An alternative Modified Direct Linear Transformation implementation - see
% also mdlt1 from Tomislav Pribanic.  This one takes a bit more cpu time
% but doesn't require Matlab's symbolic solver or very lengthy equations
% keyed in by hand.
%
% Modified Direct Linear Transformation (Hatze, 1988) recognizes an
% internal non-linear dependency in the DLT algorithm, potentially
% resulting in a more accurate reconstruction.  In practice, this is rarely
% the case.  Contrary to the results in Hatze (1988) I've never found a
% test case, either in extrapolation outside the calibration volume or
% reconstruction within it, where mDLT consistently outperformed standard
% DLT.
%
% However, all modified DLT solutions internally express rotations about
% orthogonal axes (this is not true of DLT, where the axes are usually
% non-orthogonal) - this property is very useful when recreating scenes
% in 3D visualization or graphics packages that cannot perform rotations
% about non-orthogonal axes.
%
% Ty Hedrick, Feb. 16, 2007
%
% Hatze, H. "High-precision three-dimensional photogrammetric calibration
% and object space reconstruction using a modified DLT-approach." J.
% Biomechanics, 1988, 21, 533-538

% remove any NaN points
idx=find(isnan(xypts(:,1))==true);
xypts(idx,:)=[];
frame(idx,:)=[];

% start with standard DLT coefficients
[Cinit] = dlt_computeCoefficients(frame,xypts);

% options for the Matlab optimization implementation.
opts=optimset;
opts.MaxFunEvals=1e24;
opts.MaxIter=1e24;

% search for a set of optimized DLT coefficients that adhere to the
% non-linear constraint
[Csearch] = fminsearch(@mdltScore,Cinit(2:11),opts,frame,xypts);

% get the final values
[avgres,coefs] = mdltScore(Csearch,frame,xypts);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [s,C] = mdltScore(Cinit,frame,xypts)

% function [s,C] = mdltScore(Cinit,frame,xypts)
%
% Scoring function for the mdlt2 function.  The idea is to compute the 1st
% DLT parameter from the other 10 and the non-linear constraint, then
% reconstruct the ideal XY camera points from the 11 DLT parameters and the
% calibration frame, then measure the error as the difference between the
% ideal XY points and the digitized xypoints

% The core non-linear constraint for modified direct linear transformation
%
%(C1*C5+C2*C6+C3*C7)*(C9^2+C10^2+C11^2)=(C1*C9+C2*C10+C3*C11) ...
% *(C5*C9+C6*C10+C7*C11)

% start setting up the full, 11 parameter coefficients matrix
C(2:11,1)=Cinit;

% create C(1) from the non-linear constraint
C(1)=(-C(2)*C(6)*C(9)^2-C(2)*C(6)*C(11)^2 - C(3)*C(7)*C(9)^2 - ...
  C(3)*C(7)*C(10)^2 + C(2)*C(10)*C(5)*C(9) + C(2)*C(10)*C(7)*C(11) + ...
  C(3)*C(11)*C(5)*C(9) + C(3)*C(11)*C(6)*C(10)) / (C(5)*C(10)^2 + ...
  C(5)*C(11)^2 - C(9)*C(6)*C(10) - C(9)*C(7)*C(11));

% break out frame points
X=frame(:,1);
Y=frame(:,2);
Z=frame(:,3);

% Compute the ideal xy coordinates of the frame from the calibration
x=(X.*C(1)+Y.*C(2)+Z.*C(3)+C(4))./(X.*C(9)+Y.*C(10)+Z.*C(11)+1);
y=(X.*C(5)+Y.*C(6)+Z.*C(7)+C(8))./(X.*C(9)+Y.*C(10)+Z.*C(11)+1);

% residual compatible with dlt_computeCoefficients; also used as the score
% in the nonlinear minimizer
s=(sum(sum(([x,y]-xypts).^2))./numel(xypts))^0.5;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% mediaRead

function [mov,fname]=mediaRead(fname,frame,incolor,mirror)

% function [mov,fname]=mediaRead(fname,frame,incolor,mirror);
%
% Wrapper function which uses VideoReader, mmreader, cineRead or mrfREad
% depending on what type of file is detected.  Also performs the flipud() 
% on the result of aviread and puts the cdata result from cineRead into a 
% mov.* structure.

if ischar(fname)
  if strcmpi(fname(end-3:end),'.avi') || strcmpi(fname(end-3:end),'.mp4') || strcmpi(fname(end-3:end),'.mov')
    if exist('VideoReader')==2
      fname=VideoReader(fname); % turn the filename into an videoreader object
      if ismethod(fname,'readFrame') % use readFrame if available
        mov.cdata=fname.readFrame;
      else
        mov.cdata=read(fname,frame);
      end
    else
      fname=mmreader(fname); % turn the filename into an mmreader object
      mov.cdata=read(fname,frame);
    end
    
    if incolor==false
      mov.cdata=flipud(mov.cdata(:,:,1));
    else
      for i=1:size(mov.cdata,3)
        mov.cdata(:,:,i)=flipud(mov.cdata(:,:,i));
      end
    end
  elseif strcmpi(fname(end-3:end),'.cin') % vision research cine
    mov.cdata=cineRead(fname,frame);
  elseif strcmpi(fname(end-4:end),'.cine') % vision research cine
    mov.cdata=cineRead(fname,frame);
  elseif strcmpi(fname(end-3:end),'.mrf') % IDT/Redlake multipage raw
    mov.cdata=mrfRead(fname,frame);
  else
    mov=[];
    disp('mediaRead: bad file extension')
    return
  end
else % fname is not a char so it is an mmreader or videoreader obj
  % Using read() with VideoReader objects can be exceedingly slow so we
  % avoid it
  if isa(fname,'VideoReader')==true
    if ismethod(fname,'readFrame') % use readFrame if available
      % check current time & don't seek to a new time if we don't need to
      ctime=fname.CurrentTime;
      ftime=(frame-1)*(1/fname.FrameRate); % start time of desired frame
      if abs(ctime-ftime)<1/fname.FrameRate
        % no need to seek
      else
        fname.CurrentTime=ftime;
      end
      mov.cdata=fname.readFrame;
    else
      mov.cdata=read(fname,frame);
    end
  else
    % fallback to read() for mmreader
    mov.cdata=read(fname,frame);
  end
  if incolor==false
    mov.cdata=flipud(mov.cdata(:,:,1));
  else
    for i=1:size(mov.cdata,3)
      mov.cdata(:,:,i)=flipud(mov.cdata(:,:,i));
    end
  end
end

if mirror==true
  for i=1:size(mov.cdata,3)
    mov.cdata(:,:,i)=fliplr(mov.cdata(:,:,i));
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% cineRead
function [cdata] = cineRead(fileName,frameNum)

% function [cdata] = cineRead(fileName,frameNum)
%
% Reads the frame specified by frameNum from the Phantom camera cine file
% specified by fileName.  It will not read compressed cines.  Furthermore,
% the bitmap in cdata may need to be flipped, transposed or rotated to
% display properly in your imaging application.
%
% frameNum is 1-based and starts from the first frame available in the
% file.  It does not use the internal frame numbering of the cine itself.
%
% This function uses the cineReadMex implementation on 32bit Windows; on
% all other platforms it uses a pure Matlab implementation that has been
% tested on (and works on) grayscale CIN files from a Phantom v5.1 and
% Phantom v7.0 camera.  The cineReadMex function has only been tested with
% 1024x1024 cines from a Phantom v5.1 and likely will not work with other
% data files.
%
% Ty Hedrick, April 27, 2007
%  updated November 06, 2007
%  updated March 1, 2009

% check inputs
if strcmpi(fileName(end-3:end),'.cin') || ...
    strcmpi(fileName(end-4:end),'.cine') && isnan(frameNum)==false
  
  % get file info from the cineInfo function
  info=cineInfo(fileName);
  
  % offset is the location of the start of the target frame in the file -
  % the pad + 8bits for each frame + the size of all the prior frames
  offset=info.headerPad+8*info.NumFrames+8*frameNum+(frameNum-1)* ...
    (info.Height*info.Width*info.bitDepth/8);
  
  % get a handle to the file from the filename
  f1=fopen(fileName);
  
  % seek ahead from the start of the file to the offset (the beginning of
  % the target frame)
  fseek(f1,offset,-1);
  
  % read a certain amount of data in - the amount determined by the size
  % of the frames and the camera bit depth, then cast the data to either
  % 8bit or 16bit unsigned integer
  if info.bitDepth==8 % 8bit gray
    idata=fread(f1,info.Height*info.Width,'*uint8');
    nDim=1;
  elseif info.bitDepth==16 % 16bit gray
    idata=fread(f1,info.Height*info.Width,'*uint16');
    nDim=1;
  elseif info.bitDepth==24 % 24bit color
    idata=double(fread(f1,info.Height*info.Width*3,'*uint8'))/255;
    nDim=3;
  else
    disp('error: unknown bitdepth')
    return
  end
  
  % destroy the handle to the file
  fclose(f1);
  
  % the data come in from fread() as a 1 dimensional array; here we
  % reshape them to a 2-dimensional array of the appropriate size
  cdata=zeros(info.Height,info.Width,nDim);
  for i=1:nDim
    tdata=reshape(idata(i:nDim:end),info.Width,info.Height);
    cdata(:,:,i)=fliplr(rot90(tdata,-1));
  end
else
  % complain if the use gave what appears to be an incorrect filename
  fprintf( ...
    '%s does not appear to be a cine file or frameNum is not available.'...
    ,fileName)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% cineInfo
function [info,header32] = cineInfo(fileName)

% function [info] = cineInfo(fileName)
%
% Reads header information from a Phantom Camera cine file, analagous to
% Mathworks aviinfo().  The values returned are:
%
% info.Width - image width
% info.Height - image height
% info.startFrame - first frame # saved from the camera cine sequence
% info.endFrame - last frame # saved from the camera cine sequence
% info.bitDepth - image bit depth
% info.frameRate - frame rate the cine was recorded at
% info.exposure - frame exposure time in microseconds
% info.NumFrames - total number of frames
% info.cameraType - model of camera used to record the cine
% info.softwareVersion - Phantom control software version used in recording
% info.headerPad - length of the variable portion of the pre-data header
%
% Ty Hedrick, April 27, 2007
%  updated November 6, 2007
%  updated March 1, 2009

% check for cin suffix.  This program will produce erratic results if run
% on an AVI!
if strcmpi(fileName(end-3:end),'.cin') || ...
    strcmpi(fileName(end-4:end),'.cine')
  % read the first chunk of header
  %
  % get a file handle from the filename
  f1=fopen(fileName);
  
  % read the 1st 410 32bit ints from the file
  header32=double(fread(f1,410,'*int32'));
  
  % release the file handle
  fclose(f1);
  
  % set output values from certain magic locations in the header
  info.Width=header32(13);
  info.Height=header32(14);
  info.startFrame=header32(5);
  info.NumFrames=header32(6);
  info.endFrame=info.startFrame+info.NumFrames-1;
  info.bitDepth=header32(17)/(info.Width*info.Height/8);
  info.frameRate=header32(214);
  info.exposure=header32(215);
  info.cameraType=header32(220);
  info.softwareVersion=header32(222);
  info.headerPad=header32(9); % variable length pre-data pad
  info.compression=sprintf('%s-bit raw',num2str(info.bitDepth));
else
  fprintf('%s does not appear to be a cine file.',fileName)
  info=[];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% dlt_inverse

function [uv] = dlt_inverse(c,xyz)

% function [uv] = dlt_inverse(c,xyz)
%
% This function reconstructs the pixel coordinates of a 3D coordinate as
% seen by the camera specificed by DLT coefficients c
%
% Inputs:
%  c - 11 DLT coefficients for the camera, [11,1] array
%  xyz - [x,y,z] coordinates over f frames,[f,3] array
%
% Outputs:
%  uv - pixel coordinates in each frame, [f,2] array
%
% Ty Hedrick

% write the matrix solution out longhand for Matlab vector operation over
% all points at once
uv(:,1)=(xyz(:,1).*c(1)+xyz(:,2).*c(2)+xyz(:,3).*c(3)+c(4))./ ...
  (xyz(:,1).*c(9)+xyz(:,2).*c(10)+xyz(:,3).*c(11)+1);
uv(:,2)=(xyz(:,1).*c(5)+xyz(:,2).*c(6)+xyz(:,3).*c(7)+c(8))./ ...
  (xyz(:,1).*c(9)+xyz(:,2).*c(10)+xyz(:,3).*c(11)+1);

