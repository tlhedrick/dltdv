function [imOut] = blockNet2(block_struct,net)

% function [imOut] = blockNet2(block_struct,net)
%
% function for block-processing an image with a dnn

% % recipe:
% img1=mds2.readByIndex(1,722); % read an image
% img1=single(img1/255); % scale to 0-1
% img1=repmat(img1,[1 1 3]); % make 3D
% fun=@(block_struct)blockNet2(block_struct,net5); % setup function
% I2=blockproc(img1,repmat(mds2.cropSize,1,2),fun,'padpartialblocks',true); % process image blocks
% I2=I2(1:size(img,1),1:size(img,2),:); % crop edges

% resize image for network
img=imresize(block_struct.data,[224 224]);

% figure
% imagesc(img)
% title(num2str(block_struct.location))

% predict
imOut=predict(net,img);

% resize output
imOut=imresize(imOut,size(block_struct.data,1,2));
