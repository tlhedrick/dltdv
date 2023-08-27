function [info]=mediaInfo(fname)

% function [info]=mediaInfo(fname);
%
% Wrapper which uses aviinfo or cineInfo depending on which is appropriate.

if strcmpi(fname(end-3:end),'.avi') || strcmpi(fname(end-3:end),'.mp4') || strcmpi(fname(end-3:end),'.mov')
  info=mmFileInfo2(fname);
elseif strcmpi(fname(end-3:end),'.cin')
  info=cineInfo(fname);
elseif strcmpi(fname(end-4:end),'.cine')
  info=cineInfo(fname);
elseif strcmpi(fname(end-3:end),'.mrf')
  info=mrfInfo(fname);
elseif strcmpi(fname(end-3:end),'.cih')
  info=cihInfo(fname);
else
  info=[];
  disp('mediaInfo: bad file extension')
end

% set better default framerate
if isnan(info.frameRate) | info.frameRate==0
  info.frameRate=1;
end

% set default variableTiming
fn=fieldnames(info);



end

function [info] = mmFileInfo2(fname)

% function [info] = mmFileInfo2(fname)
%
% An abbreviated info command using the VideoReader object

obj=VideoReader(fname); % turn the filename into an videoreader object

% Directly querying the frame count in VideoReader can take a long while
% since MATLAB wants to decode and count every frame in the file.
info.NumFrames=round(obj.FrameRate*obj.Duration);

info.compression = obj.VideoCompression;
info.frameRate = obj.FrameRate;

% check for variable frame timing
if info.NumFrames>4 & ismethod(obj,'readFrame')
  for i=1:5
    fTimes(i,1)=obj.CurrentTime;
    foo=obj.readFrame;
  end
  fSpan=round(diff(fTimes)*100000)/100000; % round to remove numeric precision noise
  if numel(unique(fSpan))>1
    info.variableTiming=true;
  else
    info.variableTiming=false;
  end
else
  info.variableTiming=false;
end
end
