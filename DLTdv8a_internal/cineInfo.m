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
  
  % variable timing not possible in mrf files
  info.variableTiming=false;
else
  fprintf('%s does not appear to be a cine file.',fileName)
  info=[];
end

end
