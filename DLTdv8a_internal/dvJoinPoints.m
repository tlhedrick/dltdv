function [] = dvJoinPoints(app,sp,spD)

% function [] = dvJoinPoints(app,sp,spD)
%
% Data operations for joining points in DLTdv8a

% extract arrays and use nanmean to combine
m = sp2full(app.xypts(:,(1:2*app.nvid)+(sp-1)*2*app.nvid));
m(:,:,2) = sp2full(app.xypts(:,(1:2*app.nvid)+(spD-1)*2*app.nvid));
m=inanmean(m,3);
m(isnan(m))=0;
app.xypts(:,(1:2*app.nvid)+(sp-1)*2*app.nvid)=m;

% delete old points
app.xypts(:,(1:2*app.nvid)+(spD-1)*2*app.nvid)=[];
app.dltpts(:,spD*3-2:spD*3)=[];
app.dltres(:,spD)=[];
app.pointNames(spD);

app.numpts=app.numpts-1; % update number of points

% update the drop-down menu
ptstring={};
for i=1:app.numpts
  ptstring(i)=app.pointNames(i);
end
app.CurrentpointDropDown.ItemsData=1:app.numpts;
app.CurrentpointDropDown.Items=ptstring;
app.CurrentpointDropDown.Value=sp;
app.sp=sp;

% Compute 3D coordinates + residuals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if app.dlt
  %added dedistortion (Baier 1/16/06) (modified Hedrick 6/23/08)
  udist=m;
  udist(udist==0)=NaN;
  for j=1:size(udist,2)/2
    if isempty(app.camud{j})==false
      udist(:,j*2-1:j*2)=applyTform(app.camud{j},udist(:,j*2-1:j*2));
    end
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  [rawResults,rawRes]=dlt_reconstruct_v2(app.dltcoef,udist);
  app.dltpts(:,sp*3-2:sp*3)=full2sp(rawResults(:,1:3));
  app.dltres(:,sp)=full2sp(rawRes);
end