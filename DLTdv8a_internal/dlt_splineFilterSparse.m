function [Ddata]=dlt_splineFilterSparse(data,tol,weights,order)

% function [Ddata]=dlt_splineFilterSparse(data,tol,weights,order)
%
% Inputs:
%   data - a columnwise sparse data matrix. No NaNs or Infs please.
%   tol - the total error allowed: tol=sum((data-Ddata)^2)
%   weights - weighting function for the error:
%     tol=sum(weights*(data-Ddata)^2)
%   order - the derivative order (note that tol is with respect to the 0th
%     derivative)
%
% Outputs:
%   Ddata - the smoothed function (or its derivative) evaluated across the
%     input data
%
% Uses the spaps function of the spline toolbox to compute the smoothest
% function that conforms to the given tolerance and error weights.
%
% version 2, Ty Hedrick, Feb. 28, 2007
% sparse version 1, Ty Hedrick, 2018-07-20
% remove zero-weight data (i.e. interpolated data) from the final output, Ty Hedrick, 2021-05-14

% create a sequence matrix, assume regularly spaced data points
X=(1:size(data,1))';

% set any NaNs in the weight matrix to zero
weights(isnan(weights))=0;

% spline order
sporder=3; % quintic spline, okay for up to 3rd order derivative

% spaps can't handle a weights matrix instead of a weights vector, so we
% loop through each column in data ...
Ddata=data;
for i=1:size(data,2)
  
  % Non-zero, finite value index
  idx=find(data(:,i)~=0 & isfinite(data(:,i)) & weights(:,i)~=0);
  
  if numel(idx)>5 % >5 consistent with dlt_splineInterpSparse
    [sp] = spaps(X(idx),data(idx,i)',tol(i),weights(idx,i),sporder);
    
    % get the derivative of the spline
    spD = fnder(sp,order);
    
    % compute the derivative values on X
    Ddata(idx,i) = fnval(spD,X(idx));
    
    % set remove zero-weight data to zero (sparse null)
    Ddata(weights(:,i)==0,i)=0;
  end
  
end