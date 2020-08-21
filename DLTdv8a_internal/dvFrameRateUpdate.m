function [] = dvFrameRateUpdate(varargin)

% function [] = dvFrameRateUpdate(varargin)
%
% Callback for changes to the frame rate field in DLTdv8a movie windows

cbo=varargin{1};
app=varargin{3};

% which movie did the call originate from?
p=get(cbo,'parent');
idx=getappdata(p,'videoNumber');

% what's the new frame rate?
frNew=str2num(get(cbo,'string'));

% check input validity
if isempty(frNew) || frNew<=0 || isnan(frNew)
  set(cbo,'string',num2str(app.movFrameRates(idx)));
  disp('Video frame rates must be numeric and positive.')
  return
end

% update userdata
app.movFrameRates(idx)=frNew;
app.movFrameRateRatios=app.movFrameRates./app.movFrameRates(1);

% redraw all movies
fullRedraw(app)