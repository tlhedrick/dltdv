function [I] = chex(n,p,q)

% draw a checkerboard

bs = zeros(n);
ws = ones(n);
twobytwo = [bs ws; ws bs];
I = repmat(twobytwo,p,q);