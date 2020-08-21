function [rmse] = rrmse(coefs,uv,xyz)

% function [rmse] = rrmse(coefs,uv,xyz)
%
% The rmse output of dlt_reconstruct and dlt_reconstruct fast is an
% algebraic residual and although it generally tracks the reprojection
% error of a given point, it does not do so exactly and there can be large
% deviations in some cases. Thus, for algorithms that depend on rmse as a
% quality measure, it can be useful to calculate a "real" rmse that is more
% closely based on reprojection error. This function provides that measure.
%
% Inputs: coefs = dlt coefficients (11,n)
%         uv = image coordinate observations (m,n*2)
%         xyz = 3D coordinates (m,3) (optional)
%
% Outputs: rrmse = real rmse, reprojection error conditioned by degrees of
% freedom in uv
%
% Ty Hedrick, 2015-07-29

% get xyz if they are not given
if exist('xyz','var')==false
  [xyz] = dlt_reconstruct(coefs,uv);
end

% get reprojected uv
uvp=uv*NaN;
for i=1:size(coefs,2)
  uvp(:,i*2-1:i*2)=dlt_inverse(coefs(:,i),xyz);
end

% get real rmse
% note that this has the same degrees of freedom conditioning as dlt rmse,
% i.e. 2*n-3 where n is the number of cameras used in reconstruction
rmse=inansum((uvp-uv).^2./repmat((sum(isfinite(uv),2)-3),1,size(uv,2)),2).^0.5;