function [h] = redlakeplot(varargin)

% function [h] = redlakeplot(rltiff,xy)
%
% Description:	Quick function to plot images from Redlake tiffs
% 	This function was formerly named birdplot
%
% Version history:
% 1.0 - Ty Hedrick 3/5/2002 - initial version

if nargin ~= 1 & nargin ~= 2
  disp('Incorrect number of inputs.')
  return
end

h=image(varargin{1},'CDataMapping','scaled');
%set(h,'EraseMode','normal');
colormap(gray(256))
axis xy
hold on

if nargin == 2
  plot([varargin{2}(:,1)],[varargin{2}(:,2)],'r.');
end
