function [x,y,fit]=regionID4(app,prevRegion,prevXY,newData,gammaS)

% function [x,y,fit]=regionID4(app,prevRegion,prevXY,newData,gammaS)
%
% A cross-correlation based generalized image tracking program.
%
% Version history:
% 1.0 - Ty Hedrick, 3/5/2002 - initial release version
% 2.0 - Ty Hedrick, 10/02/2002 - updated to use the 2d corr. coefficient
% 3.0 - Ty Hedrick, 07/13/2004 - updated to use fft based cross-correlation
% 4.0 - Ty Hedrick, 12/10/2005 - updated to scale the image data by the
% gamma value specified in the UI and used to display the images

% set some other preliminary variables
xy=prevXY; % base level xy
ssize=floor(size(prevRegion,1)/2); % search area deviation

% grab a block of data from the newData image
try
  chunk=newData(xy(2)-ssize:xy(2)+ssize,xy(1)-ssize:xy(1)+ssize,:);
catch
  chunk=ones(ssize*2+1,ssize*2+1)*NaN;
end

% apply gamma and rescale (grayscale only)
if app.DisplayincolorCheckBox.Value==false
  prevRegion=prevRegion(:,:,1).^gammaS;
  prevRegion=prevRegion-min(min(prevRegion));
  prevRegion=prevRegion*(1/max(max(prevRegion)));
  chunk=chunk(:,:,1).^gammaS;
  chunk=chunk-min(min(chunk));
  chunk=chunk*(1/max(max(chunk)+1));
end

% estimate new pixel positions with a 2D cross correlation.  For color
% video, pick the result with the best signal to noise ratio
xc=zeros(size(chunk,1)*2-1,size(chunk,2)*2-1,size(chunk,3));
I=zeros(1,size(chunk,3));
J=I;
fit=I;

for i=1:size(chunk,3)
  % detrend the chunk and prevRegion so they better fit the assumptions of
  % the cross-correlation
  chunk(:,:,i)=rot90(detrend(rot90(detrend(chunk(:,:,i)))),-1);
  prevRegion(:,:,i)=rot90(detrend(rot90(detrend(prevRegion(:,:,i)))),-1);
  
  % calculate the cross-correlation matrix of the chunk to the previous
  % region
  xc(:,:,i) = conv2(chunk(:,:,i), fliplr(flipud(prevRegion(:,:,i))));
  xc_s=xc(:,:,i);
  
  % get the location of the peak
  [I(i),J(i)]=find(xc_s==max(xc_s(:)));
  
  % do sub-pixel interpolation
  [I(i),J(i)] = subPixPos(xc_s,I(i),J(i));
  
  % give signal-to-noise ratio as fit
  fit(i)=max(xc_s(:))/(sum(abs(xc_s(:)))/numel(xc_s)+0.001);
  
  % set fit to -1 if it is a NaN
  if isnan(fit(i))==1
    fit(i)=-1;
  end
end

% place in world coordinates
bestFit=find(fit==max(fit));
x=xy(1)+J(bestFit(1))-ssize*2-1;
y=xy(2)+I(bestFit(1))-ssize*2-1;

% single number fit for export
fit=max(fit);

function [x,y] = subPixPos(c,pi,pj)

% function [x,y] = subPixPos(c,pi,pj)
%
% Uses Matlab's 2D interpolation fuction to estimate a sub-pixel location
% of the peak in array c near pi,pj

% check to see that c is large enough for interpolation
if sum(size(c)<5)>0
  x=pi;
  y=pj;
  return
end

% subsample c near the peak
c2=c(pi-2:pi+2,pj-2:pj+2);

% interpolate
[xs,ys]=meshgrid(1:5,1:5);
[xm,ym]=meshgrid(1:.01:5,1:.01:5);
xc2=interp2(xs,ys,c2,xm,ym,'spline');

% find new peak
[i2,j2]=find(xc2==max(xc2(:)));

% convert back to pixel coordinates
x=xm(1,i2)-3+pi;
y=ym(j2,1)-3+pj;

