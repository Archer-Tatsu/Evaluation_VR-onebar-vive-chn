%=====================================================================
% File: SSCQS.m
%=====================================================================
function varargout = SSCQS(varargin)
% SSCQS M-file for SSCQS.fig
%      SSCQS, by itself, creates a new SSCQS or raises the existing
%      singleton*.
%
%      H = SSCQS returns the handle to a new SSCQS or the handle to
%      the existing singleton*.
%
%      SSCQS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SSCQS.M with the given input arguments.
%
%      SSCQS('Property','Value',...) creates a new SSCQS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SSCQS_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SSCQS_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright 2002-2003 The MathWorks, Inc.

% Edit the above text to modify the response to help SSCQS

% Last Modified by GUIDE v2.5 21-Oct-2009 23:17:08

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SSCQS_OpeningFcn, ...
                   'gui_OutputFcn',  @SSCQS_OutputFcn, ...
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


% --- Executes just before SSCQS is made visible.
function SSCQS_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SSCQS (see VARARGIN)
clc;
% Choose default command line output for SSCQS
handles.output = [];
[Args]=ParseInputs(varargin{:});

[handles]=InitializeSubData(handles,Args);

%Create line handle for the slider
axes(handles.SliderBar);
handles.LineHandle=line([1,1],[0,1],'LineWidth',2,'Color','r');
set(handles.LineHandle,'Parent',handles.SliderBar);

%TODO: Need to perfect this. Hence commented for now.
% %We need to present a grey background to minimize distractions
% set(0,'defaultUicontrolBackgroundColor',[0.5,0.5,0.5]);

%Extract testing phase and subject information.
if('t'==Args.SessionType)
    set(handles.Phase,'String','Training');
    set(handles.InstructionsPhase,'String','训练模式');
    handles.SubData.SaveFn=@NoSave;
elseif('a'==Args.SessionType)
    set(handles.Phase,'String','Testing');
    set(handles.InstructionsPhase,'String','标准模式');

    handles.SubData.SaveFn=@SaveScores;
else
    %close(handles.SSCQS);
    error('无效的运行模式','Invalid input','modal');
    return;
end


%Figure out subject number
if(1==isempty(Args.mode))
    %New file
    handles.SubData.IsAppend=0;
    
else
    if((1==strcmp('append',Args.mode)))
        
        [num,txt]=ReadTabulatedValues(handles.SubData.OutputFilename);
        
        
        if(1==handles.SubData.AutoGenerateSubNum)
            %Read first row and extract last subject number
            ColHeaders=lower(txt(1,:));
            [NumOfSubjects,LastSubject,SubColIdx]=ReadSubjectNumbers(ColHeaders);
            if(0==NumOfSubjects)
                handles.SubData.IsAppend=0;
            else
                handles.SubData.SubjectNumber=LastSubject+1;
                handles.SubData.IsAppend=1;
            end
        else
            handles.SubData.IsAppend=1;
            
        end %if(1==handles.SubData.AutoGenerateSubNum)
        
        %Verify that the files selected and the files in the SubRating
        %spreadsheet match.
       if(1==size(txt,1))
           %close(handles.SSCQS);
           error('未指定文件');
           return;
       end
        tmp=setdiff({txt{2:end,1}},Args.TestFiles');

        if(~isempty(tmp))
            %close(handles.SSCQS);
            error('添加的测试序列与所选择的已存在的记录文件中的测试序列不同');
            return;
        end
        
    elseif((1==strcmp('overwrite',Args.mode)))
        %Don't care
        handles.SubData.IsAppend=0;
        
    end %if((1==strcmp('append',Args.mode)))
    
end  %if(1==isempty(Args.mode))

%Append display

set(handles.SubNum,'String',num2str(handles.SubData.SubjectNumber));

%Display instructions
set(handles.TestPanel,'visible','off');
set(handles.InstruPanel,'visible','on');
handles=DisplayInstructions(handles);

if(strcmp(Args.SelSubTestMethod,'MSCQS'))
    set(handles.SSCQS,'Name','MSCQS');
end

% Update handles structure
guidata(handles.SSCQS, handles);

% UIWAIT makes SSCQS wait for user response (see UIRESUMEms)
uiwait(handles.SSCQS);

% --- Outputs from this function are returned to the command line.
function varargout = SSCQS_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes when user attempts to close SelectSource.
function SSCQS_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to SSCQS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
if isequal(get(handles.SSCQS, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    handles.output=1;
    guidata(handles.SSCQS,handles);
    uiresume(handles.SSCQS);
    warndlg('即将中止测试，再次点击关闭确认中止。','中止测试');
    %delete(handles.SSCQS);
else
    % The GUI is no longer waiting, just close it
    delete(handles.SSCQS);
end


% --- Executes on button press in Continue.
function Continue_Callback(hObject, eventdata, handles)
% hObject    handle to Continue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%Hide Instructions and enable Test screen
set(handles.InstruPanel,'visible','off');
set(handles.TestPanel,'visible','on');

%Update display
set(handles.CurrCount,'String',num2str(handles.SubData.Count));
set(handles.TotalCount,'String',num2str(handles.SubData.NumOfTestFiles));

%Create Slider Bar
[handles]=InitializeSliderBar(handles);

%Initialize new callbacks
SliderBarButtonDownFcn=get(handles.SliderBar,'ButtonDownFcn');
set(handles.LineHandle,'ButtonDownFcn',SliderBarButtonDownFcn);

%Set the buttons
set(handles.Next,'Enable','off');
set(handles.Rate,'Enable','off');

[handles]=RenderVideo(handles);

guidata(handles.SSCQS,handles);


% --- Executes on button press in Next.
function Next_Callback(hObject, eventdata, handles)
% hObject    handle to Next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.Next,'Enable','off');
handles.SubData.Count=handles.SubData.Count+1;
handles.SubData.Index=handles.SubData.permutationVector(handles.SubData.Count);
set(handles.CurrCount,'String',num2str(handles.SubData.Count));

%Render next image
[handles]=RenderVideo(handles);
%Create Slider Bar
[handles]=InitializeSliderBar(handles);

guidata(handles.SSCQS,handles);

function Emergency_Callback(hObject, eventdata, handles)
% hObject    handle to Next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Render next image
[handles]=RenderVideo(handles);

guidata(handles.SSCQS,handles);

% --- Executes on button press in Rate.
function Rate_Callback(hObject, eventdata, handles)
% hObject    handle to Rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.Rate,'Enable','off');

%Check
if sum(ismember(handles.SubData.IdxQP42,handles.SubData.Index))~=0 %QP42
    
    temp_ref=handles.SubData.AllScores(handles.SubData.RefIdx(handles.SubData.Index));
    if temp_ref~=0
        if temp_ref<=handles.SubData.metric
            warndlg('请认真打分！否则数据作废！');
            handles.Fault=handles.Fault+1;
            guidata(handles.SSCQS,handles);
            return
        end
    end
elseif sum(ismember(handles.SubData.RefIdx,handles.SubData.Index))~=0 %Ref
    Ref_QP42=handles.SubData.RefIdx(handles.SubData.IdxQP42); 
    Icorr_QP42=(Ref_QP42==handles.SubData.Index);
    IQP42=handles.SubData.IdxQP42(Icorr_QP42);
    if handles.SubData.metric<=max(handles.SubData.AllScores(IQP42))
        warndlg('请认真打分！否则数据作废！');
        handles.Fault=handles.Fault+1;
        guidata(handles.SSCQS,handles);
        return
    end
end

%Save the metric
handles.SubData.AllScores(handles.SubData.Index)=handles.SubData.metric;
if(handles.SubData.Count==handles.SubData.NumOfTestFiles)
    set(handles.Next,'Enable','off');
    
    %Save all ratings if testing phase
    
    [handles]=handles.SubData.SaveFn(handles);
    
    %Check if too many faults
    if(handles.Fault>=3)
        fid=fopen('check.txt','a','n','UTF-8');
        fprintf(fid,strrep(handles.SubData.OutputFilename,'\','\\'));
        fclose(fid);
        warndlg('打分出错过多，请联系管理员验证！');
    else
        msgbox('测试完成，谢谢参与.','测试完成','modal');
    end
    handles.output = 1;
    guidata(handles.SSCQS,handles);

    uiresume(handles.SSCQS);   
else
    set(handles.Next,'Enable','on');
    [handles]=InitializeSliderBar(handles);
    guidata(handles.SSCQS,handles);
end


% --- Executes on mouse press over axes background.
function SliderBar_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to SliderBar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%SubData=get(handles.SliderBar,'SubData');
handles.SubData.ButtonClickOnTrack=1;
set(handles.LineHandle,'visible','on');
guidata(handles.SSCQS,handles);

% --- Executes on mouse motion over figure - except title and menu.
function SSCQS_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to SSCQS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%SubData=get(handles.SliderBar,'SubData');

if(1==handles.SubData.ButtonClickOnTrack)
    %Get current location of mouse.
    CursorPosition=get(gca,'CurrentPoint');
    if((CursorPosition(1)>100))
        xPosition=100;
    elseif((CursorPosition(1)<0))
        xPosition=0;
    else
        xPosition=CursorPosition(1);
    end
    set(handles.LineHandle,'XData',[xPosition,xPosition]);
    set(handles.qtext,'String',xPosition);

    set(handles.LineHandle,'visible','on');
end

guidata(handles.SSCQS,handles);

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function SSCQS_WindowButtonUpFcn(hObject, eventdata, handles)
% hObject    handle to SSCQS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%SubData=get(handles.SliderBar,'SubData');
if(1==handles.SubData.ButtonClickOnTrack)
    %Get current location of mouse.

    metric=get(handles.LineHandle,'XData');
    handles.SubData.metric=metric(1);
    set(handles.LineHandle,'visible','on');
    handles.SubData.ButtonClickOnTrack=0;
    
    set(handles.Rate,'Enable','on');
end
guidata(handles.SSCQS,handles);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Internal functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [LineHandle,xPositionInScale]=DrawSlider(AxesHandle,LineHandle,xPosition,Bottom,Top)
Xlimit=get(AxesHandle,'Xlim');
XPos=get(AxesHandle,'Position');

xPositionInScale=(xPosition*Xlimit(2))/XPos(3);

set(LineHandle,'Parent',AxesHandle);
set(LineHandle,'visible','on');
SliderBarButtonDownFcn=get(AxesHandle,'ButtonDownFcn');
set(LineHandle,'ButtonDownFcn',SliderBarButtonDownFcn);

set(LineHandle,'XData',[xPositionInScale,xPositionInScale]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [handles]=InitializeSliderBar(handles)
%Marking the divisions for the different ranges
axes(handles.SliderBar);
Xlimit=get(handles.SliderBar,'Xlim');
XlimitMid=floor((Xlimit(1)+Xlimit(2))/2);

set(handles.LineHandle,'XData',[XlimitMid ,XlimitMid]);
set(handles.qtext,'String',XlimitMid);

x=[20,40,60,80;20,40,60,80;];
y=[0,0,0,0;1,1,1,1];
line(x,y,'Color','k');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [handles]=DisplayInstructions(handles)
tmp=get(handles.Phase,'String');
if(1==strcmpi('Training',tmp))
    filename='SSCQSTrainingInstructions.txt';
    filename=which(filename);    
else
    filename='SSCQSTestingInstructions.txt';
    filename=which(filename);
end

fid=fopen(filename);

if(-1==fid)
    error('无法读取测试指导');
else
    %msg=fread(fid,inf,'int8'); 
    msg=textread(filename,'%s');
    fclose(fid);
    set(handles.Instructions,'String',msg');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Args]=ParseInputs(varargin)
    Args.SessionType=[];
    Args.TargetType=[];
    Args.RawSubScoreFile=[];
    
    Args.TestFiles=[];
    Args.TestFormat=[];    
    Args.TestImageWidth=[];  
    Args.TestImageHeight=[];
        
    Args.mode=[];
    Args.AutoGenerateSubNum=1;
    Args.SubjectNum=[];
    
    Args.RefFiles=[];
    Args.SelSubTestMethod=[];
    
    Args.Player=[];
    Args.RefIdx=[];

    k=1;
    
    LengthArgIn=length(varargin);
    while (k <=LengthArgIn )
        arg = varargin{k};
        
        if(isfield(arg, 'Player'))
            Args.Player=arg.Player;
        end
        if(isfield(arg, 'RefIdx'))
            Args.RefIdx=arg.RefIdx;
        end
        if(isfield(arg, 'RefFiles'))
            Args.RefFiles=arg.RefFiles;
        end
        if(isfield(arg, 'SelSubTestMethod'))
            Args.SelSubTestMethod=arg.SelSubTestMethod;
        end
        if(isfield(arg, 'SessionType'))
            Args.SessionType=arg.SessionType;
        end
        if(isfield(arg, 'TargetType'))
            Args.TargetType=arg.TargetType;
        end
        if(isfield(arg,'mode'))
            Args.mode=arg.mode;
        end
        if(isfield(arg, 'TestFiles'))
            Args.TestFiles=arg.TestFiles;
        end
        if(isfield(arg, 'TestFormat'))
            Args.TestFormat=arg.TestFormat;
        end
        if(isfield(arg, 'TestImageWidth'))
            Args.TestImageWidth=arg.TestImageWidth;
        end
        if(isfield(arg, 'TestImageHeight'))
            Args.TestImageHeight=arg.TestImageHeight;
        end
        if(isfield(arg, 'RawSubScoreFile'))
            Args.RawSubScoreFile=arg.RawSubScoreFile;
        end           

        if(isfield(arg,'AutoGenerateSubNum'))
            Args.AutoGenerateSubNum=arg.AutoGenerateSubNum;
            if(0==Args.AutoGenerateSubNum)
               
                if(isfield(arg,'SubjectNum') &&(~isempty(arg.SubjectNum)))
                    Args.SubjectNum=arg.SubjectNum;
                else
                	%close(handles.SSCQS);
                    error('Subject number not specified','Missing Input','modal'); 
                end
            end    
        end
        
        k=k+1;
    end %while(k<=LengthArgIn)

    %Sanity check
    
    if(isempty(Args.SessionType))
        %close(handles.SSCQS);
        error('运行模式未指定','Missing Input','modal');        
    end
    if(isempty(Args.TestFiles))
        %close(handles.SSCQS);
        error('测试文件未指定','Missing Input','modal');        
    end
    if(isempty(Args.RawSubScoreFile))
        %close(handles.SSCQS);
        error('原始分数记录输出文件未指定','Missing Input','modal');        
    end
   
       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [handles]=InitializeSubData(handles,Args)
handles.Player=Args.Player;
handles.SubData.RefIdx=Args.RefIdx;
handles.Fault=0;

handles.SubData.NumOfTestFiles=length(Args.TestFiles);

handles.SubData.IsAppend=[];

handles.SubData.SaveFn=[];
handles.SubData.OutputFilename=Args.RawSubScoreFile;

handles.SubData.metric=[];
handles.SubData.voted=[0,0];
handles.SubData.AllScores=zeros(handles.SubData.NumOfTestFiles,1);

handles.SubData.TestFiles=Args.TestFiles;
handles.SubData.TestFormat=Args.TestFormat;    
handles.SubData.TestImageWidth=Args.TestImageWidth;  
handles.SubData.TestImageHeight=Args.TestImageHeight;  

%find index of qp42
IdxQP42=[];
for i_qp=1:size(handles.SubData.TestFiles,2)
    if ~isempty(strfind(handles.SubData.TestFiles{i_qp},'qp42'))
       IdxQP42=[IdxQP42,i_qp]; 
    end
end
handles.SubData.IdxQP42=IdxQP42;

handles.SubData.IsImageShown=zeros(handles.SubData.NumOfTestFiles,1);

if(strcmp(Args.TargetType,'q'))
    set(handles.TextTarget,'String','整体质量');
else
    set(handles.TextTarget,'String','各方向一致性');
end

%Random Method
if(strcmp(Args.SelSubTestMethod,'SSCQS'))
    handles.SubData.permutationVector=randperm(handles.SubData.NumOfTestFiles);
elseif(strcmp(Args.SelSubTestMethod,'MSCQS'))
    if(isempty(Args.RefFiles))
        error('未添加参考序列','Missing Input','modal');
    elseif(numel(Args.RefFiles)~=numel(Args.TestFiles))
        error('参考序列数目与测试序列数目不匹配','Missing Input','modal');
    else
        [~, RefIdx]=ismember(Args.RefFiles,Args.TestFiles);
        temptab=[RefIdx;1:numel(Args.TestFiles)];
        temptab=sortrows(temptab',1)';
        RefLines=unique(RefIdx);
        RefPermVector=randperm(length(RefLines));
        
%         tabRef=tabulate(Args.RefFiles);
%         statRef=(cell2mat(tabRef(:,2)))';
%         RefPermVector=randperm(length(statRef));
        TestPermVector=[];
        for i=1:length(RefPermVector)
            indexRef=RefLines(RefPermVector(i));
            SubgroupTest=temptab(2,find(temptab(1,:)==indexRef));
            tempPerm=randperm(numel(SubgroupTest));
            TestPermVector=[TestPermVector SubgroupTest(tempPerm)];
        end
        handles.SubData.permutationVector=TestPermVector;
    end
end

handles.SubData.Count=1;
handles.SubData.Index=handles.SubData.permutationVector(handles.SubData.Count);

handles.SubData.IsSliderDrawn=0;
handles.SubData.ButtonClickOnTrack=0;

handles.SubData.AutoGenerateSubNum=Args.AutoGenerateSubNum;
if(0==handles.SubData.AutoGenerateSubNum)
    handles.SubData.SubjectNumber=Args.SubjectNum;
else
    handles.SubData.SubjectNumber=1;
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [handles]=RenderVideo(handles)
videofile=handles.SubData.TestFiles{handles.SubData.Index};
videotemp=VideoReader(videofile);
duration=get(videotemp,'Duration');
framerate=get(videotemp,'FrameRate');
clear videotemp;
[path,subname,~]=fileparts(handles.SubData.OutputFilename);
[~,filename,~]=fileparts(videofile);

playerpath=[handles.Player.Path handles.Player.Name];

cmd1=['"' playerpath '" "' videofile '" & exit'];
cmdwait=['"' playerpath '" "' which('wait3.mp4') '"'];
fid = fopen('cmd.bat','w');
fprintf(fid,'%s',cmd1);
fclose(fid);

cmd2=[which('VRTracker.exe') ' -p ' path ' -s ' subname ...
    ' -f ' filename ' -d ' num2str(duration) ' -r ' num2str(framerate) ...
    ' -h 1078 -w 1'];

dos('cmd.bat &');
dos(cmd2);
dos(cmdwait);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [handles]=NoSave(handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [handles]=SaveScores(handles)


NumOfTestFiles=numel(handles.SubData.TestFiles);

%check if we need to append to an existing file.

if(1==handles.SubData.IsAppend)
    %Append data to end of file. If MOS is present in the file.
    [num,txt]=ReadTabulatedValues(handles.SubData.OutputFilename);
    %Update this subjects scores to the num array
    txt{1,end+1}=['Subject ' num2str(handles.SubData.SubjectNumber)];
    num(:,end+1)=handles.SubData.AllScores;    

else
    num=handles.SubData.AllScores;
    if(0==exist(handles.SubData.OutputFilename,'file'))
        %Generate num and txt arrays
        txt=cell(NumOfTestFiles+1,2); 
    else
        [~,txt]=ReadTabulatedValues(handles.SubData.OutputFilename);
        txt=cell(size(txt));
    end
    
    txt(1,1:2)={'Filename','Subject 1'};
    txt(2:(NumOfTestFiles+1),1)=handles.SubData.TestFiles';
end

%Write output.
OutputArray=txt;
OutputArray(2:size(num,1)+1,2:size(num,2)+1)=num2cell(num);

WriteRawSubScores(handles.SubData.OutputFilename,OutputArray);
