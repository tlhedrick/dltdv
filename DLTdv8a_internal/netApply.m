function [xypts,quality]=netApply(img,net,netInfo,netType,numPts,minQ)

% function xypts=netApply(img,net,netInfo,netType,numPts)
%
% Apply deep learning networks to multiple images

for i=1:numel(img)
  [xypts(i,:),quality(i,:)]=getDetections(img{i},net(i),netInfo{i},netType(i),numPts(i),minQ);
end


function [xyp,quality] = getDetections(img,net,netInfo,netType,numPts,minQ)

% multi-cropping network
if netType==1
  
  % get cropscales
  try
    cropScales=repmat(max(netInfo.minCropSize),1,2);
  catch ME
    cropScales = [336 336]; % plausible default
  end
  
  % setup
  fun=@(block_struct)blockNet2(block_struct,net); % block processing function
  I2=[];
  I2max=[];
  if size(img,3)==1
    img=repmat(img,[1 1 3]);
  end
  
  for j=1:size(cropScales,1)
    I2{j}=blockproc(img,round(cropScales(j,:)/2),fun,'padpartialblocks',true,'bordersize',round(cropScales(j,:)/4)); % process image blocks
    I2{j}=I2{j}(1:size(img,1),1:size(img,2),:); % crop edges
    I2{j}=clearCorners(I2{j}); % remove detections at the image corners
    I2{j}=I2{j}.*repmat(I2{j}(:,:,size(I2{j},3))>minQ,[1 1 size(I2{j},3)]);
    I2max(:,j)=max(max(I2{j}));
  end
  bestScale=find(sum(I2max(1:end-1,:))==max(sum(I2max(1:end-1,:))));
  
  % combine scales by adding together the best response for each
  % individiual point
  foo=[];
  for i=1:size(I2max,1)
    idx=find(I2max(i,:)==max(I2max(i,:)));
    foo(:,:,i)=I2{idx(1)}(:,:,i);
  end
  fooSum=sum(foo,3);
  
  % get overall bounding box
  [m,n]=find(fooSum>minQ);
  
  % insufficient detections
  if numel(m)<2
    xyp(1,1:numPts*2)=0; % sparse null array
    quality(1,1:numPts)=0;
    return
  end
  
  %           % median method
  %           cp = round(median([n,m]));
  %           blockSize=max(round(std([n,m])));
  
  % bounding box method
  bb = [min(n) min(m) max(n) max(m)];
  cp = round([bb(1)+(bb(3)-bb(1))/2,bb(2)+(bb(4)-bb(2))/2]);
  blockSize = max(round([bb(4)-bb(2),bb(3)-bb(1)]/2));
  
  rx=round(1.5*[-blockSize blockSize-1])+cp(1); % basic
  % check borders
  if rx(1)<1
    rx=rx-rx(1)+1;
  end
  if rx(2)>size(img,2)
    rx=rx-rx(2)+size(img,2);
  end
  if rx(1)<1 % allow non-square shape if necessary
    rx(1)=1;
  end
  ry=round(1.5*[-blockSize blockSize-1])+cp(2); % basic
  % check borders
  if ry(1)<1
    ry=ry-ry(1)+1;
  end
  if ry(2)>size(img,1)
    ry=ry-ry(2)+size(img,1);
  end
  if ry(1)<1 % allow non-square shape if necessary
    ry(1)=1;
  end
  img2=img(ry(1):ry(2),rx(1):rx(2),:);
  img2r=imresize(img2,[224 224]);
  scaleFactor=size(img2,[1,2])./[224 224];
  
  % get real detections
  I3=predict(net,img2r);
  
  
  for j=1:numPts
    %
    %             % global best choice
    %             if I2max(j,bestScale)>minQ
    %               [m,n]=find(I2{bestScale(1)}(:,:,j)==max(I2max(j,bestScale)));
    %               xy=[n,m];
    %             else
    %               xy=[0,0]; % sparse array null
    %             end
    
    %             % local best choice
    %             if max(I2max(j,:))>minQ
    %               bestScale=find(I2max(j,:)==max(I2max(j,:)));
    %               [m,n]=find(I2{bestScale(1)}(:,:,j)==max(I2max(j,bestScale(1))));
    %               xy=sparse([n,m]);
    %             else
    %               xy=sparse([0,0]); % sparse array null
    %             end
    
    % using re-cropped image
    if max(max(I3(:,:,j)))>minQ
      [m,n]=find(I3(:,:,j)==max(max(I3(:,:,j))));
      xyp(1,j*2-1:j*2)=[n,m].*scaleFactor+[rx(1),ry(1)];
      quality(1,j)=max(max(I3(:,:,j)));
    else
      xyp(1,j*2-1:j*2)=[0,0]; % sparse null array
      quality(1,j)=0;
    end
  end
  
  % single-scale network
else
  % resize image and make color if necessary
  img1=imresize(img,[224 224]);
  if size(img1,3)==1
    img1=repmat(img1,[1 1 3]);
  end
  
  % predict
  netOut=predict(net,img1);
  
  % get points
  for j=1:size(netOut,3)-1
    
    % enforce global detection requirement
    netOut(:,:,j)=netOut(:,:,j).*(netOut(:,:,end)>minQ);
    
    maxQ=max(max(netOut(:,:,j)));
    if maxQ>minQ
      q=maxQ;
      [m,n]=find(netOut(:,:,j)==maxQ);
      xy=[n(1),m(1)]./[224 224].*size(img,[2 1]);
      
      % try for a weighted average
      try
        v=netOut(m-2:m+2,n-2:n+2,j); % net output, centered on xy
        [X,Y]=meshgrid(-2:2,-2:2);
        xy(1)=xy(1)+mean(mean(v.*X));
        xy(2)=xy(2)+mean(mean(v.*Y));
      catch
        xy=xy;
      end
      
    else
      xy=[0,0]; % empty sparse output
      q=0;
    end
    
    % add to all-points array
    xyp(1,j*2-1:j*2)=xy;
    quality(1,j)=q;
  end
  
  
  %         % single pass detection
%         if netType==2
%           
%           % resize and make color if necessary
%           img1=imresize(img,[224 224]);
%           if size(img1,3)==1
%             img1=repmat(img1,[1 1 3]);
%           end
%           
%           % predict
%           netOut=predict(net,img1);
%           
%           % detect
%           for j=1:numPts
%             netOut(:,:,j)=netOut(:,:,j).*(netOut(:,:,end)>minQ);
%             maxQ=max(max(netOut(:,:,j)));
%             if maxQ>minQ
%               [m,n]=find(netOut(:,:,j)==maxQ);
%               xy=[n(1),m(1)]./[224 224].*size(img,[2 1]);
%               
%               % try for a weighted average
%               try
%                 v=netOut(m-2:m+2,n-2:n+2,j); % net output, centered on xy
%                 [X,Y]=meshgrid(-2:2,-2:2);
%                 xy(1)=xy(1)+mean(mean(v.*X));
%                 xy(2)=xy(2)+mean(mean(v.*Y));
%               catch
%                 xy=xy;
%               end
%               
%             else
%               xy=[0,0]; % empty sparse output
%             end
  
end