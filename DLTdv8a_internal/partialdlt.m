function [m,b]=partialdlt(u,v,C1,C2)

% function [m,b]=partialdlt(u,v,C1,C2)
%
% partialdlt takes as inputs a set of X,Y coordinates from one camera view
% and the DLT coefficients for the view and one additional view.  It returns the
% line coefficients m & b for Y=mX+b in the 2nd camera view.  Under error-free
% DLT, the X,Y marker in the 2nd camera view must fall along the line given.
%
% Inputs:
%	 u = X coordinate in camera 1
%	 v = Y coordinate in camera 1
%	 C1 = the 11 dlt coefficients for camera 1
%	 C2 = the 11 dlt coefficients for camera 2
%
% Outputs:
%	 m = slope of the line in camera 2
%	 b = Y-intercept of the line in camera 2
%
% Ty Hedrick

% pick 2 random Z (actual values are not important)
z(1)=500;
z(2)=-500;

% for each Z predict x & y
for i=1:2
	Z=z(i);

	% new solution for y from MathCAD 11:
	y(i)= -(u*C1(9)*C1(7)*Z + u*C1(9)*C1(8) - u*C1(11)*Z*C1(5) -u*C1(5) ...
    + C1(1)*v*C1(11)*Z + C1(1)*v - C1(1)*C1(7)*Z - C1(1)*C1(8) - ...
    C1(3)*Z*v*C1(9) + C1(3)*Z*C1(5) - C1(4)*v*C1(9) + C1(4)*C1(5)) / ...
    (u*C1(9)*C1(6) - u*C1(10)*C1(5) + C1(1)*v*C1(10) - C1(1)*C1(6) - ...
    C1(2)*v*C1(9) + C1(2)*C1(5));
	
	Y=y(i);
	
	% get x
	x(i)= -(v*C1(10)*Y+v*C1(11)*Z+v-C1(6)*Y-C1(7)*Z-C1(8))/(v*C1(9)-C1(5));
end

% back the points into the cam2 X,Y domain
for i=1:2
	xy(i,:)=dlt_inverse(C2(:),[x(i),y(i),z(i)]);
end

% get a line equation back, y=mx+b
m=(xy(2,2)-xy(1,2))/(xy(2,1)-xy(1,1));
b=xy(1,2)-m*xy(1,1);