function [info]=mediaInfo(fname)

% function [info]=mediaInfo(fname)
%
% Outer wrapper for media (i.e. video) information gathering. Calls
% mmFileInfo2, cineInfo, mrfInfo, or cihInfo as indicated by file
% extension. mmFileInfo2 is itself a VideoReader wrapper for formats
% supported by MATLAB through the local operating system libraries.

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

% check for variable frame timing and a long end frame if possible
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


% check for long frames at the end
if info.NumFrames>24 & ismethod(obj,'readFrame')
  obj.CurrentTime=obj.Duration-(1/obj.FrameRate)*20;
  timeStack=[];
  kg=true;
  try
      while kg
          obj.readFrame();
          timeStack=[timeStack;obj.CurrentTime];
      end
  catch
    % nothing - we get here when there are no frames left to read
  end

  % look at inter-frame time differences and find the last difference that
  % matches the expected frameRate
  tsd=diff(timeStack);
  idx=find(abs(tsd-1/obj.FrameRate)<(1/obj.FrameRate)*0.05);
  if numel(idx)>0
    realDuration=timeStack(idx(end)+1);
    nNumFrames=round(obj.FrameRate*realDuration);
    if nNumFrames~=info.NumFrames
        info.NumFrames=nNumFrames;
        fprintf('mediaInfo: ignoring dummy frames at the end of %s\n',fname)
    end
  end

end

end
