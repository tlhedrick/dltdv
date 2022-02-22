function [] = dvVideoOffsetUpdate(varargin)

% function [] = dvVideoOffsetUpdate(varargin)
%
% Callback for offset text field

cbo=varargin{1}; % callback object
app=varargin{3}; % app


% disp('case 8: validate the video offsets text')
offset=str2double(get(cbo,'String'));
if isempty(offset) || isnan(offset)
  beep
  disp('Corrected invalid input, video offsets must be numeric')
  set(cbo,'String','0'); % set the offset to zero
elseif mod(offset,1)~=0 % mod 1 will return 0 for integers
  disp('Non-integer video offsets produce sub-frame interpolation of 2D points before computing any 3D results')
  %set(cbo,'String',num2str(round(offset))); % round the offset
end
%app.reloadVid=true; % 2020-12-13 not necessary & slow
app.lastvnum=getappdata(cbo.Parent,'videoNumber'); % 2020-12-13 make sure the correct video is active
fullRedraw(app);