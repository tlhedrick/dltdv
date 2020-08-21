function [p,filtSys] = kalmanPredictorAcc(seq)

% function [p,filtSys] = kalmanPredictorAcc(seq)
%
% A multi-dimensional, velocity-based Kalman predictor
%
% Inputs: seq - a (:,n) columnwise matrix with n independent series of data
%   points sampled at a constant time step
%
% Outputs: p - a (1,n) vector of the predicted value(s) of seq in the next
%   time step
%
% Thanks for guidance in:
% The Kalman Filter toolbox by Kevin Murphy, available at:
% http://www.cs.ubc.ca/~murphyk/Software/index.html
%
% and also to the Kalman filter info at:
% http://www.cs.unc.edu/~welch/kalman/
%
% Ty Hedrick: Jan 27, 2007

% remove NaNs by spline interpolation
seq=dlt_splineInterp(seq,'spline');
seq(isnan(sum(seq,2))==true,:)=[];

% check data size & exit if inappropriate
if size(seq,1)<4
  p=seq(end,:); % give a reasonable p
  filtSys=seq; % return the unfiltered system
  return
end

% start setting up the Kalman predictor
nd = size(seq,2); % number of data columns
ss = nd*3; % system size (position, velocity & acc for each data column)

% build a system matrix of the appropriate size - because we're probably
% dealing with the x,y projection of x,y,z motion we can't construct a real
% system description.  However, the description below does a reasonable job
% for most 2D-projection tracking cases.
A=zeros(ss);
for i=1:nd
  A(i,i)=1;
  A(i,i+nd)=0;
  A(i+nd,i+nd)=1;
  A(i,i+nd*2)=2;
  A(i+nd*2,i+nd*2)=1;
  A(i+nd,i+nd*2)=1;
end

% build an observation matrix of the appropriate size
O=zeros(nd,ss);
for i=1:nd
  O(i,i)=1;
end

% build the system error covariance matrix
Q=1*eye(ss);

% build the data error covariance matrix
R=.1*eye(nd);

% initial system state
initSys=[seq(1,:),diff(seq(1:2,:),1),diff(diff(seq(1:3,:),1))];

% initial system covariance
initCov=0.01*eye(ss);

% use the Kalman filter to track the system state
[filtSys]=kFilt(seq,A,O,Q,R,initSys,initCov);

% create a prediction from the final system state
predSys = (A*(filtSys(end,:)'))';
p=predSys(1:nd);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% kFilt

function [filtSys] = kFilt(seq,A,O,Q,R,initSys,initCov)

% [filtSys] = kFilt(seq,A,O,Q,R,initSys,initCov)
%
% Inputs:
% seq(:,t) - the observed data at time t
% A - the system matrix
% O - the observation matrix
% Q - the system covariance
% R - the observation covariance
% initSys - the initial state vector
% initCov - the initial state covariance
%
% Outputs:
% filtSys - the estimation of the system state

[N,nd] = size(seq); % # of data points and number of data streams
ss = nd*3; % system size [again assuming position, velocity, acc]

% initalize output
filtSys = zeros(N,ss); % filtered system

% walk through the data, updating the filter as we go
%
% set initial values before the loop
predSys = initSys;
predCov = initCov;
for i=1:N
  
  e = seq(i,:) - (O*(predSys'))'; % error
  
  S = O*predCov*O' + R;
  Sinv = inv(S);
  
  K = predCov*O'*Sinv; % Kalman gain matrix
  
  prevSys = predSys + (K*(e'))'; % a oosteriori prediction of system state
  prevCov = (eye(ss) - K*O)*predCov; % a posteriori covariance
  
  predSys = (A*(prevSys'))'; % predict next system state
  predCov = A*prevCov*A' + Q; % predict next system covariance
  
  filtSys(i,:)=prevSys; % store the a posteriori prediction
end