function [] = tsRedraw(varargin)

% redraw the time-series window
app=varargin{3};
quickRedraw(app,app.handles,app.sp,round(app.FrameNumberSlider.Value));