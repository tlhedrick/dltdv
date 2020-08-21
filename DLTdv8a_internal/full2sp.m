function [out] = full2sp(in)

% function [out] = full2sp(in)
%
% Converts a full matrix in the DLTdv matrix representation to sparse, i.e.
% NaNs become zeros
in(isnan(in))=0;
out=sparse(in);
