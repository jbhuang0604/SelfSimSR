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
%File Created: 20 Sep 2010
%Last Modified:207 Sep 2010 
%Given HighImg, produce conv and subsample LowImg
function SubSampleImg = GenerateSubSampleImage(HighImg, LowHeight, LowWidth, Scale, GauVar)
    I = Convolute(HighImg , GauVar );
    FormatLowHeight = ceil(LowHeight);
    FormatLowWidth = ceil(LowWidth);
    ValidLowHeight = floor(LowHeight);
    ValidLowWidth = floor(LowWidth);
    LowImg = zeros(FormatLowHeight, FormatLowWidth);
    for r=1:ValidLowHeight
        for c=1:ValidLowWidth
            LowTop = r-1;
            LowLeft = c-1;
            HighTop = LowTop * Scale;
            HighLeft = LowLeft * Scale;
            r1 = floor(HighTop) + 1;
            r2 = r1+1;
            r3 = r1+2;
            c1 = floor(HighLeft) + 1;
            c2 = c1+1;
            c3 = c1+2;
            %compute the corresponding 4x4 grid in low-res patch
            if floor(HighTop) == HighTop   %it is just an integer
                TopPortion = 1;
            else
                TopPortion = ceil(HighTop) - HighTop;
            end
            if floor(HighLeft) == HighLeft
                LeftPortion = 1;
            else
                LeftPortion = ceil(HighLeft) - HighLeft;
            end 
            if Scale - TopPortion > 1
                BottomPortion = Scale - TopPortion - 1;
                VPixel = 3;
            else
                BottomPortion = Scale - TopPortion;
                VPixel = 2;
            end
            if Scale - LeftPortion > 1
                RightPortion = Scale - LeftPortion - 1;
                HPixel = 3;
            else
                RightPortion = Scale - LeftPortion;
                HPixel = 2;
            end
            if VPixel == 3 && HPixel == 3
                P11 = TopPortion * LeftPortion;
                P12 = TopPortion;
                P13 = TopPortion * RightPortion;
                P21 = LeftPortion;
                P22 = 1;
                P23 = RightPortion;
                P31 = BottomPortion * LeftPortion;
                P32 = BottomPortion;
                P33 = BottomPortion * RightPortion;
                LowImg(r,c) = P11*I(r1,c1) + P12*I(r1,c2) + P13*I(r1,c3) + ...
                              P21*I(r2,c1) + P22*I(r2,c2) + P23*I(r2,c3) + ...
                              P31*I(r3,c1) + P32*I(r3,c2) + P33*I(r3,c3);
            elseif VPixel == 3 && HPixel == 2
                P11 = TopPortion * LeftPortion;
                P12 = TopPortion * RightPortion;
                P21 = LeftPortion;
                P22 = RightPortion;
                P31 = BottomPortion * LeftPortion;
                P32 = BottomPortion * RightPortion;
                LowImg(r,c) = P11*I(r1,c1) + P12*I(r1,c2) + ...
                              P21*I(r2,c1) + P22*I(r2,c2) + ...
                              P31*I(r3,c1) + P32*I(r3,c2);
            elseif VPixel == 2 && HPixel == 3
                P11 = TopPortion * LeftPortion;
                P12 = TopPortion;
                P13 = TopPortion * RightPortion;
                P21 = BottomPortion * LeftPortion;
                P22 = BottomPortion;
                P23 = BottomPortion * RightPortion;
                LowImg(r,c) = P11*I(r1,c1) + P12*I(r1,c2) + P13*I(r1,c3) + ...
                              P21*I(r2,c1) + P22*I(r2,c2) + P23*I(r2,c3);
            elseif VPixel == 2 && HPixel == 2
                P11 = TopPortion * LeftPortion;
                P12 = TopPortion * RightPortion;
                P21 = BottomPortion * LeftPortion;
                P22 = BottomPortion * RightPortion;
                LowImg(r,c) = P11*I(r1,c1) + P12*I(r1,c2) + ...
                              P21*I(r2,c1) + P22*I(r2,c2);
            end
        end
    end
    SubSampleImg = LowImg / Scale^2;
end