function [cdata] = cihRead(fileName,frameNum)

% function [cdata] = cihRead(fileName,frameNum)
%
% Reads the frame specified by frameNum from the Photron mraw camera file
% specified by fileName.
%
% frameNum is 1-based and starts from the first frame available in the
% file.
%
% Talia Weiss 9/1/2018 [added with permission to DLTdv7 by Ty Hedrick]

if exist('frameNum','var')==false
  % generate exception
  errS = sprintf('frameNum input not present');
  err = MException('cihRead:noFrameNum',errS);
  throw(err);
end

% check inputs & get file information
if strcmpi(fileName(end-3:end),'.cih')
  % get file info from the mrfInfo function
  info=cihInfo(fileName);
else
  % generate exception
  errS = sprintf('%s does not appear to be a valid cih file',fileName);
  err = MException('cihRead:BadFileExtension',errS);
  throw(err);
end

if frameNum<=info.NumFrames & frameNum>0
  % figure out bits on disk per pixel
  if info.bitDepth==8
    bpp=8;
  elseif info.bitDepth>8 && info.bitDepth<17
    bpp=16;
  elseif info.bitDepth==24
    bpp=24;
  else
    cdata=[];
    disp('cihRead error: unknown bitdepth')
    return
  end
  
  % get the filename of the mraw file
  mraw = [fileName(1:end-3), 'mraw'];
  
  % offset is the location of the start of the target frame in the file -
  % the pad + 8bits for each frame + the size of all the prior frames
  offset=(frameNum-1)* ...
    (info.Height*info.Width*bpp/8);
  
  % get a handle to the file from the filename
  f1=fopen(mraw);
  
  % could not open file
  if f1==-1
    errS = sprintf('Unable to open mraw file %s',mraw);
    err = MException('cihRead:CannotOpenFile',errS);
    throw(err);
  end
  
  % seek ahead from the start of the file to the offset (the beginning of
  % the target frame)
  fseek(f1,offset,-1);
  
  % read a certain amount of data in - the amount determined by the size
  % of the frames and the camera bit depth, then cast the data to either
  % 8bit or 16bit unsigned integer
  if bpp==8 % 8bit gray
    idata=fread(f1,info.Height*info.Width,'*uint8');
    nDim=1;
  elseif bpp==16 % 10, 12 14 or 16 bit gray
    idata=uint16(fread(f1,info.Height*info.Width,'*uint16'));
    nDim=1;
  elseif bpp==24 % 24bit color
    idata=double(fread(f1,info.Height*info.Width*3,'*uint8'))/255;
    nDim=3;
  else
    disp('error: unknown bitdepth')
    return
  end
  
  if info.bitDepthRec ~= info.bitDepth && strcmp(info.bitSide, 'Lower')
    idata = bitshift(idata, info.bitDepth - info.bitDepthRec);
  end
  
  % destroy the handle to the file
  fclose(f1);
  
  % the data come in from fread() as a 1 dimensional array; here we
  % reshape them to a 2-dimensional array of the appropriate size
  %cdata=zeros(info.Height,info.Width,nDim);
  for i=1:nDim
    tdata=reshape(idata(i:nDim:end),info.Width,info.Height);
    cdata(:,:,i)=fliplr((rot90(tdata,-1)));
  end
else
  % generate exception
  errS = sprintf('%s has %.0f frames; you requested frame %.0f', ...
    fileName,info.NumFrames,frameNum);
  err = MException('cihRead:OutOfRange',errS);
  throw(err);
end

end

