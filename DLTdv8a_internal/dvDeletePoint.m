function [] = dvDeletePoint(app,sp)

% function [] = dvDeletePoint(app,sp)
%
% Deletes point sp from app DLTdv8a

% update number of points
app.numpts=app.numpts-1;

% update point names
app.pointNames(sp)=[];

% update points pull-down menu
ptstring={};
for i=1:app.numpts
  ptstring(i)=app.pointNames(i);
end
app.CurrentpointDropDown.ItemsData=1:app.numpts;
app.CurrentpointDropDown.Items=ptstring;
app.CurrentpointDropDown.Value=max([1,sp-1]);
app.sp=max([1,sp-1]);

% update the data matrices by removing the deleted point
app.xypts(:,(1:2*app.nvid)+(sp-1)*2*app.nvid)=[];
app.dltpts(:,sp*3-2:sp*3)=[];
app.dltres(:,sp)=[];