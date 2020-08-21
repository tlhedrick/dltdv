function [cdata] = mrfRead(fileName,frameNum)

% function [cdata] = mrfRead(fileName,frameNum)
%
% Reads the frame specified by frameNum from the Redlake raw camera file
% specified by fileName.  It will not read compressed files.  Furthermore,
% the bitmap in cdata may need to be flipped, transposed or rotated to
% display properly in your imaging application.
%
% frameNum is 1-based and starts from the first frame available in the
% file.
%
% This function does not depend on any of the Redlake software development
% kit files and was developed purely from the file format descriptions in
% the manual appendices.  It has been tested only with 8 & 10 bit
% grayscale files from an N5 and may require further development or
% debugging when used with files from other sources.
%
% Ty Hedrick, Feb. 09, 2011

% check inputs
if strcmpi(fileName(end-3:end),'.mrf') && isnan(frameNum)==false
  
  % get file info from the cineInfo function
  info=mrfInfo(fileName);
  
  % figure out bits on disk per pixel
  if info.bitDepth==8
    bpp=8;
  elseif info.bitDepth>8 && info.bitDepth<17
    bpp=16;
  elseif info.bitDepth==24
    bpp=24;
  else
    cdata=[];
    disp('mrfRead error: unknown bitdepth')
    return
  end
  
  % offset is the location of the start of the target frame in the file -
  % the pad + 8bits for each frame + the size of all the prior frames
  offset=info.headerPad + 0 + (frameNum-1)* ...
    (info.Height*info.Width*bpp/8);
  
  % get a handle to the file from the filename
  f1=fopen(fileName);
  
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
    idata=fread(f1,info.Height*info.Width,'*uint16');
    nDim=1;
  elseif bpp==24 % 24bit color
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
    tdata=reshape(idata(i:nDim:end),info.Width,info.Height)';
    %cdata(:,:,i)=fliplr(rot90(tdata,-1));
    cdata(:,:,i)=tdata;
  end
else
  % complain if the use gave what appears to be an incorrect filename
  fprintf( ...
    '%s does not appear to be an mrf file or frameNum is not available.'...
    ,fileName)
end

end
