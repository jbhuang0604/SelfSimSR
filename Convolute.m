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
%Separate as an indepdent function
%Create: Mar 11 2010
%Chih-Yuan Yang UC Merced EECS
function HBk = Convolute(x, Bk_GauVar )
    Sigma = sqrt( Bk_GauVar );
    [height width] = size( x );
    HBk = zeros( height, width);
    for i = 1:height
        for j = 1:width
            YCoor = (i-0.5);
            XCoor = (j-0.5);
            EffectiveRadius = Sigma * 4;
            MostLeftTopSourcePoint.X = XCoor - EffectiveRadius;
            MostLeftTopSourcePoint.Y = YCoor - EffectiveRadius;
            MostRightBottomSourcePoint.X = XCoor + EffectiveRadius;
            MostRightBottomSourcePoint.Y = YCoor + EffectiveRadius;
            %trim
            if MostLeftTopSourcePoint.X < 0.5
                MostLeftTopSourcePoint.X = 0.5;
            end
            if MostLeftTopSourcePoint.Y < 0.5
                MostLeftTopSourcePoint.Y = 0.5;
            end
            if MostRightBottomSourcePoint.X > width - 0.5
                MostRightBottomSourcePoint.X = width - 0.5;
            end
            if MostRightBottomSourcePoint.Y > height - 0.5
                MostRightBottomSourcePoint.Y = height - 0.5;
            end
            
            %Convert Coordinate to grid index
            MostLeftTopSourcePoint.ColIdx = floor(MostLeftTopSourcePoint.X + 0.5);
            MostLeftTopSourcePoint.RowIdx = floor(MostLeftTopSourcePoint.Y + 0.5);
            MostRightBottomSourcePoint.ColIdx = floor(MostRightBottomSourcePoint.X + 0.5);
            MostRightBottomSourcePoint.RowIdx = floor(MostRightBottomSourcePoint.Y + 0.5);
            
            WeightSum = 0;
            IntensitySum = 0;
            for r = MostLeftTopSourcePoint.RowIdx:MostRightBottomSourcePoint.RowIdx
                for c = MostLeftTopSourcePoint.ColIdx:MostRightBottomSourcePoint.ColIdx
                    SrcY = r - 0.5;
                    SrcX = c - 0.5;
                    distSqr = (SrcY - YCoor)^2 + (SrcX - XCoor)^2;
                    if( distSqr < Bk_GauVar * 16);
                        weight = exp(-distSqr/(2*Bk_GauVar))/(2*pi*Bk_GauVar);
                        WeightSum = WeightSum + weight;
                        IntensitySum = IntensitySum + weight * x(r , c );
                    end
                end
            end
            HBk(i,j) = IntensitySum / WeightSum ;
        end
    end
end