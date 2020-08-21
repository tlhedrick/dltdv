function [Y] = inanstd(varargin)

% uses the nanstd function if available, otherwise mimics it with some
% slightly slower code
if exist('nanstd','file')==2
  Y=nanstd(varargin{:});
else
  if nargin==1
    m=varargin{1};
    Y(1:size(m,2),1)=NaN;
    for i=1:size(m,2)
      Y(i,1)=std(m(isnan(m(:,i))==false,i));
    end
  else
    Y=NaN;
    disp(['nanstd with more than one argument is not supported', ...
      'on this computer'])
  end
end