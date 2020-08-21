function [] = dvSetUndistortion(varargin)

% function [] = dvSetUndistortion(varargin)
%
% Callback for the Set Undistortion button on DLTdv8 windows

cbo=varargin{1};
app=varargin{3};

videoNumber=getappdata(get(cbo,'parent'),'videoNumber');
% get the undistortion file
[fc,pc]=uigetfile('*.mat',sprintf('Select the Camera%d UNDTFORM File - Cancel if none exists',videoNumber));
if isequal(fc,0)
  fprintf('Camera %d undistortion profile set to None\n',videoNumber);
  app.camd{videoNumber}=[];
  app.camud{videoNumber}=[];
  set(app.handles{425+videoNumber},'String','Undistortion file: none');
else
  % load the file
  load([pc,fc]);
  app.camd{videoNumber}=camd;
  app.camud{videoNumber}=camud;
  disp(sprintf('Loaded undistortion transform matrix for camera%d.\n',videoNumber));
  set(app.handles{425+videoNumber},'String',['Undistortion file: ',fc]);
end

fullRedraw(app);