function [] = dvDeleteFcn(varargin)

% function [] = dvDeleteFcn(varargin)
%
% DeleteFcn callback for DLTdv8 app windows

app=varargin{3};

% if initialization completed and there is data to save
if app.recentlysaved==0
  savefirst= ...
    questdlg('Would you like to save your project before you quit?', ...
    'Save first?','yes','no','yes');
  pause(0.1); % make sure that the questdlg executed (MATLAB bug)
  if strcmp(savefirst,'yes')
    dvSaveproject(app);
    
  else
    app.recentlysaved=1; % mark the data saved to avoid a 2nd check
  end
end


% delete videos
for i=1:app.nvid
  try
    delete(app.handles{i+200});
  catch
  end
end


% delete time series figure
try
  delete(app.handles{600});
catch
end

% delete sub-apps
try
for i=1:numel(app.subAppObjects)
  try % use try-catch since many of these could be stale
    delete(app.subAppObjects{i});
  catch
  end
end
catch
end

% turn warnings back on
warning('on','images:inv_lwm:cannotEvaluateTransfAtSomeOutputLocations');

% delete main figure
try
  delete(app);
catch
end