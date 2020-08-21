function [data] = sparseRead(fname)

% function [data] = sparseRead(fname)
%
% Reads data in the format created by sparseSave

spSize=dlmread(fname,'\t',[1,0,1,2]);
data = spalloc(spSize(1),spSize(2),spSize(3));
try
  spData=dlmread(fname,'\t',2,0);
  spData(end+1,:)=[spSize(1:2),0]; % define bottom right corner so addition will work
catch
  spData=[spSize(1:2),0];
end
data=data+sparse(spData(:,1),spData(:,2),spData(:,3));