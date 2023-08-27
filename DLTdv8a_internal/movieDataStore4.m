classdef movieDataStore4 < matlab.io.Datastore
  
  % Implement a custom datastore to read movies for dnn training
  % see https://www.mathworks.com/help/matlab/import_export/develop-custom-datastore.html
  %
  % Ty Hedrick 2019-11-22
  
  properties (Access = private)
    CurrentFileIndex double
    FileSet matlab.io.datastore.DsFileSet % for compatibility only - this object does not use DsFileSet
    readers cell % videoReader objects
    readCounter double % track the number of reads from this object

  end
  
  properties (SetAccess = private, GetAccess=public)
    minCropSize = [NaN]
    cropSize = [NaN]
    creationDate
    numPoints % number of uv coordinate types (i.e. how many different points or landmarks)
    cached = false
    availableData table % table listing all the available data (generated at initialization)
    movieFiles
    backgrounds cell
    cache cell
    uvCoordinates cell % uv coordinates for pixel locations
    offsets cell % offsets for video files
    frameRateRatios cell % frame rate ratios for video files
  end
  
  properties
    MiniBatchSize = 20 % number of images to return for a read
    DispatchInBackground = 0 % copied from patchDS - not sure what it does
    AugmentData = true % perform augmentation (random rotation & crop) on reads
    createNegatives = false % create negative images with no points on 50% of reads
    name = '' % field for DLTdv8a
    description = '' % field for DLTdv8a
    crop = false % enable crop behavior (crop around a single point)
    cropAndResize = false % enable crop and resize (crop around multiple points)
    activePoints = [] % list of points to be returned
    groupPoints = false % group all the input points as a single output
  end
  
  
  methods % begin methods section
    
    function myds = movieDataStore4(movieFiles,uvCoordinates,varargin)
      
      % input parser
      p = inputParser;
      validCell = @(x) iscell(x);
      addRequired(p,'movieFiles',validCell);
      addRequired(p,'uvCoordinates',validCell);
      addParameter(p,'offsets',{},validCell);
      addParameter(p,'frameRateRatios',{},validCell);
      addParameter(p,'backgroundSources',{},validCell);
      addParameter(p,'cropAndResize',false);
      addParameter(p,'crop',false);
      addParameter(p,'AugmentData',true);
      
      parse(p,movieFiles,uvCoordinates,varargin{:});
      args=p.Results;
      
      if numel(uvCoordinates)>1&&args.crop==true
        disp('crop can only be set for a single input coordinate')
        return
      end
      
      % copy input arguments
      myds.AugmentData=args.AugmentData;
      myds.crop=args.crop;
      myds.cropAndResize=args.cropAndResize;
      myds.movieFiles=movieFiles;
   
      myds.uvCoordinates=args.uvCoordinates; % pixel coordinates of locations of interest
      myds.offsets=args.offsets; % offsets for multi-camera videography
      myds.frameRateRatios=args.frameRateRatios; % frame rate ratios for multi-camera videography
      
      % setup a table of valid video frames from all movies, this will be used later
      % to randomly select frames for myds.read()
      movie=[];
      frames=[];
      for i=1:numel(movieFiles)
        idx=find(sum(isfinite(uvCoordinates{i}(:,1:2:end)),2)>0); % rows with any coordinate present
        movie=[movie;idx*0+i];
        frames=[frames;idx];
      end
      myds.availableData=table(movie,frames);
      
      % populate readers with filenames (*.cine, *.mrf) or VideoReader objects (*mp4)
      for i=1:numel(movieFiles)
        [~,~,ext] = fileparts(movieFiles{i});
        if strcmpi(ext,'.mov') || strcmpi(ext,'.avi') || strcmpi(ext,'.mp4')
          % turn the filename into an videoreader object for videoreader
          % file types
          myds.readers{i}=VideoReader(movieFiles{i});
        else
          % just copy paths for other file types & hope for the best
          myds.readers{i}=movieFiles{i};
        end
      end
      
      % populate backgrounds array if called for [NEEDS WORK]
      bkg={};
      for i=1:numel(args.backgroundSources)
        [mov]=mediaRead2(args.backgroundSources{i},1);
        bkg{i}=double(mov.cdata);
      end
      myds.backgrounds=bkg;
      
      % determine bounding box for pixel coordinates (not necessary
      % anymore?)  Also, the calculations aren't right, should be done on a
      % per-movie basis in case the object position is different in
      % different movies
      uv=cat(1,uvCoordinates{:});
      minmax=[nanmin(uv(:,1:2:end),[],2),nanmax(uv(:,1:2:end),[],2),nanmin(uv(:,2:2:end),[],2),nanmax(uv(:,2:2:end),[],2)];
      mmd=[minmax(:,2)-minmax(:,1),minmax(:,4)-minmax(:,3)];
      myds.minCropSize=ceil(nanmax(mmd)); % crops smaller than this would miss at least one training image
      myds.cropSize=ceil(nanmax(nanmax(mmd)))*2;
      
      % set other initialization parameters
      myds.numPoints=size(uvCoordinates{1},2)/2;
      myds.activePoints=1:myds.numPoints;
      myds.creationDate=datestr(now);
      
      % init the FileSet for compatibility reasons, it isn't actually used
      myds.FileSet = matlab.io.datastore.DsFileSet(args.movieFiles,'FileExtensions',{'.cine','.cin','.mov','.mp4','.avi','.mrf'});
      myds.CurrentFileIndex = 1; % here for compatibility reasons, not actually used
      
      reset(myds); % call reset to clean up
    end
    
    function tf = hasdata(myds)
      % Return true if more data is available.
      % must sometimes return false to prevent an infinite loop during dnn 
      % training initialization the number of reads required for a "false" 
      % hasdata is not actually important since in most cases this
      % datastore operates with random augmentation turned on and each read
      % is in principle different from every other
      if myds.readCounter>20
        tf=false;
      else
        tf=true;
      end
    end
    
    function [data,info] = read(myds)
      % data will be a 2-column table of cells where each cell is a
      % 224x224x3 array of singles representing a scaled image. The table
      % will have MiniBatchSize rows. The first table column are the input
      % images and the second table column are the output images.  Output
      % images have one 3D layer for each input point and then a final
      % dimension that is the sum of the above dimensions.
      
      % figure out what type of read to do
      if myds.cropAndResize
        [data,info] = readCropAndResize(myds);
      elseif myds.crop
        [data,info] = readCrop(myds);
      else
        [data,info] = readNormal(myds);
      end
    end
    
    function [data,info] = readNormal(myds)
      % read whole images and resize them to the 224x224 dnn size
      
      % setup arrays to pack into the output table
      imOut={};
      imIn={};
      
      % get image backgrounds
      bkg=myds.backgrounds;
      
      % get a list of data to access
      if size(myds.availableData,1)>myds.MiniBatchSize
        % sample without replacement if possible
        s=randsample(1:size(myds.availableData,1),myds.MiniBatchSize);
      else
        % sample with replacement if necessary
        s=randsample(1:size(myds.availableData,1),myds.MiniBatchSize,true);
      end
      s=sort(s);
      cnt=1;
      for i=s
        % get the movie and frame to use
        m_id=myds.availableData.movie(i);
        frame=myds.availableData.frames(i);
        
        % read the source frame, subtract background if backgrounds exist,
        % and convert to a single
        if isempty(myds.cache)
          [img,fname]=mediaRead2(myds.readers{m_id},myds.offsets{m_id}+frame);
          img=img.cdata;
          if ischar(fname)==false && ischar(myds.readers{m_id})==true
            myds.readers{m_id}=fname;
          end
        else
          img=myds.cache{m_id,frame};
        end
        if isempty(bkg)==false
          img=double(img)-double(bkg{m_id});
        end
        img = single(img)/255; % scale to 0-1
        
        % get pixel coordinates (all locations of interest)
        uv = myds.uvCoordinates{m_id}(frame,:);
        uv = uv(:,sort([myds.activePoints*2-1,myds.activePoints*2]));
        
        % rotate image & coordinates
        if myds.AugmentData
          tform2=randomAffine2d('Rotation',[-100 100]); % full rotation
          imgr=imwarp(img,tform2);
          for k=1:numel(uv)/2 % for each location of interest
            uvr(k*2-1:k*2)=tform2.transformPointsForward(uv(k*2-1:k*2)-fliplr(size(img,1,2))/2)+fliplr(size(imgr,1,2))/2;
          end
        else % copy unrotated images to rotated image variable
          imgr=img;
          uvr=uv;
        end
        
        % create & store input image
        imgrr=imresize(imgr,[224 224]); % rotated and resized
        if size(imgrr,3)==1
          imgrr=repmat(imgrr,[1,1,3]); % input image must be 3D
        end
        imIn{cnt}=imgrr;
        
        % create output image
        % get pixel coordinates
        uvr2=round(uvr.*repmat([224 224]./(fliplr(size(imgr,1,2))),1,numel(uvr)/2));
        iOut=single(repmat(imgrr(:,:,1)*0,[1,1,numel(uvr2)/2])); % init output image
        for j=1:numel(uvr2)/2 % create gaussian map of location of interest
          if isfinite(sum(uvr2(j*2-1:j*2)))
            iOut(max(uvr2(j*2)-2,1):min(uvr2(j*2)+2,224),max(uvr2(j*2-1)-2,1):min(uvr2(j*2-1)+2,224),j)=1; % 5-pixel wide max probability square
            iOut(:,:,j)=imgaussfilt(iOut(:,:,j),2); % Gaussian blur
            iOut(:,:,j)=iOut(:,:,j)/(max(max(iOut(:,:,j)))); % re-normalize
          end
        end
        % add bottom summed layer to iOut
        iOut(:,:,end+1)=sum(iOut,3);

        % handle groupPoints input
        if myds.groupPoints==true
            iOut=repmat(iOut(:,:,end),[1 1 2]);
        end
        
        imOut{cnt}=iOut; % store
        cnt=cnt+1;
      end
      
      % pack images into a table
      data = table(imIn(:),imOut(:),'VariableNames',{'InputImage','ResponseImage'});
      
      % setup info output
      info = [];
      info.Size=myds.MiniBatchSize;
      
      % increment the read counter, see myds.hasdata()
      myds.readCounter=myds.readCounter+1;
    end
    
    function [data,info] = readCrop(myds)
      % function [data,info] = readCrop(myds)
      %
      % Read a 224x224 block from around the point of interest. Only
      % appropriate for a network tracking a single POI.
      
      % setup arrays to pack into the output table
      imOut={};
      imIn={};
      
      % get image backgrounds
      bkg=myds.backgrounds;
      
      % cropping block size
      blockSize=112;
      
      % get a list of data to access
      if size(myds.availableData,1)>myds.MiniBatchSize
        % sample without replacement if possible
        s=randsample(1:size(myds.availableData,1),myds.MiniBatchSize);
      else
        % sample with replacement if necessary
        s=randsample(1:size(myds.availableData,1),myds.MiniBatchSize,true);
      end
      
      s=sort(s);
      cnt=1;
      for i=s
        % get the movie and frame to use
        m_id=myds.availableData.movie(i);
        frame=myds.availableData.frames(i);
        
        % read the source frame, subtract background if backgrounds exist,
        % stretch contrast and convert to a single
        if isempty(myds.cache)
          [img,fname]=mediaRead2(myds.readers{m_id},myds.offsets{m_id}+frame);
          img=img.cdata;
          if ischar(fname)==false && ischar(myds.readers{m_id})==true
            myds.readers{m_id}=fname;
          end
        else
          img=myds.cache{m_id,frame};
        end
        if isempty(bkg)==false
          img=double(img)-double(bkg{m_id});
        end
        img = single(img)/255; % scale to 0-1
        
        % get pixel coordinates (all locations of interest)
        uv = myds.uvCoordinates{m_id}(frame,:);
        uv = uv(:,sort([myds.activePoints*2-1,myds.activePoints*2]));
        
        if numel(uv)>2 & myds.groupPoints==false
          disp('movieDataStore.crop is only appropriate for a single uv input')
          return
        end
        
        % rotate image & coordinates
        if myds.AugmentData
          tform2=randomAffine2d('Rotation',[-100 100]); % was [-90 90]
          imgr=imwarp(img,tform2);
          for k=1:numel(uv)/2 % for each location of interest
            uvr(k*2-1:k*2)=tform2.transformPointsForward(uv(k*2-1:k*2)-fliplr(size(img,1,2))/2)+fliplr(size(imgr,1,2))/2;
          end
        else
          imgr=img;
          uvr=uv;
        end
        
        % base image - crop - want a 224x224 block that includes the point of
        % interest and does not go outside the image. If AugmentData is
        % defined add a random perturbation to the image
        if myds.AugmentData
          % with random shift - range of allowable random shifts is +-
          % blockSize, set here as blockSize*0.8 to make some edge
          % allowances
          rx=[-blockSize blockSize-1]+round(uvr(1))+round(2*(rand(1)-0.5)*blockSize*0.8);
        else
          rx=[-blockSize blockSize-1]+round(uvr(1)); % basic
        end
        
        % check borders
        if rx(1)<1
          rx=rx-rx(1)+1;
        end
        if rx(2)>size(imgr,2)
          rx=rx-rx(2)+size(imgr,2);
        end
        
        % y-coordinate
        if myds.AugmentData
          ry=[-blockSize blockSize-1]+round(uvr(2))+round(2*(rand(1)-0.5)*blockSize*0.8); % with random shift
        else
          ry=[-blockSize blockSize-1]+round(uvr(2)); % basic
        end
        
        % check borders
        if ry(1)<1
          ry=ry-ry(1)+1;
        end
        if ry(2)>size(imgr,1)
          ry=ry-ry(2)+size(imgr,1);
        end
        
        % pull out image and new coordinates for setting the heat map
        % skip if we do not have any location data
        if isnan(sum(rx)) || isnan(sum(ry))
          continue
        end
        img2=imgr(ry(1):ry(2),rx(1):rx(2),:);
        uv2=round(uvr-repmat([rx(1),ry(1)],1,numel(uvr)/2));
        uv2(uv2<3)=NaN;
        uv2(uv2>(blockSize*2-3))=NaN;
        
        iOut=img2(:,:,1)*0;
        for uu=1:numel(uv2)/2
            try
                iOut(uv2(uu*2)-2:uv2(uu*2)+2,uv2(uu*2-1)-2:uv2(uu*2-1)+2)=1;
            catch
            end
        end
        iOut=imgaussfilt(iOut,2);
        iOut=single(iOut/(max(max(iOut))));
        
        if size(img2,3)==1
          imData{cnt}=repmat(img2,[1,1,3]);
        else
          imData{cnt}=img2;
        end
        outData{cnt}=repmat(iOut,[1,1,2]); % always 2d for the crop version
        cnt=cnt+1;
      end
      
      % pack images into a table
      data = table(imData(:),outData(:),'VariableNames',{'InputImage','ResponseImage'});
      
      % setup info output
      info = [];
      info.Size=myds.MiniBatchSize;
      
      % increment the read counter, see myds.hasdata()
      myds.readCounter=myds.readCounter+1;
      
    end
    
    function [data,info] = readCropAndResize(myds)
      % function [data,info] = readCropAndResize(myds)
      %
      % Read a limited region around the points and then resize it to the
      % 224x224 dnn size
      
      % for LAB color conversion
      %load rgb2lab_lookups.mat
      
      % setup arrays to pack into the output table
      imOut={};
      imData={};
      
      % get image backgrounds
      bkg=myds.backgrounds;
            
      cnt=1;
      while cnt<=myds.MiniBatchSize
        % get a random sample from available data
        i=randsample(1:size(myds.availableData,1),1);
        
        % get the movie and frame to use
        m_id=myds.availableData.movie(i);
        frame=myds.availableData.frames(i);
        
        % read the source frame, subtract background if backgrounds exist,
        % convert to a single
        if isempty(myds.cache)
          [img,fname]=mediaRead2(myds.readers{m_id},myds.offsets{m_id}+frame);
          img=img.cdata;
          if ischar(fname)==false && ischar(myds.readers{m_id})==true
            myds.readers{m_id}=fname;
          end
        else
          img=myds.cache{m_id,frame};
        end
        if isempty(bkg)==false
          img=double(img)-double(bkg{m_id});
        end
        
        % convert to L*A*B* colorspace [NOT HELPFUL THUS FAR IN TESTING]
        %img = single(rgb2lab_lookup(img,lc1,lc2,lc3));
        
        % scale to 0-1, no conversion
        img = single(img)/255; 
        
        % get pixel coordinates (all locations of interest)
        uv = myds.uvCoordinates{m_id}(frame,:);
        uv = uv(:,sort([myds.activePoints*2-1,myds.activePoints*2]));
        
        % rotate image & coordinates
        if myds.AugmentData
          tform2=randomAffine2d('Rotation',[-100 100]); % was [-90 90]
          imgr=imwarp(img,tform2);
          for k=1:numel(uv)/2 % for each location of interest
            uvr(k*2-1:k*2)=tform2.transformPointsForward(uv(k*2-1:k*2)-fliplr(size(img,1,2))/2)+fliplr(size(imgr,1,2))/2;
          end
        else
          imgr=img;
          uvr=uv;
        end
        
        % determine crop blocksize from current pixel bounding box
        minmax=[nanmin(uvr(:,1:2:end),[],2),nanmax(uvr(:,1:2:end),[],2),nanmin(uvr(:,2:2:end),[],2),nanmax(uvr(:,2:2:end),[],2)];
        mmd=[minmax(:,2)-minmax(:,1),minmax(:,4)-minmax(:,3)];
        blockSize=round(max([mmd,224])/2); % don't let the crop size drop below the native dnn size
        cp=round([minmax(1)+mmd(1)/2,minmax(3)+mmd(2)/2]); % current bounding box center
        
        % pick an alternate center with 50% probability if createNegatives
        % is true
        if myds.createNegatives & rand(1)>0.5
          cp=ceil(rand(1,2).*size(imgr,2,1)); % new random center
          makeFake=true;
        else
          makeFake=false;
        end
        
        % base image - crop - want a blocksize x blocksize block that is initially centered on
        % the average of the points of interest interest and does not go outside the image. If AugmentData is
        % defined add a random perturbation to the image.
        %
        % with random shift - range of allowable random shifts is +-
        % blockSize, set here as blockSize*0.3 to make some edge
        % allowances     
        if myds.AugmentData
          rx=round(1.5*[-blockSize blockSize-1])+cp(1)+round((rand(1)-0.5)*blockSize*0.6); % with random shift
        else
          rx=round(1.5*[-blockSize blockSize-1])+cp(1); % basic
        end
        
        % check borders
        if rx(1)<1
          rx=rx-rx(1)+1;
        end
        if rx(2)>size(imgr,2)
          rx=rx-rx(2)+size(imgr,2);
        end
        if rx(1)<1 % allow non-square shape if necessary
          rx(1)=1;
        end
        
        % y-coordinate
        if myds.AugmentData
          ry=round(1.5*[-blockSize blockSize-1])+cp(2)+round((rand(1)-0.5)*blockSize*0.6); % with random shift
        else
          ry=round(1.5*[-blockSize blockSize-1])+cp(2); % basic
        end
        
        % check borders
        if ry(1)<1
          ry=ry-ry(1)+1;
        end
        if ry(2)>size(imgr,1)
          ry=ry-ry(2)+size(imgr,1);
        end
        if ry(1)<1 % allow non-square shape if necessary
          ry(1)=1;
        end
        
        % pull out image and new coordinates for setting the heat map
        img2=imgr(ry(1):ry(2),rx(1):rx(2),:);
        uv2=round(uvr-repmat([rx(1),ry(1)],1,size(uvr,2)/2));
        
        % resize
        img2r=imresize(img2,[224 224]);
        uv2r=round(uv2.*repmat([224 224]./(fliplr(size(img2,1,2))),1,numel(uv2)/2));
        
        % check for edges that will be bad for training
        if sum(uv2r<0 & uv2r>-5)>0 | sum(uv2r<229 & uv2r>219)>0
          %disp('skipping an edge case')
          continue
        end
        
        iOut=single(repmat(img2r(:,:,1)*0,[1,1,numel(uv2r)/2])); % init output image
        for j=1:numel(uv2r)/2 % create gaussian map of location of interest
          if isfinite(sum(uv2r(j*2-1:j*2))) && uv2r(j*2-1)>2 && uv2r(j*2)>2 && uv2r(j*2-1)<size(img2r,2)-2 && uv2r(j*2)<size(img2r,1)-2
            
            iOut(uv2r(j*2)-2:uv2r(j*2)+2,uv2r(j*2-1)-2:uv2r(j*2-1)+2,j)=1; % 5-pixel wide max probability square
            iOut(:,:,j)=imgaussfilt(iOut(:,:,j),2); % Gaussian blur
            iOut(:,:,j)=iOut(:,:,j)/(max(max(iOut(:,:,j)))); % re-normalize
            
          end
        end
        % add bottom summed layer to iOut
        iOut(:,:,end+1)=sum(iOut,3);
        imOut{cnt}=iOut;
        
        % make sure the input image is color, or at least 3D
        if size(img2r,3)==1
          imData{cnt}=repmat(img2r,[1,1,3]);
        else
          imData{cnt}=img2r;
        end
        
        cnt=cnt+1;
      end
      
      % pack images into a table
      data = table(imData(:),imOut(:),'VariableNames',{'InputImage','ResponseImage'});
      
      % setup info output
      info = [];
      info.Size=myds.MiniBatchSize;
      info.cropSize=myds.cropSize;
      
      % increment the read counter, see myds.hasdata()
      myds.readCounter=myds.readCounter+1;
      
    end % end of readCropAndResize()
    
    function [img] = readByIndex(myds,movie,frame)
      % function [img] = readByIndex(myds,movie,frame)
      %
      % Read a specific frame from a specific movie, returned in as raw a
      % form as possible
      
      % check if this image is in the cache
      inCache=false;
      if isempty(myds.cache)==false
        if isempty(myds.cache{movie,frame})==false
          inCache=true;
          img=myds.cache{movie,frame};
        end
      end
      if inCache==false
        [img,fname]=mediaRead2(myds.readers{movie},myds.offsets{movie}+frame);
        img=img.cdata;
        if ischar(fname)==false && ischar(myds.readers{movie})==true
          myds.readers{movie}=fname;
        end
      end
      
    end
    
    function reset(myds)
      %disp('called reset')
      % Reset to the start of the data.
      reset(myds.FileSet);
      myds.CurrentFileIndex = 1;
      myds.readCounter = 0;
    end
    
    function out = getVariableNamesOfData(myds)
      % because patchDS has this method
      disp('called getVariableNamesOfData')
      out = {'InputImage','ResponseImage'};
    end
    
    function data = MyFileReader(fileInfoTbl)
      disp('MyFileReader is not implemented');
      data = [];
      %       % create a reader object using the FileName
      %       reader = matlab.io.datastore.DsFileReader(fileInfoTbl.FileName);
      %
      %       % seek to the offset
      %       seek(reader,fileInfoTbl.Offset,'Origin','start-of-file');
      %
      %       % read fileInfoTbl.SplitSize amount of data
      %       data = read(reader,fileInfoTbl.SplitSize);
    end
    
    function [] = buildCache(myds)
      % function [] = buildCache(myds)
      %
      % Load all the movie frames with image data into an array and store
      
      for i=1:size(myds.availableData,1)
        % get the movie and frame to use
        m_id=myds.availableData.movie(i);
        frame=myds.availableData.frames(i);
        
        % read the source frame & store in cache
        [img,fname]=mediaRead2(myds.readers{m_id},myds.offsets{m_id}+frame);
        if ischar(fname)==false && ischar(myds.readers{m_id})==true
          myds.readers{m_id}=fname;
        end
        myds.cache{m_id,frame}=img.cdata;
      end
      disp('Finished building image cache')
      myds.cached=true;
    end
    
    function [] = clearCache(myds)
      % function [] = clearCache(myds)
      %
      % Clears all images stored in the cache
      myds.cache={};
      myds.cached=false;
    end
    
    function [] = resetReaders(myds)
      % function [] = resetReaders(myds)
      %
      % Replaces objects in myds.readers{} with files & paths. This is
      % usually done in preparation for saving the datastore object to a
      % MAT file.
      for i=1:numel(myds.readers)
        if isobject(myds.readers{i})
          myds.readers{i}=[myds.readers{i}.Path,filesep,myds.readers{i}.Name];
        end
      end 
    end
    
    function [] = combine(otherds)
      % function [] = combine(otherds)
      %
      % Adds the data from otherDataStore (another movie datastore) to the
      % current datastore
      disp('Implemented superMovieDatastore instead')
    end
    
  end
end

function [mov,fname]=mediaRead2(fname,frame)

% function [mov,fname]=mediaRead2(fname,frame);
%
% Wrapper function which uses VideoReader, cineRead or mrfRead to
% grab an image from a video. Also puts the cdata result from
% cineRead into a mov.* structure.

if ischar(fname)
  [~,~,ext]=fileparts(fname);
  if strcmpi(ext,'.mov') || strcmpi(ext,'.avi') || strcmpi(ext,'.mp4')
    % turn the filename into an videoreader object for videoreader
    % file types
    fname=VideoReader(fname);
  end
end

if ischar(fname) % for mrf or cine files
  [~,~,ext]=fileparts(fname);
  
  if strcmpi(ext,'.cin') || strcmpi(ext,'.cine') % vision research cine
    mov.cdata=cineRead2(fname,frame);
  elseif strcmpi(ext,'.mrf') % IDT/Redlake multipage raw
    mov.cdata=mrfRead2(fname,frame);
  else
    mov=[];
    disp('mediaRead2: unknown file extension')
    return
  end
else % fname is not a char so it is a videoreader obj
  % check current time & don't seek to a new time if we don't need to
  ctime=fname.CurrentTime;
  ftime=(frame-1)*(1/fname.FrameRate); % start time of desired frame
  if abs(ctime-ftime)<0.90/fname.FrameRate % use 0.9 instead of 1 to avoid ambiguity near the end of a file
    % no need to seek
  else
    fname.CurrentTime=ftime;
  end
  mov.cdata=fname.readFrame;
end
end
