function [x,y]=AutoTrackPredictor(otherpts,fr,mode,stepSize)

% function [x,y]=AutoTrackPredictor(otherpts,fr,mode,stepSize)
%
% This function attempts to predict the [x,y] coordinates of the point in
% frame fr+1 based on it's location at other times.  The predictor
% algorithm is specified by the "Autotrack predictor" menu entry, with a
% few caveats as to the amount of prior data required for the different
% algorithms.  The selected menu entry number is passed in as "mode" from
% the calling function.
%
% Modes are:
% 1: extended Kalman (best predictor)
% 2: linear fit (okay predictor)
% 3: static (special case)

% compatibility with older code
if exist('stepSize','var')~=1
    stepSize=1;
end

% get the index of the last 11 points on the step
stepIndex=flipud((fr:-stepSize:1)');
if numel(stepIndex)>11
    stepIndex=stepIndex(end-10:end,:);
end

% get the amount of data available for prediction
ndpts=find(otherpts(stepIndex,1)~=0 & isnan(otherpts(stepIndex,1))==false); % find only good data
ndpts=stepIndex(ndpts); % make ndpts a direct index into otherData

% exit if there are no data
if isempty(ndpts)
  x=NaN;
  y=NaN;
  return
end

% if we have little data, force certain algorithms
if numel(ndpts)<3
  forceMode=3; % static
elseif numel(ndpts)<8 || fr < 11*stepSize
  forceMode=2; % linear
else
  forceMode=0; % any
end

% choose a mode based on the menu and data
mode=max([mode,forceMode]);

% make a prediction
if mode==3 % static
  x=round(otherpts(ndpts(end),1));
  y=round(otherpts(ndpts(end),2));
elseif mode==2 % linear fit
  prevpts=sp2full(otherpts(ndpts(end-2:end),:));
  seq=(1:size(prevpts,1))';
  p=polyfit(seq,prevpts(:,1),1);
  x=round(polyval(p,4));
  p=polyfit(seq,prevpts(:,2),1);
  y=round(polyval(p,4));
elseif mode==1 % extended Kalman
  %kpts=otherpts(fr-10:fr,:);
  kpts=otherpts(stepIndex,:);
  [p]=kalmanPredictorAcc(sp2full(kpts));
  p=round(p);
  x=p(1);
  y=p(2);
end