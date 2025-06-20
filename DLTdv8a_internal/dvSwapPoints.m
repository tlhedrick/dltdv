function [] = dvSwapPoints(app,sp,selection,numrng)

% function [] = dvSwapPoints(app,sp,selection,numrng)
%
% Data operations for swapping the array position of two points in DLTdv8a

xytmp = app.xypts;
dltpttmp = app.dltpts;
dltrestmp = app.dltres;
pntmp=app.pointNames;
minsp = min([sp,selection]);
maxsp = max([sp,selection]);
app.xypts(numrng(1):numrng(2),(1:2*app.nvid)+(minsp-1)*2*app.nvid)=xytmp(numrng(1):numrng(2),(1:2*app.nvid)+(maxsp-1)*2*app.nvid);
app.xypts(numrng(1):numrng(2),(1:2*app.nvid)+(maxsp-1)*2*app.nvid)=xytmp(numrng(1):numrng(2),(1:2*app.nvid)+(minsp-1)*2*app.nvid);

app.dltpts(numrng(1):numrng(2),minsp*3-2:minsp*3)=dltpttmp(numrng(1):numrng(2),maxsp*3-2:maxsp*3);
app.dltpts(numrng(1):numrng(2),maxsp*3-2:maxsp*3)=dltpttmp(numrng(1):numrng(2),minsp*3-2:minsp*3);

app.dltres(numrng(1):numrng(2),minsp)=dltrestmp(numrng(1):numrng(2),maxsp);
app.dltres(numrng(1):numrng(2),maxsp)=dltrestmp(numrng(1):numrng(2),minsp);

app.pointNames(minsp)=pntmp(maxsp);
app.pointNames(maxsp)=pntmp(minsp);