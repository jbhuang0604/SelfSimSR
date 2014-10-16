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
%Chih-Yuan Yang
%2013/2/22
%Create Initial Dictionary, initialDictionary from the Singla, but not
%repeat
function CreateInitialDictionary( Para )
    TempFolder = Para.TempDataFolder;
    SaveName = Para.SaveName;
    
    LoadData = load(fullfile(TempFolder, [SaveName '_XlXh.mat']));
    XlXh = LoadData.XlXh;
    clear LoadData;

    SqrtSumOfSquare = sqrt(sum(XlXh.^2));
    
    [Dim DataSize] = size(XlXh);
    codesize = Para.DictionarySize;
    InitialDictionary = zeros(Dim , codesize );
    Thd = 1e-5;
    idx = 0;
    for i=1:DataSize
        if SqrtSumOfSquare(i) >= Thd      %not use pure zero
            CandidateSignal = XlXh(:,i);
        
            %verify non-repeated
            bRepeated = false;
            for j=1:idx
                ComparedSignal = InitialDictionary(:,j);
                SignalDiff = ComparedSignal - CandidateSignal;
                SumAbs = sum(abs(SignalDiff));
                if SumAbs < Thd
                    bRepeated = true;
                    break;
                end
            end

            if bRepeated == false
                idx = idx + 1;
                InitialDictionary(:,idx) = CandidateSignal;       %I don't use randperm for observation
                if idx == codesize
                    break;
                end
            end
        end
    end
    DlDh = InitialDictionary;
    save(fullfile(TempFolder, [SaveName '_DlDh0.mat']), 'DlDh');
end