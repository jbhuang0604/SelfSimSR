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
%02/22/2013

function AllLayers2 = F1_GenerateAllLayersByGlasnerMethod(img_y, Zooming, B_GauVar,ReconPixelOverlap,...
    TempDataFolder,nn,SSD_Sigma,BackProjectionLoopNum)
    if Zooming == 4
        BuildLayerNum = 7;
    elseif Zooming == 3
        BuildLayerNum = 5;
    end

    ScalePerLayer = 1.25;
    L0.INumber = 0;
    L0.TrueWidth = size(img_y,2);
    L0.TrueHeight = size(img_y,1);
    L0.FormatWidth = L0.TrueWidth;
    L0.FormatHeight = L0.TrueHeight;
    L0.ValidWidth = L0.TrueWidth;
    L0.ValidHeight = L0.TrueHeight;
    L0.Conv = img_y;
    L0.GridAsHighLayer = img_y;
    L0.PatchRecordTable = [];

    ExSmall = 10^-12;
    %CreateSubLayer
    SubLayers(6,1) = struct('INumber', 0 , 'TrueWidth', 0 , 'TrueHeight' , 0 , 'FormatWidth' , 0 , 'FormatHeight' , 0 , ...
        'ValidWidth' , 0 , 'ValidHeight' , 0, 'Conv' ,[] , 'GridAsHighLayer' , [] , 'PatchRecordTable' , []);
    for i=1:6     %I only need the I-1~I-5, I-6 is unnecessary, only Con-6 is necessary
        Bk_GauVar = B_GauVar * i / 6;
        SubLayers(i,1).INumber = -i;
        SubLayers(i,1).TrueWidth = L0.TrueWidth / ScalePerLayer^i;
        SubLayers(i,1).TrueHeight = L0.TrueHeight / ScalePerLayer^i;
        SubLayers(i,1).FormatWidth = ceil( SubLayers(i,1).TrueWidth );
        SubLayers(i,1).FormatHeight = ceil( SubLayers(i,1).TrueHeight );
        SubLayers(i,1).ValidWidth = floor( SubLayers(i,1).TrueWidth );
        SubLayers(i,1).ValidHeight = floor( SubLayers(i,1).TrueHeight );
        SubLayers(i,1).Conv = Convolute(img_y, Bk_GauVar );
        %Home-made subsampling, unable to use Matlab build-in imresize
        Conv = SubLayers(i,1).Conv;
        FormatHeight = SubLayers(i).FormatHeight;
        FormatWidth = SubLayers(i).FormatWidth;
        ValidHeight = SubLayers(i).ValidHeight;
        ValidWidth = SubLayers(i).ValidWidth;
        TrueHeight = SubLayers(i).TrueHeight;
        TrueWidth = SubLayers(i).TrueWidth;
        Ratio = ScalePerLayer ^ i;
        Grid = zeros(FormatHeight , FormatWidth);
        [HighHeight HighWidth] = size(Conv);
        %Do grid subsampling high-res to low-res. Current case: high is integer res, but low is non-integer res.
        for low_r=1:FormatHeight   %if the TureHeight is not integer, the last low_r will be floor(TrueHeight)=ValidHeight, but now I need it reaches FormatHeight
            HighTop = (low_r-1) * Ratio;
            r1 = floor(HighTop) + 1;   
            if low_r <= ValidHeight
                HighBottom = HighTop + Ratio;
                r2 = floor(HighBottom-ExSmall) + 1;
                Ratio_r = Ratio;
                bBoundaryCase_r = false;
            elseif ValidHeight ~= FormatHeight
                HighBottom = HighHeight;
                r2 = HighHeight;                
                Ratio_r = HighBottom - HighTop;
                bBoundaryCase_r = true;                
            end

            for low_c=1:FormatWidth
                fprintf('Generate SubLayers INumber:%d low_r:%d low_c:%d\n' , i , low_r , low_c);            
                HighLeft = (low_c-1) * Ratio;
                c1 = floor(HighLeft) + 1;
                if low_c <= ValidWidth
                    HighRight = HighLeft + Ratio;
                    c2 = floor(HighRight-ExSmall) + 1;
                    Ratio_c = Ratio;
                    bBoundaryCase_c = false;
                elseif ValidWidth ~= FormatWidth
                    HighRight = HighWidth;
                    c2 = HighWidth;
                    Ratio_c = HighRight - HighLeft;
                    bBoundaryCase_c = true;
                end

                %for 4 corners
                Portion = (ceil(HighTop+ExSmall) - HighTop) * (ceil(HighLeft+ExSmall)-HighLeft);
                Sum = Conv(r1,c1) * Portion;     %TopLeft
                if r1<r2
                    Portion = (HighBottom - floor(HighBottom-ExSmall)) * (ceil(HighLeft+ExSmall)-HighLeft);
                    Sum = Sum + Conv(r2,c1) * Portion;   %BottomLeft
                end
                if c1<c2
                    Portion = (ceil(HighTop+ExSmall) - HighTop) * (HighRight-floor(HighRight-ExSmall));
                    Sum = Sum + Conv(r1,c2) * Portion;   %TopRight
                end
                if r1<r2 && c1<c2
                    Portion = (HighBottom - floor(HighBottom-ExSmall)) * (HighRight-floor(HighRight-ExSmall));
                    Sum = Sum + Conv(r2,c2) * Portion;   %BottomRight
                end

                %for 4 edge
                if c1+1 < c2   %for left edge exclusive top-left and bottom-left
                    PortionTop = ceil(HighTop+ExSmall) - HighTop;
                    for c = c1+1:c2-1
                        Sum = Sum + Conv(r1,c)*PortionTop;      
                    end
                    if ~bBoundaryCase_r
                        PortionBottom = HighBottom - floor(HighBottom-ExSmall);
                        for c = c1+1:c2-1
                            Sum = Sum + Conv(r2,c)*PortionBottom;      
                        end
                    end
                end

                if r1+1 < r2
                    PortionLeft = ceil(HighLeft+ExSmall) - HighLeft;
                    for r = r1+1:r2-1
                        Sum = Sum + Conv(r,c1)*PortionLeft;
                    end
                    if ~bBoundaryCase_c
                        PortionRight = HighRight - floor(HighRight-ExSmall);
                        for r = r1+1:r2-1
                            Sum = Sum + Conv(r,c2)*PortionRight;
                        end
                    end
                end

                %for interior pixels
                if bBoundaryCase_c
                    if r1+1<r2 && c1+1<=c2
                        for r=r1+1:r2-1
                            for c=c1+1:c2
                                Sum = Sum + Conv(r,c);
                            end
                        end
                    end
                elseif bBoundaryCase_r
                    if r1+1<=r2 && c1+1<c2
                        for r=r1+1:r2
                            for c=c1+1:c2-1
                                Sum = Sum + Conv(r,c);
                            end
                        end
                    end
                elseif r1+1<r2 && c1+1<c2
                    for r=r1+1:r2-1
                        for c=c1+1:c2-1
                            Sum = Sum + Conv(r,c);
                        end
                    end
                end
                PixelValue = Sum / (Ratio_r * Ratio_c);
                Grid(low_r,low_c) = PixelValue;                
            end
        end

        SubLayers(i).GridAsHighLayer = Grid;
    end
    clear Conv
    %Dump Layers for debug
%    if DbgPrintOutSubLayers
%        for i=1:5
%            INumber = SubLayers(i).INumber;
%            SaveFileName = [Para.TempDataFolder 'Lower_INumber' num2str(INumber) '.png'];
%            imwrite( SubLayers(i).GridAsHighLayer / 256 , SaveFileName );
%        end
%    end
    clear AllLayers HighTop HighLeft
    AllLayers = [L0; SubLayers];

    %Build the PatchRecordTable From Con-1 to Con-6
    for i = 1:6
        HighLayer = AllLayers(i);
        LowLayer = AllLayers(i+1);          %to get the Conv
        HighHeight = HighLayer.ValidHeight;
        HighWidth = HighLayer.ValidWidth;
        PatchNum = (HighHeight-4) * (HighWidth-4);
        INumber = HighLayer.INumber;             %this INumber indicates the INumber of HighLayer
        clear PatchRecordTable
        PatchRecordTable(PatchNum,1) = struct( 'Vector' , zeros(16,1) , 'HighPatch5x5_r' , 0 , 'HighPatch5x5_c' , 0 , 'HighPatch5x5_INumber' , 0);       %16 is the low patchsize, 3 for the corresponding high-res location (INumber,top,left)
        idx = 0;
        Scale = ScalePerLayer^(i-1);      %the Scale mean the res of Con0 to Con-i
        Conv = LowLayer.Conv;
        for r=1:HighHeight-4
            for c=1:HighWidth-4
                fprintf('Build Sub Conv'' PatchRecordTable INumber:%d r:%d c:%d\n' , INumber , r , c);  
                %Compute the grid of low
                LowPatch = zeros(4);
                for lowridx = 1:4
                    Top = (r-1 + 1.25 * (lowridx-1)) * Scale;         %the coordinate in Conv layer, 1.25 is the shift in the high-res cooredinate
                    Bottom = Top + 1.25 * Scale;
                    r1 = floor(Top) + 1;                        %r1 means rstart      %the pixel index in ConvLayer
                    r2 = floor(Bottom-ExSmall)+1;               %r2 means rend
                    for lowcidx = 1:4
                        Left = (c-1 + 1.25 * (lowcidx-1)) * Scale;
                        Right = Left + 1.25 * Scale;
                        c1 = floor(Left) + 1;                   %c1 means cstart
                        c2 = floor(Right-ExSmall) + 1;          %c2 means cend

                        %Compute the sum of the range
                        Portion = (ceil(Top+ExSmall) - Top) * (ceil(Left+ExSmall)-Left);
                        Sum = Conv(r1,c1) * Portion;     %TopLeft
                        Portion = (ceil(Top+ExSmall) - Top) * (Right-floor(Right-ExSmall));
                        Sum = Sum + Conv(r1,c2) * Portion;   %TopRight
                        Portion = (Bottom - floor(Bottom-ExSmall)) * (ceil(Left+ExSmall)-Left);
                        Sum = Sum + Conv(r2,c1) * Portion;   %BottomLeft
                        Portion = (Bottom - floor(Bottom-ExSmall)) * (Right-floor(Right-ExSmall));
                        Sum = Sum + Conv(r2,c2) * Portion;   %BottomRight
                        %for 4 edge
                        if c1+1 ~= c2
                            PortionTop = ceil(Top+ExSmall) - Top;
                            PortionBottom = Bottom - floor(Bottom-ExSmall);
                            for c3 = c1+1:c2-1
                                Sum = Sum + Conv(r1,c3)*PortionTop;      
                                Sum = Sum + Conv(r2,c3)*PortionBottom;      
                            end
                        end
                        if r1+1 ~= r2
                            PortionLeft = ceil(Left+ExSmall) - Left;
                            PortionRight = Right - floor(Right-ExSmall);
                            for r3 = r1+1:r2-1
                                Sum = Sum + Conv(r3,c1)*PortionLeft;
                                Sum = Sum + Conv(r3,c2)*PortionRight;
                            end
                        end
                        %for interior pixels
                        if r1+1<r2 && c1+1<c2
                            for r3=r1+1:r2-1
                                for c3=c1+1:c2-1
                                    Sum = Sum + Conv(r3,c3);
                                end
                            end
                        end
                        LowPatch(lowridx,lowcidx) = Sum / (1.25*Scale)^2;       %becuase we map 1.25*Scale x 1.25*Scale pixels into a pixel
                    end
                end
                %save the vector and r,c,i
                idx = idx + 1;
                PatchRecordTable(idx).HighPatch5x5_r = r;
                PatchRecordTable(idx).HighPatch5x5_c = c;
                PatchRecordTable(idx).HighPatch5x5_INumber = INumber;
                PatchRecordTable(idx).Vector = reshape(LowPatch, 16,1);           %here is the bug, the value of LowPatch is too high 
            end   %end of for c=1:HighWidth-4
        end
        %save PatchRecordTable
        AllLayers(i+1).PatchRecordTable = PatchRecordTable;
    end
    clear i INumber  %prevent bug

    for BuildINumber = 1:BuildLayerNum
        %Add an imagine layer to be reconstructed.
        BuildLayer.INumber = BuildINumber;
        BuildLayer.TrueWidth = L0.TrueWidth * ScalePerLayer^BuildINumber;
        BuildLayer.TrueHeight = L0.TrueHeight * ScalePerLayer^BuildINumber;
        BuildLayer.FormatWidth = ceil(BuildLayer.TrueWidth);
        BuildLayer.FormatHeight = ceil(BuildLayer.TrueHeight);
        BuildLayer.ValidWidth = floor(BuildLayer.TrueWidth);
        BuildLayer.ValidHeight = floor(BuildLayer.TrueHeight);
        BuildLayer.Conv = [];
        BuildLayer.GridAsHighLayer = [];
        BuildLayer.PatchRecordTable = [];

        %Build PatchRecordTable for ANN Query
        HighHeight = BuildLayer.FormatHeight;
        HighWidth = BuildLayer.FormatWidth;
        Overlap = ReconPixelOverlap;
        rArray = 1:5-Overlap:HighHeight-4;
        if rArray(end) ~= HighHeight-4
            rArray = [1:5-Overlap:HighHeight-4 HighHeight-4];       %the last patch has to be done
        end
        cArray = 1:5-Overlap:HighWidth-4;
        if cArray(end) ~= HighWidth-4
            cArray = [1:5-Overlap:HighWidth-4 HighWidth-4];
        end

        LowLayer = AllLayers(1);
        %extend LowLayer_Grid by right 1 pixel and left 1 pixel for HighToLow Mapping
        h = LowLayer.FormatHeight;
        w = LowLayer.FormatWidth;
        LowerLayer_Grid = zeros( h + 1, w +1);
        LowerLayer_Grid(1:h, 1:w) = LowLayer.Conv;
        LowerLayer_Grid(1:h, w+1) = LowerLayer_Grid(1:h, w); %copy the last column to the extended
        LowerLayer_Grid(h+1, 1:w) = LowerLayer_Grid(h,1:w);  %copy the last row to the extended
        LowerLayer_Grid(h+1, w+1) = LowerLayer_Grid(h,w);    %copy the right-bottom corner
        idx = 0;

        %run whole image for database
        PatchNum = (HighHeight-4) * (HighWidth-4);
        INumber = BuildINumber;
        clear PatchRecordTable
        PatchRecordTable(PatchNum,1) = struct( 'Vector' , zeros(16,1) , 'HighPatch5x5_r' , 0 , 'HighPatch5x5_c' , 0 , 'HighPatch5x5_INumber' , 0);       %16 is the low patchsize, 3 for the corresponding high-res location (INumber,top,left)
        for ridx=1:HighHeight-4
            r = ridx;
            for cidx=1:HighWidth-4
                c = cidx;
                fprintf('Build whole 4x4 patches for database INumber:%d r:%d c:%d\n' , INumber , r , c);
                %Compute the grid of low
                HighTop = r-1;
                HighLeft = c-1;
                LowTop = HighTop / ScalePerLayer;
                LowLeft = HighLeft / ScalePerLayer;
                r1 = floor(LowTop) + 1;
                c1 = floor(LowLeft) + 1;
                %compute the corresponding 4x4 grid in low-res patch
                if floor(LowTop) == LowTop   %it is just an integer
                    TopPortion = 1;
                else
                    TopPortion = ceil(LowTop) - LowTop;
                end
                if floor(LowLeft) == LowLeft
                    LeftPortion = 1;
                else
                    LeftPortion = ceil(LowLeft) - LowLeft;
                end 
                BottomPortion = 1 - TopPortion;
                RightPortion = 1 - LeftPortion;
                if TopPortion ~= 1 && LeftPortion ~= 1
                    TopLeftPortion = TopPortion * LeftPortion;
                    TopRightPortion = TopPortion * RightPortion;
                    BottomLeftPortion = BottomPortion * LeftPortion;
                    BottomRightPortion = BottomPortion * RightPortion;
                    TopLeftContribution     = LowerLayer_Grid(r1  :r1+3,c1  :c1+3) * TopLeftPortion;
                    TopRightContribution    = LowerLayer_Grid(r1  :r1+3,c1+1:c1+4) * TopRightPortion;
                    BottomLeftContribution  = LowerLayer_Grid(r1+1:r1+4,c1  :c1+3) * BottomLeftPortion;
                    BottomRightContribution = LowerLayer_Grid(r1+1:r1+4,c1+1:c1+4) * BottomRightPortion;
                    LowPatch = TopLeftContribution + TopRightContribution + BottomLeftContribution + BottomRightContribution;
                elseif TopPortion ~= 1 && LeftPortion == 1     %up and bottom
                    TopContribution     = LowerLayer_Grid(r1  :r1+3,c1:c1+3) * TopPortion;
                    BottomContribution  = LowerLayer_Grid(r1+1:r1+4,c1:c1+3) * BottomPortion;
                    LowPatch = TopContribution + BottomContribution;
                elseif TopPortion == 1 && LeftPortion ~= 1     %left and right
                    LeftContribution   = LowerLayer_Grid(r1:r1+3,c1  :c1+3) * LeftPortion;
                    RightContribution  = LowerLayer_Grid(r1:r1+3,c1+1:c1+4) * RightPortion;
                    LowPatch = LeftContribution + RightContribution;
                else
                    LowPatch = LowerLayer_Grid(r1:r1+3,c1:c1+3);
                end
                %save the vector and r,c,i
                idx = idx + 1;
                PatchRecordTable(idx).HighPatch5x5_r = r;
                PatchRecordTable(idx).HighPatch5x5_c = c;
                PatchRecordTable(idx).HighPatch5x5_INumber = INumber;
                PatchRecordTable(idx).Vector = reshape(LowPatch, 16,1);            
            end   %end of for c=1:HighWidth-4
        end
        AllLayers(1).PatchRecordTable = PatchRecordTable;

        %run part of the patch for reconstruction
        PatchNum = length(rArray) * length(cArray);
        clear PatchRecordTable
        idx = 0;
        PatchRecordTable(PatchNum,1) = struct( 'Vector' , zeros(16,1) , 'HighPatch5x5_r' , 0 , 'HighPatch5x5_c' , 0 , 'HighPatch5x5_INumber' , 0);       %16 is the low patchsize, 3 for the corresponding high-res location (INumber,top,left)
        for ridx=1:length(rArray)
            r = rArray(ridx);
            for cidx=1:length(cArray)
                c = cArray(cidx);
                fprintf('Build ANN source data BuildINumber:%d r:%d c:%d\n' , INumber , r , c);
                %Compute the grid of low
                HighTop = r-1;
                HighLeft = c-1;
                LowTop = HighTop / ScalePerLayer;
                LowLeft = HighLeft / ScalePerLayer;
                r1 = floor(LowTop) + 1;
                c1 = floor(LowLeft) + 1;
                %compute the corresponding 4x4 grid in low-res patch
                if floor(LowTop) == LowTop   %it is just an integer
                    TopPortion = 1;
                else
                    TopPortion = ceil(LowTop) - LowTop;
                end
                if floor(LowLeft) == LowLeft
                    LeftPortion = 1;
                else
                    LeftPortion = ceil(LowLeft) - LowLeft;
                end 
                BottomPortion = 1 - TopPortion;
                RightPortion = 1 - LeftPortion;
                if TopPortion ~= 1 && LeftPortion ~= 1
                    TopLeftPortion = TopPortion * LeftPortion;
                    TopRightPortion = TopPortion * RightPortion;
                    BottomLeftPortion = BottomPortion * LeftPortion;
                    BottomRightPortion = BottomPortion * RightPortion;
                    TopLeftContribution     = LowerLayer_Grid(r1  :r1+3,c1  :c1+3) * TopLeftPortion;
                    TopRightContribution    = LowerLayer_Grid(r1  :r1+3,c1+1:c1+4) * TopRightPortion;
                    BottomLeftContribution  = LowerLayer_Grid(r1+1:r1+4,c1  :c1+3) * BottomLeftPortion;
                    BottomRightContribution = LowerLayer_Grid(r1+1:r1+4,c1+1:c1+4) * BottomRightPortion;
                    LowPatch = TopLeftContribution + TopRightContribution + BottomLeftContribution + BottomRightContribution;
                elseif TopPortion ~= 1 && LeftPortion == 1     %up and bottom
                    TopContribution     = LowerLayer_Grid(r1  :r1+3,c1:c1+3) * TopPortion;
                    BottomContribution  = LowerLayer_Grid(r1+1:r1+4,c1:c1+3) * BottomPortion;
                    LowPatch = TopContribution + BottomContribution;
                elseif TopPortion == 1 && LeftPortion ~= 1     %left and right
                    LeftContribution   = LowerLayer_Grid(r1:r1+3,c1  :c1+3) * LeftPortion;
                    RightContribution  = LowerLayer_Grid(r1:r1+3,c1+1:c1+4) * RightPortion;
                    LowPatch = LeftContribution + RightContribution;
                else
                    LowPatch = LowerLayer_Grid(r1:r1+3,c1:c1+3);
                end
                %save the vector and r,c,i
                idx = idx + 1;
                PatchRecordTable(idx).HighPatch5x5_r = r;
                PatchRecordTable(idx).HighPatch5x5_c = c;
                PatchRecordTable(idx).HighPatch5x5_INumber = INumber;
                PatchRecordTable(idx).Vector = reshape(LowPatch, 16,1);            
            end   %end of for c=1:HighWidth-4
        end
    %    AllLayers(1).PatchRecordTable = PatchRecordTable;

        %2 Dump to text for ANN query
        %2.1 Extract the data for source, which means the High_Layer is L1 and the Low_Layer is L0
        BuildLayerPatchNumber = length( PatchRecordTable );
        AnnSource = zeros(16,BuildLayerPatchNumber);
        for i=1:BuildLayerPatchNumber
            AnnSource(:,i) = PatchRecordTable(i).Vector;            
        end
        SaveFileName = fullfile(TempDataFolder, 'AnnSource.txt');
        dlmwrite( SaveFileName , AnnSource' , ' ');
        clear AnnSource SaveFileName

        %2.2 Get ANN search pool from stored data
        TotalPatchNum = 0;       %this is the overall PatchNum
        AvailableLayerNum = length(AllLayers)-1;
        for i=1:AvailableLayerNum
            PatchNumForALayer = length(AllLayers(i+1).PatchRecordTable);
            TotalPatchNum = TotalPatchNum + PatchNumForALayer;
        end
        %Record all patches for ANN searching pool
        clear PatchRecordTable
        PatchRecordTable(TotalPatchNum,1) = struct( 'Vector' , zeros(16,1) , 'HighPatch5x5_r' , 0 , 'HighPatch5x5_c' , 0 , 'HighPatch5x5_INumber' , 0);       %16 is the low patchsize, 3 for the corresponding high-res location (INumber,top,left)

        idx = 1;
        %Collect all available PatchRecords
        for i=1:AvailableLayerNum
            PatchNumForALayer = length(AllLayers(i+1).PatchRecordTable);
            PatchRecordTable(idx:idx+PatchNumForALayer-1) = AllLayers(i+1).PatchRecordTable;
            idx = idx + PatchNumForALayer;
        end

        AnnSearchPoolNumber = length(PatchRecordTable);
        AnnSearchPool = zeros(16,AnnSearchPoolNumber);
        for i=1:AnnSearchPoolNumber
            AnnSearchPool(:,i) = PatchRecordTable(i).Vector;
        end
        SaveFileName = fullfile(TempDataFolder, 'AnnSearchPool.txt');
        dlmwrite( SaveFileName , AnnSearchPool' , ' ');
        clear AnnSearchPool SaveFileName

        %2.3 Do Ann 
        DataFileName = fullfile(TempDataFolder, 'AnnSearchPool.txt');
        Data = dlmread(DataFileName);
        MaxInstance = size(Data,1);
        clear Data
        currentfolder = pwd;
        if ispc
            AnnPath = fullfile('Lib','Ann_Windows');
        elseif isunix
            AnnPath = fullfile('Lib','Ann_Linux');
        end
        cd( AnnPath );
        Dim = 16;
        QueryFileName = fullfile(currentfolder, TempDataFolder, 'AnnSource.txt');
        DataFileName = fullfile(currentfolder, TempDataFolder, 'AnnSearchPool.txt');
        OutputFileName = fullfile(currentfolder, TempDataFolder, 'AnnResult.txt');
        fprintf('Doing ANN\n');
        if ispc
            ExecString = ['ann_sample.exe -d ' num2str(Dim) ' -max ' num2str(MaxInstance) ' -nn ' num2str(nn) ' -df ' DataFileName ' -qf ' QueryFileName ' -sa ' OutputFileName ];
            [s, w] = dos( ExecString );
        elseif isunix
            ExecString = ['./ann_sample -d ' num2str(Dim) ' -max ' num2str(MaxInstance) ' -nn ' num2str(nn) ' -df ' DataFileName ' -qf ' QueryFileName ' -sa ' OutputFileName ];
            [s, w] = system( ExecString );
        end
        cd( currentfolder);

        %2.4 Convert Ann Result to Mapping Table
        AnnResultFileName = fullfile(TempDataFolder, 'AnnResult.txt');
        AnnResult = dlmread( AnnResultFileName , ',' );
        PatchNum = size(AnnResult,1);
        col = size( AnnResult ,2);
        nn = (col - 1)/2;
        clear PatchMappingTable
        fprintf('Buidling PatchMappingTable\n');
        PatchMappingTable(PatchNum,nn) = struct( 'HighPatch5x5_INumber' , 0 , 'HighPatch5x5_r' , 0 , 'HighPatch5x5_c' , 0 , 'Diff' , 0);
        for idx = 1:PatchNum
            for i=1:nn
                ColPosition = i*2;
                IndexInPatchRecordTable = AnnResult( idx , ColPosition ) + 1;        %+1 because ANN result start from 0
                AnnDiff = AnnResult( idx , ColPosition+1 );
                INumber = PatchRecordTable(IndexInPatchRecordTable).HighPatch5x5_INumber;
                r = PatchRecordTable(IndexInPatchRecordTable).HighPatch5x5_r;
                c = PatchRecordTable(IndexInPatchRecordTable).HighPatch5x5_c;
                PatchMappingTable(idx,i).HighPatch5x5_INumber = INumber;
                PatchMappingTable(idx,i).HighPatch5x5_r = r;
                PatchMappingTable(idx,i).HighPatch5x5_c = c;
                PatchMappingTable(idx,i).Diff = AnnDiff;
            end
        end

        %delete Ann files, they are too fat for BSD300
        delete(fullfile(TempDataFolder, 'AnnResult.txt'));
        delete(fullfile(TempDataFolder, 'AnnSearchPool.txt'));
        delete(fullfile(TempDataFolder, 'AnnSource.txt'));

        %Compute the corresponding high 5x5 patch by exp(-SSD/sigma)
        ImageSum = zeros(BuildLayer.FormatHeight,BuildLayer.FormatWidth);
        ImageWeight = zeros(BuildLayer.FormatHeight,BuildLayer.FormatWidth);
        sigma = SSD_Sigma;
        idx = 0;
        for ridx=1:length(rArray)
            r = rArray(ridx);
            for cidx=1:length(cArray)
                c = cArray(cidx);
                fprintf('Computing the built high-res patch r:%d c:%d\n',r,c);
                idx = idx +1;
                PatchSum = zeros(5);
                WeightSum = 0;
                for n=1:nn
                    INumber = PatchMappingTable(idx,n).HighPatch5x5_INumber;
                    Found_r = PatchMappingTable(idx,n).HighPatch5x5_r;
                    Found_c = PatchMappingTable(idx,n).HighPatch5x5_c;
                    Diff = PatchMappingTable(idx,n).Diff;
                    Weight = exp(-Diff/sigma);
                    Patch = AllLayers(-INumber+BuildINumber).GridAsHighLayer(Found_r:Found_r+4,Found_c:Found_c+4);
                    %insert 2 lines
                    ImageSum(r:r+4,c:c+4) = ImageSum(r:r+4,c:c+4) + Weight*Patch;%BuiltPatch{r,c};
                    ImageWeight(r:r+4,c:c+4) = ImageWeight(r:r+4,c:c+4) + Weight;%ones(5);
                end
            end
        end

        %Generate the AverageImage for back-projection
        AverageImage = ImageSum ./ImageWeight;

        %Dump the AverageImage for debuging data before back-projection
        %if Para.DbgPrintOutBeforeBackProjectionImage
        %    SaveFileName = [Para.TempDataFolder 'BuildINumber' num2str(BuildINumber) 'BeforeBackProjection.png'];
        %    imwrite( AverageImage/255 , SaveFileName );
        %end

        %do back-projection here
        Bk_GauVar = B_GauVar * BuildINumber / 6;
        Img = AverageImage;       %initial value
        for bkl = 1:BackProjectionLoopNum
            ConvResult = Convolute(Img, Bk_GauVar);
            %There is a small problem. L0 is the full rage, but BuildLayer's valid range, there might be some remaining in the last pixel. How to solve this problem?
            %I need a hand-made downsampling here, key point: the high-res image is not integer imagee
            HighImage = ConvResult;
            HighHeight = BuildLayer.TrueHeight; %maybe not integer
            HighWidth = BuildLayer.TrueWidth;
            LowHeight = L0.TrueHeight;          %must be integer
            LowWidth = L0.TrueWidth;
            LowFormatHeight = L0.FormatHeight;
            LowFormatWidth = L0.FormatWidth;
            LowImage = zeros(LowFormatHeight, LowFormatWidth);
            ScaleH = HighHeight / LowHeight;
            ScaleW = HighWidth / LowWidth;
            for r=1:floor(LowHeight)        %r, c is the low res image index
                Top = (r-1) * ScaleH;
                Bottom = Top + ScaleH;
                r1 = floor(Top) + 1;
                r2 = floor(Bottom-ExSmall) + 1;
                for c=1:floor(LowWidth)
                    Left = (c-1) * ScaleW;
                    Right = Left + ScaleW;
                    c1 = floor(Left) + 1;
                    c2 = floor(Right-ExSmall) + 1;
                    %for 4 corners
                    Portion = (ceil(Top+ExSmall) - Top) * (ceil(Left+ExSmall)-Left);
                    Sum = HighImage(r1,c1) * Portion;     %TopLeft
                    Portion = (ceil(Top+ExSmall) - Top) * (Right-floor(Right-ExSmall));
                    Sum = Sum + HighImage(r1,c2) * Portion;   %TopRight
                    Portion = (Bottom - floor(Bottom-ExSmall)) * (ceil(Left+ExSmall)-Left);
                    Sum = Sum + HighImage(r2,c1) * Portion;   %BottomLeft
                    Portion = (Bottom - floor(Bottom-ExSmall)) * (Right-floor(Right-ExSmall));
                    Sum = Sum + HighImage(r2,c2) * Portion;   %BottomRight
                    %for 4 edge
                    if c1+1 ~= c2
                        PortionTop = ceil(Top+ExSmall) - Top;
                        PortionBottom = Bottom - floor(Bottom-ExSmall);
                        for c3 = c1+1:c2-1
                            Sum = Sum + HighImage(r1,c3)*PortionTop;      
                            Sum = Sum + HighImage(r2,c3)*PortionBottom;      
                        end
                    end
                    if r1+1 ~= r2
                        PortionLeft = ceil(Left+ExSmall) - Left;
                        PortionRight = Right - floor(Right-ExSmall);
                        for r3 = r1+1:r2-1
                            Sum = Sum + HighImage(r3,c1)*PortionLeft;
                            Sum = Sum + HighImage(r3,c2)*PortionRight;
                        end
                    end
                    %for interior pixels
                    if r1+1<r2 && c1+1<c2
                        for r3=r1+1:r2-1
                            for c3=c1+1:c2-1
                                Sum = Sum + HighImage(r3,c3);
                            end
                        end
                    end
                    PixelValue = Sum / (ScaleH*ScaleW);
                    LowImage(r,c) = PixelValue;
                end
            end

            DownSampling = LowImage;
            Diff = L0.GridAsHighLayer - DownSampling;

            %I need a hand-made upward imresize
            [low_h, low_w] = size(Diff);
            high_h = BuildLayer.TrueHeight;
            high_w = BuildLayer.TrueWidth;
            Up = zeros(BuildLayer.FormatHeight , BuildLayer.FormatWidth);
            ScaleH = high_h / low_h;
            ScaleW = high_w / low_w;
            %extend Diff 1 pixel for boundary case.
            Diff_Ext = zeros(low_h+1 , low_w+1);
            Diff_Ext(1:low_h,1:low_w) = Diff;
            Diff_Ext(low_h+1,1:low_w) = Diff(low_h,1:low_w);
            Diff_Ext(1:low_h,low_w+1) = Diff(1:low_h,low_w);
            Diff_Ext(low_h+1,low_w+1) = Diff_Ext(low_h,low_w);
            for r=1:BuildLayer.FormatHeight         %think it as a point, rather than a region, the r, c is the coordinate of high image
                y = (r-1+0.5)/ScaleH;           %y and x are the coordinates in Diff_Ext image
                y1 = floor(y+0.5)-0.5;
                y2 = y1+1;
                r1 = y1+0.5;
                r2 = r1+1;
                if r1 == 0
                    r1 = 1;
                end
                for c=1:BuildLayer.FormatWidth
                    x = (c-1+0.5)/ScaleW;
                    %use the closest 4 points to compute the interpolated value, if it is boundary case, extend the boundary
                    x1 = floor(x+0.5)-0.5;
                    x2 = x1+1;
                    c1 = x1+0.5;
                    c2 = c1+1;
                    %boundary case
                    if c1 == 0
                        c1 = 1;
                    end
                    v11 = Diff_Ext(r1,c1);      %top left pixel
                    v12 = Diff_Ext(r1,c2);      %top right pixel
                    v21 = Diff_Ext(r2,c1);      %bottom left pixel
                    v22 = Diff_Ext(r2,c2);

                    %interpolate the value
                    v = v11 *(x2-x)*(y2-y) + v12*(x-x1)*(y2-y) + v21*(x2-x)*(y-y1) + v22*(x-x1)*(y-y1);
                    Up(r,c) = v;
                end
            end
            final = Convolute(Up, Bk_GauVar);
            Img = Img + final;
        end
        BuildLayer.GridAsHighLayer = zeros(BuildLayer.FormatHeight,BuildLayer.FormatWidth);       %in some case, there will be dot point TrueHeight, TrueWidth
        BuildLayer.GridAsHighLayer(1:size(AverageImage,1),1:size(AverageImage,2)) = Img;
        BuildLayer.Conv = BuildLayer.GridAsHighLayer;
        AllLayers = [BuildLayer; AllLayers];       %move this line to the end after the layer is built    

%         if Para.bProduceEachLayerImage
%             if ChannelNumber == 3
%                 %restore the color information
%                 IQLayer_high = imresize(IQLayer, [BuildLayer.FormatHeight BuildLayer.FormatWidth]);
%                 ReconYIQ = AllLayers(1).GridAsHighLayer;
%                 ReconYIQ(:,:,2:3) = IQLayer_high;
%                 ReconRGB = uint8(YIQ2RGB(ReconYIQ));
%                 OutputImage = ReconRGB;
%             elseif ChannelNumber == 1
%                 OutputImage = Img;
%             end
% 
%             SaveFileName = [Para.TempDataFolder Para.SaveName '_BuildINumber' num2str(BuildINumber) '.png'];
%             imwrite( OutputImage , SaveFileName );
%         end
    end

    %ignore unnecessary data, to save disk space
    LayerNum = length(AllLayers);
    AllLayers2(LayerNum,1) = struct('INumber', 0 , 'TrueWidth', 0 , 'TrueHeight' , 0 , 'FormatWidth' , 0 , 'FormatHeight' , 0 , ...
        'ValidWidth' , 0 , 'ValidHeight' , 0, 'GridAsHighLayer' , [] );
    for i=1:LayerNum
        AllLayers2(i).INumber = AllLayers(i).INumber;
        AllLayers2(i).TrueWidth = AllLayers(i).TrueWidth;
        AllLayers2(i).TrueHeight = AllLayers(i).TrueHeight;
        AllLayers2(i).FormatWidth = AllLayers(i).FormatWidth;
        AllLayers2(i).FormatHeight = AllLayers(i).FormatHeight;
        AllLayers2(i).ValidWidth = AllLayers(i).ValidWidth;
        AllLayers2(i).ValidHeight = AllLayers(i).ValidHeight;
        AllLayers2(i).GridAsHighLayer = AllLayers(i).GridAsHighLayer;
    end
end

