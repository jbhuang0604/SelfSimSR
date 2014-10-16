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
%2013/2/22
%ReconstructHigh3 contains a back-projection. Other content is the same as ReconstructHigh.

function ReconstructHigh3( Para , img_input_y, IQLayer, Iter)
    zoom = Para.Zooming;
    LowEdge = Para.LowPatchSize;
    HighEdge = LowEdge * zoom;
    LowVectorLength = 4*LowEdge^2;
    
    TempFolder = Para.TempDataFolder;
    SaveName = Para.SaveName;
    
    LoadData = load(fullfile(TempFolder, [SaveName '_FeatureMatrix.mat']));
    LowFeature = LoadData.LowFeatureMatrix(1:LowVectorLength,:);
    CoordinateData = LoadData.LowFeatureMatrix(LowVectorLength+1:LowVectorLength+3,:);
    HighFeature = LoadData.HighFeatureMatrix;
    clear LoadData;
    
    DictionaryFileName = fullfile(TempFolder, [SaveName '_DlDh' num2str(Iter-1) '.mat']);
    LoadData = load( DictionaryFileName );
    D = LoadData.DlDh;
    clear LoadData
    
    %create the bb image
    ImgLow = img_input_y;
    bby = imresize(ImgLow,zoom,'bicubic');

    % bicubic interpolation for the other two channels
    ReconY = zeros(size(bby));
    NormalizeTable = zeros( size(ReconY) );
    
    %do group SR

    dimL = size(LowFeature,1);
    dimH = size(HighFeature,1);
    CombinedTable = [LowFeature/sqrt(dimL);HighFeature/sqrt(dimH)];        %for balancing Xl and Xh,
    Norm = sqrt(sum(CombinedTable.^2));
    
    CoefMatrixFileName = fullfile(TempFolder, [SaveName '_CoefMatrix_Iter' num2str(Iter) '.mat']);
    load( CoefMatrixFileName );

    OutXFull = D * CoefMatrix;
    BalancedXFull = OutXFull .* repmat(Norm ,dimL+dimH,1);
    BalancedXh = BalancedXFull(dimL+1:end,:);
    RawXh = BalancedXh .* sqrt(dimH);
    
    [Lrow, Lcol]= size(img_input_y);
    L0TotalPatchNum = (Lrow - 4 - (LowEdge-1) )*(Lcol - 4 - (LowEdge-1) );
    for i=1:L0TotalPatchNum
        hPatch = reshape( RawXh(:,i) , HighEdge, HighEdge);
        lowtop = CoordinateData(1,i);
        lowleft = CoordinateData(2,i);
        top = (lowtop-1)*zoom +1;
        left = (lowleft-1)*zoom +1;
        bottom = top + HighEdge - 1;
        right = left + HighEdge -1;
        bbPatch = bby(top:bottom,left:right);
        bbMean = mean(bbPatch(:));
        ReconPatch = hPatch + bbMean;
        ReconY(top:bottom,left:right) = ReconY(top:bottom,left:right) + ReconPatch;
        NormalizeTable(top:bottom,left:right) = NormalizeTable(top:bottom,left:right) + 1;
        if rem( i , floor(L0TotalPatchNum/20)) == 0
            fprintf('.');
        end
    end
    fprintf('\n');   
    
    ZeroArea = (NormalizeTable == 0);
    NormalizeTable(ZeroArea) = 1;
    hImy = ReconY ./NormalizeTable;
    %Copy boundary from bby to himy
    hImy(ZeroArea) = bby(ZeroArea);

    %insert a back projection here
    BackProjectionLoopNum = Para.BackProjectionLoopNum;     %I set default = 3 here
    Bk_GauVar = Para.B_GauVar *log(Para.Zooming) / (6*log(1.25));
    Img = hImy;       %initial value
    %imwrite(Img , fullfile(TempFolder, [SaveName '_Iter' num2str(Iter) '_BeforeBP.png'] ));
    clear hImy;
    for bkl = 1:BackProjectionLoopNum
        ConvResult = Convolute(Img, Bk_GauVar);
        DownSampling = imresize(ConvResult, [Lrow Lcol], 'bilinear');
        Diff = img_input_y - DownSampling;
        Up = imresize(Diff, Para.Zooming,'bilinear');
        final = Convolute(Up, Bk_GauVar);
        Img = Img + final;        
    end

    if ~isempty(IQLayer)
        EnlargedIQLayer = imresize(IQLayer , size(Img) );
        img_YIQ = Img;
        img_YIQ(:,:,2:3) = EnlargedIQLayer;
        img_rgb = YIQ2RGB(img_YIQ);
        imwrite(img_rgb , fullfile(TempFolder, [SaveName '_Iter' num2str(Iter) '.png'] ));
    else
        imwrite(Img , fullfile(TempFolder, [SaveName '_Iter' num2str(Iter) '.png'] ));
    end
end