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
function CoefMatrix = FindCoef3( Para , Iter)
    TempFolder = Para.TempDataFolder;
    SaveName = Para.SaveName;
%    tStart = now;

    addpath(fullfile('Lib','spgl1-1.7'));
    codesize = Para.DictionarySize;

    load(fullfile(TempFolder, [SaveName '_ClusterResultAllMatchArray_Avg' num2str(Para.AvgSignalNumPerCluster) '.mat']), 'AllMatchArray', 'ClusterNum');

    LoadData = load(fullfile(TempFolder, [SaveName '_DlDh' num2str(Iter-1) '.mat']));
    Dictionary = [LoadData.DlDh];
    clear LoadData;
    
    LoadData = load(fullfile(TempFolder, [SaveName '_XlXh.mat']));
    XlXh = LoadData.XlXh;
    SignalNum = size(XlXh,2);
    clear LoadData;
    
    CoefMatrix_Sum = zeros( codesize, SignalNum );      %out of memory here
    CoefMatrix_ClusterCount = zeros(1,SignalNum);
    BaseSigma = Para.BaseSigma;
    opts = spgSetParms('verbosity',0,'iterations',Para.IterNumForGroupSparseCoding);   %1000
    OptimizationSum = 0;
    for CluIdx = 1:ClusterNum
        MatchArray = AllMatchArray(:,CluIdx);
        InClusterNum = sum(MatchArray);%AllInClusterNum(CluIdx);
        sigma = BaseSigma * sqrt(InClusterNum);     %Feb 17, add sqrt, adding should be correct
        InClusterGroupIdx = MatchArray';
        Y = XlXh(:,InClusterGroupIdx);
        if ~isempty(Y)
            Coef = spg_mmv(Dictionary,Y,sigma,opts);     %the form is min ||X||1,2 s.t. ||AX-B||2,2 <= sigma
            CoefMatrix_Sum(1:codesize, InClusterGroupIdx) = CoefMatrix_Sum(1:codesize, InClusterGroupIdx) + Coef;
            CoefMatrix_ClusterCount(InClusterGroupIdx) = CoefMatrix_ClusterCount(InClusterGroupIdx) + 1;
            disp( ['Find Coef ...' num2str(CluIdx) ' / ' num2str(ClusterNum)]);
            DiffMatrix = Y - Dictionary * Coef;
            DiffSquare = DiffMatrix.*DiffMatrix;
            GroupSignalDiff = sum(DiffSquare(:));
            CoefSquare = Coef .* Coef;
            CoefpqNorm = sum(sqrt(sum(CoefSquare,2)));
            OptimizationSum = OptimizationSum + GroupSignalDiff + CoefpqNorm;
        end
        %Compute the optimization sum
        %pause(0.1);
    end
    CoefMatrix = CoefMatrix_Sum ./ repmat(CoefMatrix_ClusterCount , codesize , 1);
%    OptSum_Coef = OptimizationSum;
%    WriteToInfoFile(OptSum_Coef, Para);
    save(fullfile(TempFolder, [SaveName '_CoefMatrix_Iter' num2str(Iter) '.mat']) , 'CoefMatrix' );
%    rmpath('lib\spgl1-1.7');
%    tEnd = now;
%    CoefFindTime = ['(Iter' num2str(Iter) ')' datestr(tEnd-tStart, 'dd:HH:MM:SS')];
%    WriteToInfoFile( CoefFindTime , Para );
end

