function [tfOut] = netStopCheck(app,netState)

% Returns true (stop) or false (keep going) to halt deep learning network
% training operations.

drawnow % to let the gui update and us read the Halt button
if app.HaltTrainingButton.Value==1
  tfOut=true;
  disp('Detected stop signal')
else
  tfOut=false;
end


% print network state to console
fprintf('|%8d |%12d |                |% 13.2f |\n',netState.Epoch,netState.Iteration,netState.TrainingRMSE)