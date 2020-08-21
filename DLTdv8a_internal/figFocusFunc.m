function [] = figFocusFunc(varargin)

% function [] = figFocusFunc(varargin)
%
% Called when a figure comes into focus in the operating system

% figure out the movie number
% wrap in a try-catch-end to avoid spamming console with errors as figures
% are being deleted
try
  app=varargin{3};
  
  % set lastvnum to myself and run full redraw
  app.lastvnum=getappdata(varargin{4},'videoNumber');
  fullRedraw(app);
catch
end