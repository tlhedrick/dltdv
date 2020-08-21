function [info] = mrfInfo(fileName)

% function [info] = mrfInfo(fileName)
%
% Reads header information from a Redlake uncompressed raw file (*.mrf)
% file.
%
% info.Width - image width
% info.Height - image height
% info.bitDepth - image bit depth
% info.NumFrames - total number of frames
% info.frameRate - recording frame rate, likely not stored accurately in
% the header.
%
% This function does not depend on any of the Redlake software development
% kit files and was developed purely from the description of the *.mrf file
% header in the Redlake manual appendices.  It has been tested only with 8
% and 10-bit files from an N5 camera and may not work properly with files
% from a different camera.
%
% Ty Hedrick, February 9, 2011

% check for an mrf suffix
if strcmpi(fileName(end-3:end),'.mrf')
  
  % get a file handle from the filename
  f1=fopen(fileName);
  
  % read the header, piece by piece
  info.header = char(fread(f1,8,'schar')');
  blank1 = fread(f1,1,'*int32');
  info.headerPad = fread(f1,1,'int32=>double')+8+4; % header length from start of file
  info.NumFrames = fread(f1,1,'int32=>double');
  info.Width = fread(f1,1,'int32=>double');
  info.Height = fread(f1,1,'int32=>double');
  info.bitDepth = fread(f1,1,'int32=>double');
  info.nCams = fread(f1,1,'int32=>double');
  blank2 = fread(f1,1,'*int32');
  blank3 = fread(f1,1,'*int32');
  info.nBayer = fread(f1,1,'*int16');
  info.nCFAPattern = fread(f1,1,'*int16');
  info.frameRate = fread(f1,1,'int32=>double');  % not stored correctly?
  userdata = fread(f1,59,'int32=>double');
  
  % release the file handle
  fclose(f1);
  
  % variable timing not possible in mrf files
  info.variableTiming=false;
  
else
  fprintf('%s does not appear to be an mrf file.',fileName)
  info=[];
end

end

