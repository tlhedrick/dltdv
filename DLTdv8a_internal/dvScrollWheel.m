function [] = dvScrollWheel(varargin)

fh=varargin{1}; % figure handle
swe=varargin{2}; % scroll event
app=varargin{3}; % DLTdv8a app
h=app.handles;
me = getappdata(fh,'videoNumber')+200;

% pl=get(0,'PointerLocation'); % pointer location on the screen
% pos=get(fh,'Position'); % get the figure position
% %fr=app.FrameNumberSlider.Value; % get the current frame 

% calculate pointer location in normalized units
% plocal=[(pl(1)-pos(1,1)+1)/pos(1,3), (pl(2)-pos(1,2)+1)/pos(1,4)];

%axh=me+100; % axis handle for each figure is offset by +100

% 2026-01-18: new approach to getting pointer position
vnum=getappdata(fh,'videoNumber'); % video number
axh=vnum+300; % address of axis handle in the handles array
pixpos=get(app.handles{axh},'CurrentPoint'); % pixel position of pointer
pixpos=pixpos(1,1:2);

% zoom in or out as indicated
if axh~=0

  axis(h{axh}); % make sure we have the current axis as active
  xl=xlim; yl=ylim; % x & y limits on axis

  % calculate the normalized position of the pointer in the axis
  plocal2=[(pixpos(1)-xl(1))/(xl(2)-xl(1)), (pixpos(2)-yl(1))/(yl(2)-yl(1))];
  
  % set the figure xlimit and ylimit
  if swe.VerticalScrollCount>0 % zoom in
    xlim([pixpos(1)-(xl(2)-xl(1))/3 pixpos(1)+(xl(2)-xl(1))/3]);
    ylim([pixpos(2)-(yl(2)-yl(1))/3 pixpos(2)+(yl(2)-yl(1))/3]);
  else % zoom out
    xlim([pixpos(1)-(xl(2)-xl(1))/1.5 pixpos(1)+(xl(2)-xl(1))/1.5]);
    ylim([pixpos(2)-(yl(2)-yl(1))/1.5 pixpos(2)+(yl(2)-yl(1))/1.5]);
  end
  
  % keep mouse pointer over same pixel
  xl2=xlim;
  yl2=ylim;
  plocal3=[0.5,0.5];
  plDiff=plocal3-plocal2;
  xlim(xl2+plDiff(1)*diff(xl2));
  ylim(yl2+plDiff(2)*diff(yl2));
  
end