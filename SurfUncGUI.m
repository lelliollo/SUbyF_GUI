function varargout = SurfUncGUI(varargin)
% SURFUNCGUI MATLAB code for SurfUncGUI.fig
%      SURFUNCGUI, by itself, creates a new SURFUNCGUI or raises the existing
%      singleton*.
%
%      H = SURFUNCGUI returns the handle to a new SURFUNCGUI or the handle to
%      the existing singleton*.
%
%      SURFUNCGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SURFUNCGUI.M with the given input arguments.
%
%      SURFUNCGUI('Property','Value',...) creates a new SURFUNCGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SurfUncGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SurfUncGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SurfUncGUI

% Last Modified by GUIDE v2.5 10-May-2018 14:14:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SurfUncGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @SurfUncGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before SurfUncGUI is made visible.
function SurfUncGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SurfUncGUI (see VARARGIN)

% Choose default command line output for SurfUncGUI
handles.output = hObject;

%Initialization
handles.SelectLoadModeMenu.String={'File .mat','MatchID output folder'};
handles.LoadMode=1;
handles.UsingCustomMID='n';
handles.PreProcModeSU='CM-SVD';
handles.FitModelSU='loess';
handles.DecimationSU=0;
handles.CaricamentoConsenso=false;
handles.DatiConsenso=false;
handles.FitConsenso=false;
handles.UncConsenso=false;

handles.MessageBoxTextOut.String='GUI inizializzata correttamente';

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SurfUncGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SurfUncGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in SelectLoadModeMenu.
function SelectLoadModeMenu_Callback(hObject, eventdata, handles)
% hObject    handle to SelectLoadModeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SelectLoadModeMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SelectLoadModeMenu
handles.LoadMode=get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function SelectLoadModeMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SelectLoadModeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ButtonLoadFileDir.
function ButtonLoadFileDir_Callback(hObject, eventdata, handles)
% hObject    handle to ButtonLoadFileDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.LoadMode
    case 1
        %carica mat
       [FileName,PathName,~] = uigetfile('*.mat','Seleziona file .Mat');
       handles.MatFileName=strcat(PathName,'\',FileName);
       handles.MessageBoxTextOut.String='File Mat identificato';
    case 2
        %setuppa per matchid
       [~,PathName,~] = uigetfile('*.csv','Seleziona un file output MatchID');
       SearchExp=strcat(PathName,'\','*.csv');
       Dirlist=dir(SearchExp);
       Nfiles=size(Dirlist,1);
       Clist={};
       for i=1:Nfiles
           Clist{i}=strcat(Dirlist(i).folder,'\',Dirlist(i).name);
       end
       handles.MatchIdFilesList=Clist; 
       handles.MessageBoxTextOut.String='Files .CSV di MatchId Identificati';
end
handles.CaricamentoConsenso=true;
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in ExecuteLoadDataButton.
function ExecuteLoadDataButton_Callback(hObject, eventdata, handles)
% hObject    handle to ExecuteLoadDataButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.CaricamentoConsenso
    switch handles.LoadMode
        case 1
           %carica mat
           A=load(handles.MatFileName);
           nomedati=fields(A);
           handles.SurfData=eval(strcat('A.',nomedati{1}));
           handles.MessageBoxTextOut.String='Matrice dati caricata';
        case 2
           %pesca classe
           handles.MiDreader=MatchIDdataReader(handles.MatchIdFilesList);
           if strcmp(handles.UsingCustomMID,'y')
               handles.MiDreader.SetNaNString(handles.CustomNaN);           
           end
           handles.MessageBoxTextOut.String='Caricamento CSV files...';
           drawnow
           [handles.SurfData,~]=handles.MiDreader.ReadMultipleData();
           handles.MessageBoxTextOut.String='Dati MatchID caricati';
    end
else
    h=msgbox('Files da caricare mancanti','File mancanti','error');
end
handles.DatiConsenso=true;
% Update handles structure
guidata(hObject, handles);


% --------------------------------------------------------------------
function DatOptMenu_Callback(hObject, eventdata, handles)
% hObject    handle to DatOptMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function MiDDataReaderOption_Callback(hObject, eventdata, handles)
% hObject    handle to MiDDataReaderOption (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
prompt = {'Usare setting custom? (y/n)','Inserisci stringa custom "NaN":'};
dlg_title = 'Opzioni MatchId data reader';
num_lines = 1;
defaultans = {'y','Non un numero reale'};
answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
handles.UsingCustomMID=answer{1};
handles.CustomNaN=answer{2};
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in FitSurfButton.
function FitSurfButton_Callback(hObject, eventdata, handles)
% hObject    handle to FitSurfButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%Tira su classe SUbyF
if handles.DatiConsenso
        handles.hSUbyF=SUbyF(handles.SurfData);
        handles.hSUbyF.SetPreprocessorMode(handles.PreProcModeSU);
        handles.hSUbyF.SetFitModel(handles.FitModelSU);
        if handles.DecimationSU>1
            handles.hSUbyF.DecimateSurf(handles.DecimationSU);
        end
        [handles.MatFitObj,handles.Z,handles.x_v,handles.y_v,handles.Pcloud,handles.fit_stats]=handles.hSUbyF.FitSurface();
        handles.MessageBoxTextOut.String='Fit completato';
        handles.FitConsenso=true;
        % Update handles structure
else
    h=msgbox('Dati superificie mancanti','Dati mancanti','error');
end
guidata(hObject, handles);

% --- Executes on button press in UncCompButton.
function UncCompButton_Callback(hObject, eventdata, handles)
% hObject    handle to UncCompButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.FitConsenso
    handles.Ers=handles.hSUbyF.GetUncertaintyBySurfFit(handles.Pcloud,handles.MatFitObj);
    handles.MessageBoxTextOut.String='Incertezza calcolata';
    handles.UncConsenso=true;
else
    h=msgbox('Dati fit mancanti','Dati mancanti','error');
end
% Update handles structure
guidata(hObject, handles);

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selection = questdlg('Vuoi chiudere il programma',...
                     'Exit',...
                     'Yes','No','Yes');
 switch selection
   case 'Yes'
     delete(hObject);
     clear('handles')
   case 'No'
     return
 end


% --------------------------------------------------------------------
function Untitled_1_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function MenuSUbyF_Callback(hObject, eventdata, handles)
% hObject    handle to MenuSUbyF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

prompt = {'Modalità preprocessing:','Fit model:','Decimazione:'};
dlg_title = 'Opzioni SUbyF';
num_lines = 1;
defaultans = {'CM-SVD','loess','0'};
answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
handles.PreProcModeSU=answer{1};
handles.FitModelSU=answer{2};
handles.DecimationSU=eval(answer{3});

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in PlottaFitButton.
function PlottaFitButton_Callback(hObject, eventdata, handles)
% hObject    handle to PlottaFitButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.FitConsenso
plot3(handles.Pcloud(:,1),handles.Pcloud(:,2),handles.Pcloud(:,3),'o')
hold all
plot(handles.MatFitObj)
hold off
end

% --- Executes on button press in HistoButton.
function HistoButton_Callback(hObject, eventdata, handles)
% hObject    handle to HistoButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.UncConsenso
histogram(handles.Ers)
end


% --------------------------------------------------------------------
function Untitled_2_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function SalvaDatiMenu_Callback(hObject, eventdata, handles)
% hObject    handle to SalvaDatiMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if and(handles.UncConsenso,handles.FitConsenso)
    ModelloFit=handles.MatFitObj;
    Zmat=handles.Z;
    x_v=handles.x_v;
    y_v=handles.y_v;
    NuvolaPunti=handles.Pcloud;
    StatisticheFit=handles.fit_stats;
    Errore=handles.Ers;
    svvar={'ModelloFit','Zmat','x_v','y_v','NuvolaPunti','StatisticheFit','Errore'};
    uisave(svvar)
    h = msgbox('Salvataggio completato');
else
    h = msgbox('Salvataggio impossibile, analisi incompleta','Errore','error');
end

