function [info] = cihInfo(fileName)

% function [info] = cihInfo(fileName)
%
% Reads header information from a Photron header file (*.cih)
% file.
%
% info.Width - image width
% info.Height - image height
% info.bitDepth - image bit depth
% info.NumFrames - total number of frames
% info.frameRate - recording frame rate
%
% info.filetype - File Format
% info.bitSide - EffectiveBit Side
% info.bitDepth - EffectiveBit Depth

% Talia Weiss, 9/1/2018 [added with permission to DLTdv7 by Ty Hedrick]

% check for an mrf suffix
if strcmpi(fileName(end-3:end),'.cih')
  
  % get a file handle from the filename
  f1=fopen(fileName);
  
  tline = fgetl(f1);
  linenum = 1;
  while linenum < 82 %first part of the cih file
    tline = fgetl(f1); %get line starting at line 2
    linenum = linenum + 1;
    if ~strcmp(tline, '')
      if ~strcmp(tline, 'END') & ~strcmp(tline(1), '#')
        tcell = cellfun(@(x) strtrim(x), strsplit(tline, ':'), 'UniformOutput', 0);
        
        name = tcell{1};
        val = tcell{2};
        
        if strcmp(name, 'Total Frame')
          info.NumFrames = str2num(val);
          
        elseif strcmp(name, 'Image Width')
          info.Width = str2num(val);
          
        elseif strcmp(name, 'Image Height')
          info.Height = str2num(val);
          
        elseif strcmp(name, 'Color Bit')
          info.bitDepth = str2num(val);
          
        elseif strcmp(name, 'Record Rate(fps)')
          info.frameRate = str2num(val);
          
        elseif strcmp(name, 'File Format')
          info.filetype = val;
        elseif strcmp(name, 'EffectiveBit Side')
          info.bitSide = val;
        elseif strcmp(name, 'EffectiveBit Depth')
          info.bitDepthRec = str2num(val);
        end
      end
    end
  end
  
  % release the file handle
  fclose(f1);
  info.variableTiming = 0;
else
  fprintf('%s does not appear to be an cih file.',fileName)
  info=[];
  
  if strcmp(info.filetype, 'MRaw')
    fprintf('%s does not appear to be be for an mraw file.',fileName)
    info = [];
  end
end
end

