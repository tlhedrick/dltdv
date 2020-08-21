function [mov,fname]=mediaRead2(fname,frame)

% function [mov,fname]=mediaRead2(fname,frame);
%
% Wrapper function which uses VideoReader, cineRead or mrfRead to
% grab an image from a video. Also puts the cdata result from
% cineRead into a mov.* structure.

% check for VideoReader types
if ischar(fname)
  [~,~,ext]=fileparts(fname);
  if strcmpi(ext,'.mov') || strcmpi(ext,'.avi') || strcmpi(ext,'.mp4')
    % turn the filename into an videoreader object for videoreader
    % file types
    fname=VideoReader(fname);
  end
end

if ischar(fname) % for mrf, cih or cine files
  [~,~,ext]=fileparts(fname);
  
  if strcmpi(ext,'.cin') || strcmpi(ext,'.cine') % vision research cine
    mov.cdata=cineRead(fname,frame);
  elseif strcmpi(ext,'.mrf') % IDT/Redlake multipage raw
    mov.cdata=mrfRead(fname,frame);
  elseif strcmpi(ext,'.cih') % Photron Mraw raw
    mov.cdata=cihRead(fname,frame);
  else
    mov=[];
    disp('mediaRead2: unknown file extension')
    return
  end
else % fname is not a char so it is a videoreader obj
  % check current time & don't seek to a new time if we don't need to
  ctime=fname.CurrentTime;
  ftime=(frame-1)*(1/fname.FrameRate); % start time of desired frame
  if abs(ctime-ftime)<0.90/fname.FrameRate % use 0.9 instead of 1 to avoid ambiguity near the end of a file
    % no need to seek
  else
    fname.CurrentTime=ftime;
  end
  mov.cdata=fname.readFrame;
end
end