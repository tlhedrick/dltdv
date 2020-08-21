function [img] = clearCorners(img)

% function [img] = clearCorners(img)
%
% Sets the corners to 0 in the image

[su,sv]=size(img,[1,2]);

d=round(0.02*max([su sv]));
% 
% % corners
% img(1:d,1:d,:)=0; % upper left
% img(su-d:su,1:d,:)=0; % lower left
% img(1:d,sv-d:sv,:)=0; % upper right
% img(su-d:su,sv-d:sv,:)=0; % lower right

% sides
img(1:d,:,:)=0;
img(su-d:su,:)=0;
img(:,1:d,:)=0;
img(:,sv-d:sv,:)=0;
