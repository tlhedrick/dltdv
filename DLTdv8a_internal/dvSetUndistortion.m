function [] = dvSetUndistortion(varargin)

% function [] = dvSetUndistortion(varargin)
%
% Callback for the Set Undistortion button on DLTdv8 windows

cbo=varargin{1};
app=varargin{3};

videoNumber=getappdata(get(cbo,'parent'),'videoNumber');
% get the undistortion file
%[fc,pc]=uigetfile('*.mat',sprintf('Select the Camera%d UNDTFORM File - Cancel if none exists',videoNumber));
[fc,pc]=uigetfile({'*.mat;*profile.txt','MAT or profile.txt files';'*.*','All files'},...
    sprintf('Select the Camera%d UNDTFORM File - Cancel if none exists',2));

if isequal(fc,0)
  fprintf('Camera %d undistortion profile set to None\n',videoNumber);
  app.camd{videoNumber}=[];
  app.camud{videoNumber}=[];
  set(app.handles{425+videoNumber},'String','Undistortion file: none');
elseif strcmpi(fc(end-2:end),'mat') % mat file
    try
        % load the file
        load([pc,fc],'camd','camud');
        app.camd{videoNumber}=camd;
        app.camud{videoNumber}=camud;
        fprintf('Loaded undistortion transform matrix for camera%d.\n',videoNumber);
        set(app.handles{425+videoNumber},'String',['Undistortion file: ',fc]);
    catch
        fprintf('Failed to load camd and camud variables from MAT-file %s\n',fc)
    end
elseif strcmpi(fc(end-2:end),'txt') % txt file
    p=importdata([pc,fc]);

    % sanity checks
    if size(p,2)<8
        fprintf('%s has too few columns to be a camera profile\n',fc);
        return
    end
    if size(p,2)<12
        fprintf('camera profile %s specifies no distortion parameters\n',fc)
        return
    end
    if size(p,2)>12
        fprintf('camera profile %s does not appear to specify a radial-tangential pinhole distortion model.\n',fc)
        return
    end

    if size(p,1)==1 % assume just this camera
        [camud,camd] = create_Tforms([p(2),p(2)],p(5:6),p(8:12),p(3:4));
        app.camd{videoNumber}=camd;
        app.camud{videoNumber}=camud;
        fprintf('Generated undistortion profile for camera %d from file %s\n',videoNumber,fc)
        set(app.handles{425+videoNumber},'String',['Undistortion file: ',fc]);
    elseif size(p,1)==app.nvid % assume all cameras
        fprintf('Detected a camera profile with information for all cameras\n')
        for i=1:size(p,1)
            [camud,camd] = create_Tforms([p(i,2),p(i,2)],p(i,5:6),p(i,8:12),p(i,3:4));
            app.camd{i}=camd;
            app.camud{i}=camud;
            fprintf('Generated undistortion profile for camera %d from row %d of file %s\n',i,i,fc)
            set(app.handles{425+i},'String',['Undistortion file: ',fc]);
        end
    else
        fprintf('The camera profile file %s has the wrong number of rows.\n',fc)
    end
end

fullRedraw(app);