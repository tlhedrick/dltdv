function [y] = inanmean(varargin)

% internal version of nanmean in case the user doesn't have the stats
% toolbox
% 
% if nargin==1
%   dim=1;
% end
% 
% ndx=isnan(x);
% x(ndx)=0; % turn NaNs to zeros
% 
% nn=sum(~ndx,dim); % # of non-NaN values
% nn(nn==0)=NaN; % don't allow zeros
% 
% % add it up
% s=sum(x(~ndx),dim);
% 
% % get the mean
% y=s./nn;

% update for recent MATLAB
y = mean(varargin{:},'omitmissing');