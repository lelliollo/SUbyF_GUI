classdef SUbyF < handle
    %Surface Uncertainty by Fit (SUbyF) matlab class for surface
    %displacement uncertainty analysis
    
    %A. Lavatelli 2018
    
    properties
        dataPreprocessMode
        fitModel
        points3D
        InputDataTest
    end
    
    properties (Constant)
       PreProcAlgorithms={'same','CM-SVD','Abs-Mean'}; 
    end
    
    methods(Access=public)
        %=================================================================
        function obj=SUbyF(surf_data)
            TRes=obj.CheckInput(surf_data);
            obj.InputDataTest=TRes;
            if TRes.Pass
                obj.points3D=surf_data;
                if TRes.IsMultiple
                    obj.dataPreprocessMode='CM-SVD';
                else
                    obj.dataPreprocessMode='same';
                end
            else
               disp(TRes)
               msgID = 'SUbyF:WrongDataFormat';
               msg = 'Data input is not correct. It should be a m-by-n-by-j numeric matrix';
               SingleFileException = MException(msgID,msg);
               throw(SingleFileException); 
            end
            %%%% Set preprocessor
            obj.dataPreprocessMode='Abs-Mean';
            %%%% Set fittype
            obj.fitModel='lowess';
            
        end
        %=================================================================
        function obj=DecimateSurf(obj,DecFac)
           A=obj.points3D(1:DecFac:end,1:DecFac:end,:);
           obj.points3D=A;
        end
        %=================================================================
        function [MatFitObj,Z,x_v,y_v,fit_point_cloud,FitStatistics]=FitSurface(obj)
            Z=obj.DataPreProcessor();
            disp('////////////////////////////////////')
            disp('DATA FITTING Started')
            [m,n]=size(Z);
            x_v=1:n;
            y_v=1:m;
            disp('Squeeze data...')
            [x_fit,y_fit,z_fit]=obj.SqueezeForFitting(Z,x_v,y_v);
            %fitting surface
            disp(strjoin({'With fit model',obj.fitModel,'...'}))
            [MatFitObj,FitStatistics] = fit([x_fit,y_fit],z_fit,obj.fitModel);
            fit_point_cloud=[x_fit,y_fit,z_fit];
            disp('DATA FITTING Finished')
            disp('////////////////////////////////////')
        end
        %=================================================================
        function obj=SetPreprocessorMode(obj,Mode)
            if obj.TestPreProcOptStr(Mode)
                obj.dataPreprocessMode=Mode;
            else
               msgID = 'SetPreprocessorMode:WrongMode';
               msg = 'Please choose a correct algorithm. To see a list, see the PreProcAlgorithms property of the class';
               SingleFileException = MException(msgID,msg);
               throw(SingleFileException);
            end
        end
        %=================================================================
        function obj=SetFitModel(obj,modelName)
           obj.fitModel=modelName; 
        end
    end
    
    methods (Static, Access=public)
        function Evec=GetUncertaintyBySurfFit(Pcloud,fitObj)
            Evec=Pcloud(:,1);
            for i=1:length(Evec)
               fitest=feval(fitObj,Pcloud(i,1:2));
               Evec(i)=Pcloud(i,3)-fitest;
            end
        end
        
    end
    
    methods (Access=private)
        %=================================================================
        function [Z]=DataPreProcessor(obj)
           disp('////////////////////////////////////')
           disp('DATA PREPROCESSOR Started')
           if strcmp(obj.dataPreprocessMode,'same') 
               %%%%%%% REPLICATE THE INPUT
               disp('With method "same"')
               Z=obj.points3D;
           elseif strcmp(obj.dataPreprocessMode,'CM-SVD')
               disp('With method "CM-SVD"')
               %first strip out nans
               cleanPoints=obj.ReplaceNaNs(obj.points3D,0);
               %%%%%%% RUN CovMat AND SVD
               disp('Squeezing data ...')
               [sqW,ords]=obj.SqueezeForCovMatComputation(cleanPoints);
               disp('Covariance matrix computation...')
               CovMat=cov(sqW);
               disp('Covariance matrix decomposition...')
               [U,~,~] = svd(CovMat);
               disp('Extract shape...')
               shapeVec=U(:,1);
               disp('Reorder data...')
               RawOut=obj.ReorderShape(shapeVec,ords);
               %Put Nans back in place
               Z=obj.PutBackNaNs(RawOut,0);
          elseif strcmp(obj.dataPreprocessMode,'Abs-Mean')
              disp('With method "Abs-Mean"')
              disp('Absolute value...')
              Amat=abs(obj.points3D);
              disp('Compute mean...')
              Z=nanmean(Amat,3);
           end
           disp('DATA PREPROCESSOR Completed')
           disp('////////////////////////////////////')
        end
        %=================================================================
        function tres=TestPreProcOptStr(obj,str)
            test_vec=strcmp(obj.PreProcAlgorithms,str);
            tres=true;
            if sum(test_vec)==0
                tres=false;
            end            
        end
    end
    
    methods (Static, Access=private)
        %=================================================================
        function TestResult=CheckInput(A)
            TestResult.Pass=false;
            TestResult.IsAMatrix=false;
            S=size(A);
            if or(length(S)==2,length(S)==3)
                TestResult.IsAMatrix=true;
            end
            TestResult.IsMultiple=false;
            if length(S)==3
                TestResult.IsMultiple=true;
            end
            TestResult.IsNumeric=isnumeric(A);
            TestResult.VarType=class(A);
            if and(TestResult.IsAMatrix,TestResult.IsNumeric)
                TestResult.Pass=true;
            end
        end
        %=================================================================
        function [B,pos]=SqueezeForCovMatComputation(A)
            [m,n,Nframs]=size(A);
            if Nframs==1
                %exception thrown for wrong inputs
               msgID = 'SqueezeForCovMatComputation:WrongDataFormat';
               msg = 'Data input is not correct. It should be a 3D numeric matrix';
               SingleFileException = MException(msgID,msg);
               throw(SingleFileException); 
            else
                %here we process data
                %Compute position grids
                [colgr,rowgr]=meshgrid(1:n,1:m);
                pos(:,1)=reshape(rowgr,1,m*n);
                pos(:,2)=reshape(colgr,1,m*n);
                B=zeros(Nframs,m*n);
                for i=1:Nframs
                    B(i,:)=reshape(A(:,:,i),1,m*n);
                end
                
            end
        end
        %=================================================================
        function [C]=ReorderShape(A,ords)
            N=length(A);
            pG=max(ords,1);
            C=zeros(pG(1),pG(2));
            for i=1:N
               C(ords(i,1),ords(i,2))=A(i); 
            end
        end
        %=================================================================
        function [B]=ReplaceNaNs(A,rval)
            indx=isnan(A);
            B=A;
            B(indx)=rval;   
        end
        %=================================================================
        function [B]=PutBackNaNs(A,rval)
            indx=A==rval;
            B=A;
            B(indx)=NaN;   
        end
        %=================================================================
        function [x_fit,y_fit,z_fit]=SqueezeForFitting(Z,x_v,y_v)
           [m,n]=size(Z);
           Ntot=m*n;
           Nnan=sum(sum(isnan(Z)));
           Nnum=Ntot-Nnan;
           x_fit=zeros(Nnum,1);
           y_fit=x_fit;
           z_fit=x_fit;
           indx=1;
           for i=1:m
               for j=1:n
                   if not(isnan(Z(i,j)))
                   z_fit(indx)=Z(i,j);
                   y_fit(indx)=y_v(i);
                   x_fit(indx)=x_v(j);
                   indx=indx+1;
                   end
               end
           end     
       end
       %================================================================= 
    end
    
end

