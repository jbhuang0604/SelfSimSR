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
%Jun 16 2010
%Chih-Yuan Yang EECS UC Merced
%Implement Glasner ICCV 09 paper
function yiq = RGB2YIQ( rgb )
    yiq(:,:,1) = 0.299 * rgb(:,:,1) + 0.587 * rgb(:,:,2) + 0.114 * rgb(:,:,3);
    yiq(:,:,2) = 0.595716 * rgb(:,:,1) -0.274453 * rgb(:,:,2) -0.321263 * rgb(:,:,3);
    yiq(:,:,3) = 0.211456 * rgb(:,:,1) -0.522591 * rgb(:,:,2) +0.311135 * rgb(:,:,3);
end