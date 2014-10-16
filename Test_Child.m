%   Copyright 2010 Chih-Yuan Yang, Jia-Bin Huang, and Ming-Hsuan Yang
%
%   Licensed under the Apache License, Version 2.0 (the "License");
%   you may not use this file except in compliance with the License.
%   You may obtain a copy of the License at
%
%       http://www.apache.org/licenses/LICENSE-2.0
%
%   Unless required by applicable law or agreed to in writing, software
%   distributed under the License is distributed on an "AS IS" BASIS,
%   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%   See the License for the specific language governing permissions and
%   limitations under the License.
%Chih-Yuan Yang, EECS, UC Merced
%2013/2/23
%for release v1.1

clc
clear
Para.B_GauVar = 1.0;
Para.nn = 1;
Para.SSD_Sigma = 12.5;
Para.Zooming = 4;
Para.SaveName = 'Child';
Para.SourceFile = fullfile('Source','Child_input.png');
Para.TempDataFolder = fullfile('TempData', Para.SaveName);
Para.BackProjectionLoopNum = 3;
Para.ReconPixelOverlap = 4;     %0: noisy looks like texture, 1: smoother than 0, 2:more 4: similar to 2, changes little. suggest 2
%Create the tempfolder
if ~exist(Para.TempDataFolder,'dir')
    mkdir(Para.TempDataFolder);
end

inputimage = im2double(imread( Para.SourceFile ));

ChannelNumber = size( inputimage , 3);
if ChannelNumber == 3
    img_yiq = RGB2YIQ(inputimage);
    img_y = img_yiq(:,:,1);
    IQLayer = img_yiq(:,:,2:3);
elseif ChannelNumber == 1
    img_y = inputimage;
    IQLayer = [];
end

AllLayers = F1_GenerateAllLayersByGlasnerMethod(img_y,Para.Zooming,Para.B_GauVar,Para.ReconPixelOverlap,Para.TempDataFolder,Para.nn,Para.SSD_Sigma,Para.BackProjectionLoopNum);
U1_SaveGlasnerResult(AllLayers, Para, IQLayer);

%The parameters of our algorithm
Para.BaseSigma =  0.125;      %if the number is larger, the group sparsity will be stronger
Para.IterNumForGroupSparseCoding = 500;
Para.DictionarySize = 1024;
Para.LowPatchSize = 3;
Para.IterNumStart = 1;
Para.IterNumEnd = 7;
Para.AvgSignalNumPerCluster = 30;    
Para.ClusterPerPoint = 60;
S1_ExploitGroupSparcityToGenerateOutputImage;
