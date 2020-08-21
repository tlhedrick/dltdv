function [out]=dlt_splineInterpSparse(in,type)

% function [out]=dlt_splineInterpSparse(in,'type')
% Description: 	interpolates 0-value data, does not extrapolate beyond the
% bounds of the original inputs.  Interpolation is by 'type' and
% should be either 'nearest','linear','cubic' or 'spline'
%
% inputs with less than 5 entries are not interpolated
%
% Ty Hedrick, 2018-07-20

out=in; % setup basic output

for k=1:size(in,2) % for each column
  idx=find(in(:,k)~=0); % data indices
  if numel(idx)<5
    % do nothing
  else
    Y=sp2full(in(idx(1):idx(end),k)); % the Y (function resultant) value is the column of interest
    X=(1:1:size(Y,1))'; % X is a linear sequence of the same length as Y
    idx2=find(isnan(Y)==false);
    Ynew=interp1(X(idx2),Y(idx2),X,type); % interpolate new Y values
    out(idx(1):idx(end),k)=full2sp(Ynew); % set the new Y values in the matrix
  end
end