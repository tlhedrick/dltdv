function [] = dvScrollWheel(varargin)

fh=varargin{1}; % figure handle
swe=varargin{2}; % scroll event
app=varargin{3}; % DLTdv8a app
h=app.handles;
me = getappdata(fh,'videoNumber')+200;

pl=get(0,'PointerLocation'); % pointer location on the screen
pos=get(fh,'Position'); % get the figure position
%fr=app.FrameNumberSlider.Value; % get the current frame 

% calculate pointer location in normalized units
plocal=[(pl(1)-pos(1,1)+1)/pos(1,3), (pl(2)-pos(1,2)+1)/pos(1,4)];

axh=me+100; % axis handle for each figure is offset by +100

% zoom in or out as indicated
if axh~=0
  axpos=get(h{axh},'Position'); % axis position in figure
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