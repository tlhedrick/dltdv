function [camud, camd] = create_Tforms(f,c,k,res,name)
% function [camud camd] = create_Tforms(f,c,k,res,name)
%
% Create forward and reverse tforms for intrinsic camera parameters:
% f: [1x2] focal lengths (equal if aspect ratio = 1)
% c: [1x2] principal points (should be set to pixel coords. of the center
%   of the image
% k: [1x5] undistortion coordinates determined by calibration toolbox -
%   must correspond with the focal length!
% res: image resolution [horiz vertical]
% name: filename to use in saving the tforms

% 2021-12-03: added fitgeotrans() if available

% Get window resolution
nc = res(1); nr = res(2);

% Create mesh grid for interpolation points
[mx,my] = meshgrid(1:10:nc, 1:10:nr);
px = reshape(mx',numel(mx),1);
py = reshape(my',numel(my),1);
cp = [px py];

% Apply undistort transform
T.tdata = [f,c,k,3];
imp = undistort_Tform(cp,T);

% Local weighted mean: 1
% Choose some control points and the corresponding image points
points = ceil(numel(px)*rand(1000,1));
points = unique(sort(points));
cpnonlinear = cp(points,:);
impnonlinear = imp(points,:);
% Use cp2tform to find local weighted mean approx. of the inverse transform
if exist('fitgeotrans','file')==2
    camd = fitgeotrans(cpnonlinear,impnonlinear,'lwm',15);
else
    camd = cp2tform(cpnonlinear,impnonlinear,'lwm',15);
end

% Create reverse Tform from undistort_Tform.m
camud = maketform('custom',2,2,[],@undistort_Tform,T.tdata);

% Save Tforms to file
if exist('name','var')==1
    save(name,'camd','camud');
end

function [uvdd] = undistort_Tform(uv,T)

% function [uvdd] = undistort_Tform(uv,T)
%
% inputs:
%  uv - array of pixel coordinates, distorted
%  T.tdata(1:2) - focal length
%  T.tdata(3:4) - principal point
%  T.tdata(5:9) - nonlinear distortion coefficients
%  T.tdata(10) - number of interations
%
% outputs:
%  uvdd - array of pixel coordinates, undistorted
%
% Iteratively applies undistortion coefficients to estimate undistorted
% pixel coordinates from observation of distorted pixel coordinates. This
% version setup for use with MATLAB's tform routines

% break out packed variables
tdata = T.tdata;
f = mean(tdata(1:2));
UoVo = tdata(3:4);
nlin = tdata(5:9);
niter = tdata(10);

% create normalized points from pixel coordinates
uvn = (uv - repmat(UoVo,size(uv,1),1))./f;

uvnd = uvn;

% undistort (niter iterations)
for i=1:niter
  r2=rnorm(uvnd).^2; % square of the radius
  rad = 1 + nlin(1)*r2 + nlin(2)*r2.^2 + nlin(5)*r2.^3; % radial distortion
  
  % tangential distortion
  tan = [2*nlin(3).*uvnd(:,1).*uvnd(:,2) + nlin(4)*(r2 + 2*uvnd(:,1).^2)];
  tan(:,2) = nlin(3)*(r2 + 2*uvnd(:,2).^2) + 2*nlin(4).*uvnd(:,1).*uvnd(:,2);
  
  uvnd = (uvn - tan)./repmat(rad,1,2);
end

% restore pixel coordinates
uvdd = uvnd*f + repmat(UoVo,size(uv,1),1);