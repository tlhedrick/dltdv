function [xy,rmse] = dlt2d_reconstruct(c,camPts)

% function [xy,rmse] = dlt2d_reconstruct(c,camPts)
%
% This function reconstructs the 2D position of a coordinate based on a set
% of 2D DLT coefficients and [u,v] pixel coordinates from 1 camera
%
% Inputs:
%  c - 8 DLT coefficients for n cameras, [8,n] array
%  camPts - [u,v] pixel coordinates from all n cameras over f frames,
%   [f,2*n] array
%
% Outputs:
%  xy - the xy location in each frame, an [f,2] array
%  rmse - the root mean square error for each xy point, an [f,1] array,
%   units are [u,v] i.e. camera coordinates or pixels
%
% Ty Hedrick

% number of frames
nFrames=size(camPts,1);

% number of cameras
nCams=size(camPts,2)/2;

% setup output variables
xy(1:nFrames,1:2)=NaN;
rmse(1:nFrames,1)=NaN;

% process each frame
for i=1:nFrames

  % get a list of cameras with non-NaN [u,v]
  cdx=find(isnan(camPts(i,1:2:nCams*2))==false);

  % check for non-NaN pixel coordinate, skip this row if found
  if numel(cdx)<1
    continue
  end

  % preallocate least-square solution matrices
  m1=zeros(2,2);
  m2=zeros(2,1);

  m1(1:2:numel(cdx)*2,1)=camPts(i,cdx*2-1).*c(7,cdx)-c(1,cdx);
  m1(1:2:numel(cdx)*2,2)=camPts(i,cdx*2-1).*c(8,cdx)-c(2,cdx);
  m1(2:2:numel(cdx)*2,1)=camPts(i,cdx*2).*c(7,cdx)-c(4,cdx);
  m1(2:2:numel(cdx)*2,2)=camPts(i,cdx*2).*c(8,cdx)-c(5,cdx);

  m2(1:2:numel(cdx)*2,1)=c(3,cdx)-camPts(i,cdx*2-1);
  m2(2:2:numel(cdx)*2,1)=c(6,cdx)-camPts(i,cdx*2);

  % get the least squares solution to the reconstruction
  xy(i,1:2)=linsolve(m1,m2);

  % get the rmse
  if numel(cdx)==1
    rmse(i,1)=NaN;
  else
    % following the rrmse approach
    uvp=[];
    for j=1:size(c,2) % for each camera
      uvp(:,j*2-1:j*2)=dlt2d_inverse(c(:,j),xy(i,1:2));
    end
    rmse(i,1)=inansum((uvp-camPts(i,:)).^2./repmat((sum(isfinite(camPts(i,:)),2)-2),1,size(camPts(i,:),2)),2).^0.5;
  end

  % 1-camera version
  % % preallocate least-square solution matrices
  % m1=zeros(2,2);
  % m2=zeros(2,1);
  % 
  % m1(1,1)=camPts(i,1).*c(7,1)-c(1,1);
  % m1(1,2)=camPts(i,1).*c(8,1)-c(2,1);
  % m1(2,1)=camPts(i,2).*c(7,1)-c(4,1);
  % m1(2,2)=camPts(i,2).*c(8,1)-c(5,1);
  % 
  % m2(1,1)=c(3,1)-camPts(i,1);
  % m2(2,1)=c(6,1)-camPts(i,2);
  % 
  % % get the least squares solution to the reconstruction
  % xy(i,1:2)=linsolve(m1,m2);


end


