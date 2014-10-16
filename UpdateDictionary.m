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
%Cluster
%Feb 16 2010
%Chih-Yuan Yang
function UpdateDictionary( Para , Iter )
    TempFolder = Para.TempDataFolder;
    SaveName = Para.SaveName;
    %tStart = now;
        
    LoadData = load(fullfile(TempFolder, [SaveName '_DlDh' num2str(Iter-1) '.mat']));
    Dictionary = LoadData.DlDh;
    clear LoadData
    
    LoadData = load(fullfile(TempFolder, [SaveName '_XlXh.mat']));
    Data = LoadData.XlXh;
    clear LoadData
  
    LoadData = load(fullfile(TempFolder, [SaveName '_CoefMatrix_Iter' num2str(Iter) '.mat']));
    CoefMatrix = LoadData.CoefMatrix;
    clear LoadData
      
    replacedVectorCounter = 0;
    FixedDictionaryElement = [];
    param.L = 1;    %Feb 16 Chih-Yuan, I don't know what this parameter do.
	rPerm = randperm(size(Dictionary,2));
    for j = rPerm
        [betterDictionaryElement,CoefMatrix,addedNewVector] = I_findBetterDictionaryElement(Data,...
            [FixedDictionaryElement,Dictionary],j+size(FixedDictionaryElement,2),...
            CoefMatrix ,param.L);
        Dictionary(:,j) = betterDictionaryElement;
        replacedVectorCounter = replacedVectorCounter+addedNewVector;
    end

    Dictionary = I_clearDictionary(Dictionary,CoefMatrix(size(FixedDictionaryElement,2)+1:end,:),Data);
    
    %compute the Optiminzation value
    %DiffMatrix = Data - Dictionary * CoefMatrix;
    %DiffSquare = DiffMatrix.*DiffMatrix;
    %GroupSignalDiff = sum(DiffSquare(:));
    %CoefSquare = CoefMatrix .* CoefMatrix;
    %CoefpqNorm = sum(sqrt(sum(CoefSquare,2)));
    %OptSum_UpdateDictionary = GroupSignalDiff + CoefpqNorm;
    %WriteToInfoFile( OptSum_UpdateDictionary , Para );
    
    DlDh = Dictionary;
    save( fullfile(TempFolder, [SaveName '_DlDh' num2str(Iter) '.mat']) , 'DlDh' );
    %tEnd = now;
    %UpdateDictionaryTime = ['(Iter' num2str(Iter) ')' datestr(tEnd-tStart, 'dd:HH:MM:SS')];
    %WriteToInfoFile( UpdateDictionaryTime , Para );
end

function [betterDictionaryElement,CoefMatrix,NewVectorAdded] = I_findBetterDictionaryElement(Data,Dictionary,j,CoefMatrix,numCoefUsed)
    if (length(who('numCoefUsed'))==0)
        numCoefUsed = 1;
    end
    relevantDataIndices = find(CoefMatrix(j,:)); % the data indices that uses the j'th dictionary element.
    if (length(relevantDataIndices)<1) %(length(relevantDataIndices)==0)
        ErrorMat = Data-Dictionary*CoefMatrix;
        ErrorNormVec = sum(ErrorMat.^2);
        [d,i] = max(ErrorNormVec);
        betterDictionaryElement = Data(:,i);%ErrorMat(:,i); %
        betterDictionaryElement = betterDictionaryElement./sqrt(betterDictionaryElement'*betterDictionaryElement);
        betterDictionaryElement = betterDictionaryElement.*sign(betterDictionaryElement(1));
        CoefMatrix(j,:) = 0;
        NewVectorAdded = 1;
        return;
    end
    NewVectorAdded = 0;
    tmpCoefMatrix = CoefMatrix(:,relevantDataIndices); 
    tmpCoefMatrix(j,:) = 0;% the coeffitients of the element we now improve are not relevant.
    errors =(Data(:,relevantDataIndices) - Dictionary*tmpCoefMatrix); % vector of errors that we want to minimize with the new element
    % % the better dictionary element and the values of beta are found using svd.
    % % This is because we would like to minimize || errors - beta*element ||_F^2. 
    % % that is, to approximate the matrix 'errors' with a one-rank matrix. This
    % % is done using the largest singular value.
    [betterDictionaryElement,singularValue,betaVector] = svds(errors,1);
    CoefMatrix(j,relevantDataIndices) = singularValue*betaVector';% *signOfFirstElem
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  findDistanseBetweenDictionaries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ratio,totalDistances] = I_findDistanseBetweenDictionaries(original,new)
    % first, all the column in oiginal starts with positive values.
    catchCounter = 0;
    totalDistances = 0;
    for i = 1:size(new,2)
        new(:,i) = sign(new(1,i))*new(:,i);
    end
    for i = 1:size(original,2)
        d = sign(original(1,i))*original(:,i);
        distances =sum ( (new-repmat(d,1,size(new,2))).^2);
        [minValue,index] = min(distances);
        errorOfElement = 1-abs(new(:,index)'*d);
        totalDistances = totalDistances+errorOfElement;
        catchCounter = catchCounter+(errorOfElement<0.01);
    end
    ratio = 100*catchCounter/size(original,2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  I_clearDictionary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Dictionary = I_clearDictionary(Dictionary,CoefMatrix,Data)
    T2 = 0.99;
    T1 = 3;
    K=size(Dictionary,2);
    Er=sum((Data-Dictionary*CoefMatrix).^2,1); % remove identical atoms
    G=Dictionary'*Dictionary; G = G-diag(diag(G));
    for jj=1:1:K,
        if max(G(jj,:))>T2 | length(find(abs(CoefMatrix(jj,:))>1e-7))<=T1 ,
            [val,pos]=max(Er);
            Er(pos(1))=0;
            Dictionary(:,jj)=Data(:,pos(1))/norm(Data(:,pos(1)));
            G=Dictionary'*Dictionary; G = G-diag(diag(G));
        end
    end
end

