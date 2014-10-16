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
%Chih-Yuan Yang EECS UC Merced
%File created: 12 Aug 2010
%Last modified: 12 Aug 2010
%discriminative super-resolution

function rgb = YIQ2RGB( yiq )
    T = [0.299,0.587,0.114;0.595716,-0.274453,-0.321263;0.211456,-0.522591,0.311135];
    invT = inv(T);
    rgb(:,:,1) = invT(1,1) * yiq(:,:,1) + invT(1,2) * yiq(:,:,2) + invT(1,3) * yiq(:,:,3);
    rgb(:,:,2) = invT(2,1) * yiq(:,:,1) + invT(2,2) * yiq(:,:,2) + invT(2,3) * yiq(:,:,3);
    rgb(:,:,3) = invT(3,1) * yiq(:,:,1) + invT(3,2) * yiq(:,:,2) + invT(3,3) * yiq(:,:,3);
end