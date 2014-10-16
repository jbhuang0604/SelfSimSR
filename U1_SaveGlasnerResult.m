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

function U1_SaveGlasnerResult(AllLayers,Para, IQLayer)
    if Para.Zooming == 3
        LayerIdx_I0 = 6;
        BuildLayerNum = 5;
    elseif Para.Zooming == 4
        LayerIdx_I0 = 8;
        BuildLayerNum = 7;
    else
        error('scaling factor not supported');
    end
    img_input_y = AllLayers(LayerIdx_I0).GridAsHighLayer;

    HighImage = AllLayers(1).GridAsHighLayer;    %this if only for y channel
    [input_h, input_w] = size(img_input_y);
    ExactHeight = input_h * Para.Zooming;
    ExactWidth = input_w * Para.Zooming;
    Scale = AllLayers(1).TrueHeight / ExactHeight;
    GauVar = Para.B_GauVar * log(Scale) /( BuildLayerNum * log(1.25));
    ExactY = GenerateSubSampleImage(HighImage, ExactHeight, ExactWidth , Scale, GauVar);

    if ~isempty(IQLayer)
        %restore the color information
        IQLayer_high = imresize(IQLayer, [ExactHeight ExactWidth]);
        ReconYIQ = ExactY;
        ReconYIQ(:,:,2:3) = IQLayer_high;
        ReconRGB = YIQ2RGB(ReconYIQ);
        OutputImage = ReconRGB;
    else
        OutputImage = ExactY;
    end

    SaveFileName = fullfile(Para.TempDataFolder, [Para.SaveName '_Glasner.png']);
    imwrite( OutputImage , SaveFileName );
end