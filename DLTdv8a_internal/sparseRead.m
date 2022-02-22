function [data] = sparseRead(fname,delimiter)

% function [data] = sparseRead(fname,delimiter)
%
% Reads data in the format created by sparseSave
%
% Delimiter - defaults to tab ('\t')

if nargin==1
  delimiter='\t';
end

spSize=dlmread(fname,delimiter,[1,0,1,2]);
data = spalloc(spSize(1),spSize(2),spSize(3));
try
  spData=dlmread(fname,delimiter,2,0);
  spData(end+1,:)=[spSize(1:2),0]; % define bottom right corner so addition will work
catch
  spData=[spSize(1:2),0];
end
data=data+sparse(spData(:,1),spData(:,2),spData(:,3));