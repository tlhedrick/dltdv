function [CI,tol,weights]=dlt_confidenceIntervalsSparse(coefs,camPts,minErr,app)

% function [CI,tol,weights]=dlt_confidenceIntervalsSparse(coefs,camPts,minErr,app)
%
% A tool for creating 95% confidence intervals for digitized points along
% with tolerance and weight matrices for use with spline filtering tools.
% Uses bootstrapping and may take a long time to run.  This version is
% sparse-data aware.
%
% Inputs:
%  coefs - the DLT coefficients for the cameras
%  camPts - the XY coordinates of the digitized points
%  minErr - minimum pixel error
%  app - DLTdv8 app object
%
% Outputs:
%  CI - the 95% confidence interval values for the digitized points - i.e.
%   the xyz coordinates have a 95% confidence interval of xyz+CI to xyz-CI
%  tol - tolerance information for use with a smoothing spline
%  weights - weight information for use with a smoothing spline
%
% Ty Hedrick

% set a minimum error of zero if none is specified
if exist('minErr','var')==false
  minErr=0;
end

% number of cameras
nCams=size(coefs,2);

% number of points
nPts=size(camPts,2)./(2*size(coefs,2));

% number of bootstrap iterations
bsIter=250; % 250 in normal production

% create a progress bar
h=waitbar(0,'Creating 95% confidence intervals...');

% do subframe interpolation of xy point data; overwrite camPts input
disp('Checking subframe interpolation')
for i=1:app.numpts % for each point
  % subframe interpolation
  for fr=1:size(app.xypts,1) % for each frame
    try
      sfi=mod(full(app.offset(fr,:)),1); % subframe offset in this frame
      if sum(abs(sfi))~=0
        xy=sp2full(app.xypts(fr-1:fr+1,(1:2*app.nvid)+(i-1)*2*app.nvid));
        skel=(-1:1)'; % interpolation sequence
        for j=1:app.nvid % loop through each camera
          if sfi(j)~=0
            ndx=find(isfinite(xy(:,j*2)));
            if numel(ndx)>1
              xyI(:,j*2-1:j*2)=interp1(skel(ndx),xy(ndx,j*2-1:j*2),skel+sfi(j),'linear','extrap');
            else
              xyI(:,j*2-1:j*2)=xy(:,j*2-1:j*2);
            end
          end
        end
        camPts(fr-1:fr+1,(1:2*app.nvid)+(i-1)*2*app.nvid)=full2sp(xyI(2,:));
      end
    catch % fallback to no interpolation
      % do nothing - campts is already uninterpolated
    end
  end
end



% loop through each individual point
%xyzBS(1:size(camPts,1),1:3,1:bsIter)=NaN;
%xyzBS=sparse(zeros(size(camPts,1),3,bsIter));
xyzSD=NaN(size(camPts,1),nPts*3);
%xyzSD=sparse(zeros(size(camPts,1),nPts*3));
for i=1:nPts
  % reconstruct based on the xy points and the coefficients
  nzidx=find(sum(camPts(:,i*2*nCams-2*nCams+1:i*2*nCams)~=0,2)>0);
  icamPts=sp2full(camPts(nzidx,i*2*nCams-2*nCams+1:i*2*nCams));
  for j=1:size(icamPts,2)/2
    if isempty(app.camud{j})==false
      icamPts(:,j*2-1:j*2)=applyTform(app.camud{j},icamPts(:,j*2-1:j*2));
    end
  end
  [xyz,rmse] = dlt_reconstruct_v2(coefs,icamPts);
  
  % enforce minimum error
  rmse(rmse<minErr)=minErr;
  
  % don't trust rmse values from only two cameras; instead replace them
  % with the average for all two-camera situations
  nanSums=sum(abs(1-isnan(icamPts(:,2:2:nCams*2))),2);
  nanSums(nanSums==0)=NaN;
  mnRmse=mean(rmse(nanSums==2));
  rmse(nanSums==2)=mnRmse;
  
  %   % convert xyz and rmse back to sparse
  %   xyz=full2sp(xyz);
  %   rmse=full2sp(rmse);
  
  % bootstrap loop
  xyzBS=NaN(size(xyz,1),3,bsIter);
  xyzSDi=NaN(size(xyz,1),3);
  for j=1:bsIter
    %per=randn(size(icamPts)).*repmat(rmse,1,2*nCams)+icamPts;
    per=randn(size(icamPts)).*repmat(rmse.*2^0.5./nanSums,1,2*nCams)+icamPts;
    for k=1:size(per,2)/2
      if isempty(app.camud{k})==false
        per(:,k*2-1:k*2)=applyTform(app.camud{k},per(:,k*2-1:k*2));
      end
    end
    [xyzBS(:,:,j)] = dlt_reconstruct_v2(coefs,per);
    waitbar((((i-1)/nPts)+(j/(nPts*bsIter))),h);
  end
  
  for j=1:size(xyz,1)
    xyzSDi(j,1:3)=inanstd(rot90(squeeze(xyzBS(j,:,:))));
  end
  
  % re-pack to original locations
  xyzSD(nzidx,i*3-2:i*3)=xyzSDi;
  
end

% build confidence intervals
CI=full2sp(1.96*xyzSD);

% build spline filtering weights
weights=full2sp((1./(xyzSD./repmat(min(xyzSD),size(xyzSD,1),1))));

% export tolerances for spline filtering
tol=inansum(weights.*(xyzSD.^2));

% clean up the progress bar
close(h)