function [uv] = dlt2d_inverse(c,xy)

% function [uv] = dlt2d_inverse(c,xy)
%
% This function reconstructs the pixel (i.e. uv) coordinates of a 2D 
% (i.e. xy) coordinate as seen by the camera specificed by 2D DLT 
% coefficients c
%
% Inputs:
%  c - 8 DLT coefficients for the camera, [8,1] array
%  xy - [x,y] coordinates over f frames,[f,2] array
%
% Outputs:
%  uv - pixel coordinates in each frame, [f,2] array
%
% Ty Hedrick

% write the matrix solution out longhand for Matlab vector operation over
% all points at once

% % 3D
% uv(:,1)=(xyz(:,1).*c(1)+xyz(:,2).*c(2)+xyz(:,3).*c(3)+c(4))./ ...
%   (xyz(:,1).*c(9)+xyz(:,2).*c(10)+xyz(:,3).*c(11)+1);
% uv(:,2)=(xyz(:,1).*c(5)+xyz(:,2).*c(6)+xyz(:,3).*c(7)+c(8))./ ...
%   (xyz(:,1).*c(9)+xyz(:,2).*c(10)+xyz(:,3).*c(11)+1);

% 2D
uv(:,1)=(xy(:,1).*c(1)+xy(:,2).*c(2)+c(3))./ (xy(:,1).*c(7)+xy(:,2).*c(8)+1);
uv(:,2)=(xy(:,1).*c(4)+xy(:,2).*c(5)+c(6))./ (xy(:,1).*c(7)+xy(:,2).*c(8)+1);

