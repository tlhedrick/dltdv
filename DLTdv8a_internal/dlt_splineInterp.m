function [out,fitted]=dlt_splineInterp(in,type)

% function [out,fitted]=dlt_splineInterp(in,'type')
% Description: 	Fills in NaN points with the result of a cubic spline
%	       	interpolation.  Marks fitted points with a '1' in a new,
%	       	final column for identification as false points later on.
%	       	This function is intended to work with 3-D points output
%	       	from the 'reconfu' Kinemat function.  Points marked with
%					a '2' were not fitted because of a lack of data
%
%					'type' should be either 'nearest','linear','cubic' or 'spline'
%
%					Note: the 'fitted' return variable is only 1 column no matter
%					how many columns are passed in 'in', 'fitted' reflects _any_
%					fits performed on that row in any column of 'in'
%
% Ty Hedrick

fitted(1:size(in,1),1)=0; % initialize the fitted output matrix

for k=1:size(in,2) % for each column
  Y=in(:,k); % the Y (function resultant) value is the column of interest
  X=(1:1:size(Y,1))'; % X is a linear sequence of the same length as Y
  
  Xi=X; Yi=Y; % duplicate X and Y and use the duplicates to mess with
  
  nandex=find(isnan(Y)==1); % get an index of all the NaN values
  fitted(nandex,1)=1; % set the fitted matrix based on the known NaNs
  
  Xi(nandex,:)=[]; % delete all NaN rows from the interpolation matrices
  Yi(nandex,:)=[];
  
  if size(Xi,1)>1 % check that we're not dealing with all NaNs
    Ynew=interp1(Xi,Yi,nandex,type,'extrap'); % interpolate new Y values
    in(nandex,k)=Ynew; % set the new Y values in the matrix
    if sum(isnan(Ynew))>0
      disp('dlt_splineInterp: Interpolation error, try the linear option')
      break
    end
  else
    % only NaNs or a single value, don't interpolate
  end
  
end

out=in; % set output variable