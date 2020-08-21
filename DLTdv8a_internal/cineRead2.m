function [cdata] = cineRead2(fileName,frameNum)

% function [cdata] = cineRead2(fileName,frameNum)
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
%  updated Dec 2, 2011 (error handling)
%  updated Nov 8, 2019 (cineRead2, flip image for upper-left origin)

if exist('frameNum','var')==false
  % generate exception
  errS = sprintf('frameNum input not present');
  err = MException('cineRead:noFrameNum',errS);
  throw(err);
end

% check inputs
if strcmpi(fileName(end-3:end),'.cin') || ...
    strcmpi(fileName(end-4:end),'.cine')
  
  % get file info from the cineInfo function
  info=cineInfo(fileName);
  
else
  % generate exception
  errS = sprintf('%s does not appear to be a valid CINE file',fileName);
  err = MException('cineRead2:BadFileExtension',errS);
  throw(err);
end

if frameNum<=info.NumFrames && frameNum>0 && exist('cdata','var')==false
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
    cdata(:,:,i)=rot90(tdata,1);
  end
  
else
  % generate exception
  errS = sprintf('%s has %.0f frames; you requested frame %.0f', ...
    fileName,info.NumFrames,frameNum);
  err = MException('cineRead2:OutOfRange',errS);
  throw(err);
end
