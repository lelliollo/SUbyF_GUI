classdef MatchIDdataReader < handle
    %MatchIDReader - Matlab class to read the .csv matrix output generated
    %by the Digital Image Correlation (DIC) software MatchId
    %<https://www.matchidmbc.be/>
    %
    %Copyright - 2018 - Alberto Lavatelli <alberto.lavatelli@polimi.it> 
    %
    %Initialize class in this way:
    %        MiDReaderHandle=MatchIDdataReader('filename.csv')
    %the file name can be given as full path or local name. It can be a
    %single string or a cell array {1XJ} of strings. 
    %
    %Method(s):
    %   ReadData() ---> it reads the csv file and returns: 
    %                       -a matrix containing DIC data
    %                       -a matrix containing missing data labels
    %                   The usage is quite simple: 
    %                       [Mat, missing_data] = HandleToClass.ReadData()
    %                   
    %   ReadMultipleData() ---> it reads a list of csv file and returns: 
    %                       -a (MxNxJ) matrix containing DIC data
    %                       -a (MxNxJ) matrix containing missing data labels
    %                   The usage is quite simple: 
    %                       [Mat, missing_data] = HandleToClass.ReadMultipleData()
    %
    %   SetFileName(path) ---> methods to change file(s) name you are
    %                          working on
    %
    %   SetNaNString(string)--> you can put a custom NaN string          
    %
    % For further information type "help" on the function context
    % ==========================================================================
    %     LICENSE and WARRANTY
    %        This program is free software: you can redistribute it and/or modify
    %     it under the terms of the GNU General Public License as published by
    %     the Free Software Foundation, either version 3 of the License, or
    %     (at your option) any later version.
    %     
    %     This program is distributed in the hope that it will be useful,
    %     but WITHOUT ANY WARRANTY; without even the implied warranty of
    %     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    %     GNU General Public License for more details.
    %     
    %     You should have received a copy of the GNU General Public License
    %     along with this program.  If not, see <https://www.gnu.org/licenses/>.
    
    properties
        MiDCsvFile %property to store filename data
        NaNStrDesc %property to store NaN string descriptor
    end
    
    methods (Access=public)
        %% Constructor
        %=================================================================
         function obj=MatchIDdataReader(filename)
             %Constructor of MatchIDdataReader class. Class is built upon
             %matrix csv output file name.
            obj.MiDCsvFile=filename;
            %get system NaN and write to properties
            NET.addAssembly('System.Globalization');
            RegClass=System.Globalization.NumberFormatInfo;
            obj.NaNStrDesc=RegClass.NaNSymbol.char;
         end
         %% Data read functions
         %=================================================================
         function [DicOutput,missing_data]=ReadData(obj) 
            %This method reads a single .CSV matrix file and returns the
            %following variables:
            % ------> DicOutput: a matrix containing DIC data
            % ------> missing_data: a logical matrix containing ones where data is missing
            %Missing data are handled in a simple way: they are filled with
            %NaN. Given that MatchID doesn't provide any details on what is
            %missing where, data are read in a FIFO fashion and filled in
            %the end of each row
             if iscell(obj.MiDCsvFile)%throw exception if you have multiple files
               msgID = 'ReadData:MultipleFiles';
               msg = 'You cannot use read on multiple files. Try ReadMultipleData()';
               SingleFileException = MException(msgID,msg);
               throw(SingleFileException);
               DicMultOutput=zeros(2,2,2);
             else
                disp(strjoin({'Reading single file',obj.MiDCsvFile,'...'}))
               [DicOutput,missing_data]=obj.ReadDataFunction(obj.MiDCsvFile);
            end
         end
         %=================================================================
         function  [DicMultOutput,missing_data]=ReadMultipleData(obj)
            %This method reads multiple .CSV matrix files and returns the
            %following variables:
            % ------> DicOutput: a matrix containing DIC data
            % ------> missing_data: a logical matrix containing ones where data is missing
            %Missing data are handled in a simple way: they are filled with
            %NaN. Given that MatchID doesn't provide any details on what is
            %missing where, data are read in a FIFO fashion and filled in
            %the end of each row
            if iscell(obj.MiDCsvFile)
               disp('Processing multiple CSV files')
               DicMultOutput=[];
               missing_data=[];
               Nfiles=size(obj.MiDCsvFile,2);
               Rows=zeros(Nfiles,1);
               Cols=Rows;
               for i=1:Nfiles
                  disp(strjoin({'Reading file',obj.MiDCsvFile{i},'...'}))
                  [DicLocOut,Miss]=obj.ReadDataFunction(obj.MiDCsvFile{i});
                  [Rows(i),Cols(i)]=size(DicLocOut);
                  %Message if things are missing
                  if not(Rows(i)==Rows(1))
                       msgID = 'ReadMultipleData:InconsistentRows';
                       msg = strjoin({'The number of row data between DIC output files is different!',...
                           'Expected',num2str(Rows(1)),'rows, but got',num2str(Rows(i))});
                       warning(msgID,msg)
                  end
                  if not(Cols(i)==Cols(1))
                       msgID = 'ReadMultipleData:InconsistentCols';
                       msg = strjoin({'The number of column data between DIC output files is different!',...
                           'Expected',num2str(Cols(1)),'columns, but got',num2str(Cols(i))});
                       warning(msgID,msg)                      
                  end
                  CorrectOut=obj.CorrectMatrixSize(DicLocOut,Rows(1),Cols(1),NaN);
                  CorrectMiss=obj.CorrectMatrixSize(Miss,Rows(1),Cols(1),1);
                  DicMultOutput(:,:,i)=CorrectOut;
                  missing_data(:,:,i)=CorrectMiss;
               end
               
            else %throw exception if you have only one file
               msgID = 'ReadMultipleData:SingleFile';
               msg = 'You cannot use multiple read on a single file. Try ReadData()';
               SingleFileException = MException(msgID,msg);
               throw(SingleFileException);
               DicMultOutput=zeros(2,2,2);
            end
         end
         %=================================================================
         %% Set property functions
         %=================================================================
         function obj=SetFileName(obj,path)
             %This method allows the user to set the filenames of .CSV
             %matrix files to be read. Usage:
             %
             %  handle.SetFileName(path)
             %
             %If path is given a single string, then the class consider
             %this as a single file to be read. If path is given as a cell
             %array {1XN} of strings, then the class reads multiple files
            obj.MiDCsvFile=path; 
         end
         %=================================================================
         function obj=SetNaNString(obj,CustomNanString)
             %With this method you can setup a custom NaN string for the
             %CSV files to be intepreted.
            obj.NaNStrDesc=CustomNanString;
         end
         %=================================================================
    end
    %% Private stuffs
    methods(Access=private)
        %=================================================================
        function [DicOutputSingle,missing_data_matrix]=ReadDataFunction(obj,CustomFileName)
            %This method implements the private delegate to perform file
            %reading and translation to Matlab matrix         
            
            fID=fopen(CustomFileName,'r') ;%open csv file in read mode
            %initialize data
            buf=[];
            missing_data_matrix=[];
            Nn=[];
            indx=1;
               %Read csv file and dump to buffer
                while not(feof(fID))
                    tline = fgetl(fID); %get line
                    LineCell=strsplit(tline,';'); %separate with semicol
                    Nn(indx)=size(LineCell,2)-1; %remember that last char is \n
                    pp=zeros(1,Nn(indx)); %initialize row scan
                    for kk=1:Nn(indx)
                        if strcmp(LineCell{kk},obj.NaNStrDesc) %parse NaN correctly
                            pp(kk)=NaN;
                        else
                            pp(kk)=obj.ReadNumberStringAsSystem(LineCell{kk}); %parse double correctly according to system separator
                        end
                    end
                    [LineToStore,missDataIndx]=obj.CorrectArraySize(pp',Nn(1),NaN);
                    buf(indx,:)=LineToStore; %dump inside buffer
                    missing_data_matrix(indx,:)=missDataIndx;
                    indx=indx+1;
                end
            fclose(fID);
            DicOutputSingle=buf; %dummy move, but nice to see
         end
    end
    %=================================================================
    methods (Static,Access=private)
        %=================================================================
        function SysDoub=ReadNumberStringAsSystem(NumStr)
            %method to parse data from string
            nf = java.text.DecimalFormat;
            SysDoub=nf.parse(NumStr).doubleValue;
            clear('nf')
        end
        %=================================================================
        function [NewArray,missingDataFlag]=CorrectArraySize(ParData,NLength,repl_val)
            %Method to fill missing points in row scan of CSV files            
            L=length(ParData);
            missingDataFlag=zeros(NLength,1);
            if isempty(ParData) % Throw exception cause data is empty
               NewArray=NaN(NLength,1);
               msgID = 'CorrectArraySize:EmptyData';
               msg = 'The data vector is empty.. replacing with NaNs';
               warning(msgID,msg)
            else
                if L<NLength
                    deltaLength=NLength-L;
                    missingDataFlag(end-deltaLength:end)=ones(deltaLength,1);
                    NewArray=padarray(ParData,[deltaLength 0],repl_val,'post');
                    disp('pippo')
                elseif L==NLength
                    NewArray=ParData;
                elseif L>NLength
                    NewArray=ParData(1:NLength);
                end
            end
        end
        %=================================================================
        function NewMat=CorrectMatrixSize(MatDat,Rows,Cols,repl_val)
            %Method to fill missing points in matrix scan of multiple CSV files     
            [m,n]=size(MatDat);
            if m>Rows
               IntMat=MatDat(1:Rows,:); 
            elseif m==Rows
               IntMat=MatDat;
            elseif m<Rows
               IntMat=padarray(MatDat,[Rows-m 0],repl_val,'post');
            end
            if n>Cols
               NewMat=IntMat(:,1:Cols); 
            elseif n==Cols
               NewMat=IntMat;
            elseif n<Cols
               NewMat=padarray(IntMat,[0 Cols-n],repl_val,'post');
            end
        end
    end
    
end

