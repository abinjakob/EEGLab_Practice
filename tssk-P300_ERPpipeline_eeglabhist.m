% EEGLab basic scripting: Automatic ERP pipeline from EEGLAB History
%
% Based on the EEGLab tutorial available on the website 
% https://eeglab.org/tutorials/11_Scripting/automated_pipeline.html
% Dataset used: multiple dataset from: https://openneuro.org/datasets/ds003061/versions/1.1.2/download
% Note: only considered the run 3 for the analysis to save time
%
% Author: Abin Jacob
% Date  : 08/08/2023

% open eeglab
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% import BIDS files
[STUDY, ALLEEG] = pop_importbids('/Users/abinjacob/Documents/02. NeuroCFN/Coding Practice/Data/task-P300_DATA run3-Only', 'eventtype','value','bidsevent','on','bidschanloc','on','outputdir','/Users/abinjacob/Documents/02. NeuroCFN/Coding Practice/Data/task-P300_DATA run3-Only/derivatives/eeglab');
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];

% remove unwanted channels
EEG = pop_select( EEG,'rmchannel',{'EXG1','EXG2','EXG3','EXG4','EXG5','EXG6','EXG7','EXG8','GSR1','GSR2','Erg1','Erg2','Resp','Plet','Temp'});
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, [1:6] ,'study',1); 
STUDY = std_checkset(STUDY, ALLEEG);

% re-referencing (CAR)
EEG = pop_reref( EEG,[]);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, [1:6] ,'study',1); 
STUDY = std_checkset(STUDY, ALLEEG);

% clean RAW data 
% note: channel criterion set to 0.7 as default settings would remove many channels
EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.7, ...
    'LineNoiseCriterion',4,'Highpass',[0.75 1.25] ,'BurstCriterion',20, ...
    'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian', ...
    'WindowCriterionTolerances',[-Inf 7] ,'fusechanrej',1);

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, [1:6] ,'study',1); 
STUDY = std_checkset(STUDY, ALLEEG);

% re-referencing aftercleaning and interpolating channels
EEG = pop_reref( EEG,[],'interpchan',[]);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, [1:6] ,'study',1); 
STUDY = std_checkset(STUDY, ALLEEG);

% applying ICA (Picard)
EEG = pop_runica(EEG, 'icatype','picard','concatcond','on','options',{'maxiter',500,'mode','standard'});
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
STUDY = std_checkset(STUDY, ALLEEG);

% label bad data
EEG = pop_iclabel(EEG, 'default');
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
STUDY = std_checkset(STUDY, ALLEEG);

% flagging bad data based on ICA (musscle and eye artefacts)
EEG = pop_icflag( EEG,[NaN NaN;0.9 1;0.9 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
STUDY = std_checkset(STUDY, ALLEEG);

% choosing dataset to 3 for plotting topogrophical map of ICA componenets
CURRENTSTUDY = 0;
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, [1:6] ,'retrieve',3,'study',1); 
% choosing first 35 components
pop_selectcomps(EEG, [1:35] );

% choosing dataset to 1 for plotting topogrophical map of ICA componenets
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'retrieve',1,'study',1); 
% choosing first 35 components
pop_selectcomps(EEG, [1:35] );

% choosing all the study dataset for further analysis
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'retrieve',[1:6] ,'study',1); 
CURRENTSTUDY = 1;

% epoching (events oddball_with_reponse & standard)
EEG = pop_epoch( EEG,{'oddball_with_reponse','standard'},[-1 2] ,'epochinfo','yes');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, [1:6] ,'study',1); 
STUDY = std_checkset(STUDY, ALLEEG);

% creating a STUDY and choosing variables
STUDY = std_makedesign(STUDY, ALLEEG, 1, 'name','STUDY.design 1','delfiles','off','defaultdesign','off','variable1','type','values1',{'oddball_with_reponse','standard'},'vartype1','categorical','subjselect',{'sub-001','sub-002','sub-003','sub-004','sub-005','sub-006'});
[STUDY EEG] = pop_savestudy( STUDY, EEG, 'savemode','resave');

% precomupting ERP
[STUDY, ALLEEG] = std_precomp(STUDY, ALLEEG, {},'savetrials','on','rmicacomps','on','interp','on','recompute','on','erp','on');
eeglab redraw;
