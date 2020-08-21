function [] = tsWWtext(varargin)

app=varargin{3};

s=str2num(get(app.handles{602},'string'));
if isempty(s) || s<1 || s>size(app.xypts,1)
  s=size(app.xypts,1);
end
s=round(s);
set(app.handles{602},'string',num2str(s));
pt=sp2full(app.xypts(round(app.FrameNumberSlider.Value),(app.lastvnum*2-1:app.lastvnum*2)+(app.sp-1)*2*app.nvid));
quickRedraw(app,app.handles,app.sp,round(app.FrameNumberSlider.Value));

end