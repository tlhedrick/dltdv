classdef superMovieDatastore < matlab.io.Datastore
  
  % Implements a custom datastore that is a collection of movieDataStore4
  % objects; meant to be created immediately before use and not kept around
  % afterward
  
  properties (Access = private)
    CurrentFileIndex double
    FileSet matlab.io.datastore.DsFileSet % for compatibility only - this object does not use DsFileSet
    readCounter=0 % track the number of reads from this object
  end
  
  properties (SetAccess = private, GetAccess=public)
    minCropSize = [NaN]
    cropSize = [NaN]
    numPoints % total number of uv coordinate types (i.e. how many different points or landmarks)
    activePoints % list of the uv coordinate types to be returned
    availableData table % table listing all the available data (generated at initialization)
    subDataStores % cell array of the underlying movieDataStores
    subDataStoreSizes % array of the number of actual points in each underlying datastore
  end
  
  properties
    MiniBatchSize = 20 % number of images to return for a read
    DispatchInBackground = 0 % copied from patchDS - not sure what it does
  end
  
   methods % begin methods section
     
     % creation
     function mysds = superMovieDatastore(subDS)
       % function mysds = superMovieDatastore({movieDataStores})
       for i=1:numel(subDS)
         mysds.subDataStores{i}=subDS{i};
         mysds.subDataStoreSizes(i)=size(subDS{i}.availableData,1);
         numPoints(i)=subDS{i}.numPoints;
         minCropSize(i,:)=subDS{i}.minCropSize;
         cropSize(i,:)=subDS{i}.cropSize;
         activePoints{i}=subDS{i}.activePoints;
       end
       mysds.numPoints=median(numPoints); % should check for consistent settings
       mysds.minCropSize=max(minCropSize);
       mysds.cropSize=max(cropSize);
       mysds.activePoints=activePoints{1}; % should check for consistent settings
     end
     
     function tf = hasdata(mysds)
       % Return true if more data is available.
       % must sometimes return false to prevent an infinite loop during dnn
       % training initialization the number of reads required for a "false"
       % hasdata is not actually important since in most cases this
       % datastore operates with random augmentation turned on and each read
       % is in principle different from every other
       if mysds.readCounter>20
         tf=false;
       else
         tf=true;
       end
     end
     
     
     function [data,info] = read(mysds)
       % data will be a 2-column table of cells where each cell is a
       % 224x224x3 array of singles representing a scaled image. The table
       % will have MiniBatchSize rows. The first table column are the input
       % images and the second table column are the output images.  Output
       % images have one 3D layer for each input points and then a final
       % dimension that is the sum of the above dimensions.
       
       % just determine what underlying datastore to use and read from it
       foo=cumsum(mysds.subDataStoreSizes)./sum(mysds.subDataStoreSizes);
       r=rand(1);
       idx=find(r<=foo);
       [data,info] = mysds.subDataStores{idx(1)}.read();
       
       % increment the read counter, see myds.hasdata()
      mysds.readCounter=mysds.readCounter+1;

      % debug - check for nans
      for i=1:size(data,1)
          d=table2array(data(i,2));
          d2=d{:,:,1};
          if sum(sum(isnan(d2(:,:,1))))>0
              disp('SuperMovieDataStore: NaN found')
          end
      end
       
     end
     
     function reset(mysds)
       %disp('called reset')
       % Reset to the start of the data.
       reset(mysds.FileSet);
       mysds.CurrentFileIndex = 1;
       mysds.readCounter = 0;
     end
     
   end
  
end