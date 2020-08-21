function [iCoefs] = dlt_invert(coefs,heights)

% function [coefs] = dlt_invert(coefs,heights)
%
% Inverts the implicit vertical coordinate in the DLT coefficients to
% switch from old Hedrick style coefficients with the image origin in the
% lower left to coefficients appropriate for data with the image origin in
% the lower left.

for i=1:size(coefs,2) % for each column
  iCoefs(:,i)=cFlip(coefs(:,i),heights(i));
end

end

function [out] = cFlip(in,height)

% identity matrix with extra column for compatibility with 4x4 transforms
m=[eye(3),[0;0;0]];

% decompose original DLT
[xyz,T,ypr,Uo,Vo,Z] = DLTcameraPosition(in);

% camera intrinsics
K=[Z,0,Uo;0,Z,Vo-height;0,0,1];

% camera extrinsics
R = T(1:3,1:3);
tv = T(4,1:3)*R;

% camera rotations + translation as a 4x4 transform matrix
P1=[R',tv'];
P1e=[P1;[0,0,0,1]];

coefsraw=K*m*P1e;
coefs=reshape(coefsraw',12,1);

out=coefs(1:11,1)./coefs(end);
out([1:3,8:11])=out([1:3,8:11])*-1; % fix signs

end

function [xyz,T,ypr,Uo,Vo,Z] = DLTcameraPosition(coefs)

% function [xyz,T,ypr,Uo,Vo,Z] = DLTcameraPosition(coefs)
%
% Computes the camera position in the calibration frame coordinate system.
% This is useful because it allows you to recreate the scene perceived by
% the camera in a 3D modeling and animation program such as Maya.
%
% Inputs: coefs - the 11 DLT coefficients for the camera in question
%
% Outputs: xyz - the camera position in calibration frame XYZ space
%          T   - the 4x4 transformation matrix for camera position and
%                orientation
%          ypr - Yaw,Pitch,Roll angles in degrees (Maya compatible)
%          Uo - perceived image center along the camera width axis
%          Vo - perceived image center along the camera height axis
%          Z - distance from camera to image plane
%
% For detailed notes on recreating a scene in Maya see the accompanying
% file "DLTtoMaya.rtf"
%
% Note regarding Maya compatibility: The anges in ypr should be copied into
% the Maya Transform Attributes:Rotate cells in the order in which they
% appear in ypr.  The Rotate Order should be set to xyz.
%
% Ty Hedrick, Feb. 2nd, 2007

m1=[coefs(1),coefs(2),coefs(3);coefs(5),coefs(6),coefs(7); ...
  coefs(9),coefs(10),coefs(11)];
m2=[-coefs(4);-coefs(8);-1];

xyz=inv(m1)*m2;

D=(1/(coefs(9)^2+coefs(10)^2+coefs(11)^2))^0.5;
D=D(1); % + solution

Uo=(D^2)*(coefs(1)*coefs(9)+coefs(2)*coefs(10)+coefs(3)*coefs(11));
Vo=(D^2)*(coefs(5)*coefs(9)+coefs(6)*coefs(10)+coefs(7)*coefs(11));

du = (((Uo*coefs(9)-coefs(1))^2 + (Uo*coefs(10)-coefs(2))^2 + (Uo*coefs(11)-coefs(3))^2)*D^2)^0.5;
dv = (((Vo*coefs(9)-coefs(5))^2 + (Vo*coefs(10)-coefs(6))^2 + (Vo*coefs(11)-coefs(7))^2)*D^2)^0.5;

du=du(1); % + values
dv=dv(1); 
Z=-1*mean([du,dv]); % there should be only a tiny difference between du & dv

T3=D*[(Uo*coefs(9)-coefs(1))/du ,(Uo*coefs(10)-coefs(2))/du ,(Uo*coefs(11)-coefs(3))/du ; ...
  (Vo*coefs(9)-coefs(5))/dv ,(Vo*coefs(10)-coefs(6))/dv ,(Vo*coefs(11)-coefs(7))/dv ; ...
  coefs(9) , coefs(10), coefs(11)];

dT3=det(T3);

if dT3 < 0
  T3=-1*T3;
end

T=inv(T3);
T(:,4)=[0;0;0];
T(4,:)=[xyz(1),xyz(2),xyz(3),1];

% compute YPR from T3
%
% Note that the axes of the DLT based transformation matrix are rarely
% orthogonal, so these angles are only an approximation of the correct
% transformation matrix
alpha=atan2(T(2,1),T(1,1));
beta=atan2(-T(3,1), (T(3,2)^2+T(3,3)^2)^0.5);
gamma=atan2(T(3,2),T(3,3));

% disabled for dlt_invert internal version since it doesn't seem to
% represent any loss in quality
%
% % check for orthogonal transforms by back-calculating one of the matrix
% % elements
% if abs(cos(alpha)*cos(beta)-T(1,1)) > 1e-8
%   disp('Warning - the transformation matrix represents transformation about')
%   disp('non-orthogonal axes and cannot be represented as a roll, pitch & yaw')
%   disp('series with 100% accuracy.')
% end

ypr=rad2deg([gamma,beta,alpha]);

end
