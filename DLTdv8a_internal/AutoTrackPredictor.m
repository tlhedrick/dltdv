function [x,y]=AutoTrackPredictor(otherpts,fr,mode)

% function [x,y]=AutoTrackPredictor(otherpts,fr,mode)
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

% get the amount of data available for prediction
if fr<11
  ndpts=find(otherpts(1:fr,1)~=0);
else
  ndpts=find(otherpts(fr-10:fr,1)~=0)+fr-11;
end

% if we have little data, force certain algorithms
if numel(ndpts)<3
  forceMode=3; % static
elseif numel(ndpts)<8 || fr < 11
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
  kpts=otherpts(fr-10:fr,:);
  [p]=kalmanPredictorAcc(sp2full(kpts));
  p=round(p);
  x=p(1);
  y=p(2);
end