function [out] = sp2full(in)

% function [out] = sp2full(in)
%
% Converts a sparse matrix to the DLTdv full matrix representation, i.e.
% zeros become NaNs
out=full(in);
out(out==0)=NaN;