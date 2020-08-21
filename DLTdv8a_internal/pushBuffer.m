function [out] = pushBuffer(out,new,fill)

% function [out] = pushBuffer(old,new,fill)
%
% Pushes new data into a finite length 1d array or cell array, allowing the
% oldest data to drop out the back.  If fill is true all the buffer entries
% are set to the new value, if fill is false or undefined only the "top"
% entry is set to new.

if exist('fill','var')==false
  fill=false;
end

if fill==false
  if iscell(out)
    for i=numel(out)-1:-1:1
      out{i+1}=out{i};
    end
    out{1}=new;
  else
    for i=numel(out)-1:-1:1
      out(i+1)=out(i);
    end
    out(1)=new;
  end
else % fill = true
  if iscell(out)
    for i=numel(out):-1:1
      out{i}=new;
    end
  else
    for i=numel(out):-1:1
      out(i)=new;
    end
  end
end

end