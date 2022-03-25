function [out] = blockCheck(img,bs,st,fun)

% function [out] = blockCheck(img,bs,st,@fun)
%
% block processing loop for images
% img = input image (or m,n,d array)
% bs = block size (square block width)
% st = stride
% fun = function handle to run on each block
%
% out = [row,column,fun_out ... d]

steps = round(-(bs-1)/2:(bs-1)/2); % indices for the block away from center
I = [abs(min(steps)-1):st:size(img,2)-max(steps)]; % I = y centers
J = [abs(min(steps)-1):st:size(img,1)-max(steps)]; % J = x centers

out=[];
for i=I
  for j=J
    p=img(j+steps,i+steps,:);
    out=[out;j,i,squeeze(fun(p))'];
  end
end