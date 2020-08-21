function [y] = inansum(x,dim)

% internal version of nansum in case the user doesn't have the stats
% toolbox

if nargin==1
  dim=1;
end

% set NaNs to zero and sum
x(isnan(x))=0;
y=sum(x,dim);