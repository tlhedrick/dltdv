function [] = sparseSave(fname,title,data)

% function [] = sparseSave(fname,title,data)
%
% Saves sparse data out in a tab separated text file in the format of
% [I,J,V]=find(data); with 1st line of title and filename including path of
% fname.

f1=fopen(fname,'w');
fprintf(f1,'%s\n',title);
fprintf(f1,'%d\t%d\t%d\n',size(data,1),size(data,2),nnz(data));
[I,J,V]=find(data);
for i=1:numel(I)
  fprintf(f1,'%d\t%d\t%.6f\n',I(i),J(i),V(i));
end
fclose(f1);