function [norms] = rnorm(matrix)

% function [norms] = rnorm(matrix)
%
% Description: rnorm returns a column of norm values.  Given an input
% 	       matrix of X rows and Y columns it returns an X by 1
%	       column of norms.

norms=sqrt(dot(matrix',matrix'))';