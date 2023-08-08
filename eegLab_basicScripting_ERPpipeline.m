% EEGLab basic scripting: Automatic ERP pipeline
%
% Based on the EEGLab tutorial available on the website 
% https://eeglab.org/tutorials/11_Scripting/automated_pipeline.html
% Dataset used: multiple dataset from: https://openneuro.org/datasets/ds003061/versions/1.1.2/download
% Note: only considered the run 3 for the analysis to save time
% 
% What it does:
% - creates commands 
% - load/edit study 
%
% Author: Abin Jacob
% Date  : 06/08/2023

%% setting parameters
clear;
clc;
close all;

filePath = '/Users/abinjacob/Documents/02. NeuroCFN/Coding Practice/Data/task-P300_DATA run3-Only';

%% starting eeglab and load files
eeglab;

% allowing to process only one dataset at a time
pop_editoptions('option_storedisk',1);

% import data and create study 
[STUDY ALLEEG] = pop_importbids(filePath, 'studyName', 'oddball', 'subjects', [1:2]);

%% pre-processing data

% removing non-eeg channels 
ALLEEG = pop_select(ALLEEG, 'rmchannel', {'EXG1','EXG2','EXG3','EXG4','EXG5','EXG6', ...
    'EXG7','EXG8', 'GSR1', 'GSR2', 'Erg1', 'Erg2', 'Resp', 'Plet', 'Temp'});

% re-referencing (CAR)
ALLEEG = pop_reref(ALLEEG, []);

% clean data using clean_rawdata plugin
% note: channel criterion set to 7 as default settings were removing lot of channels
ALLEEG = pop_clean_rawdata(ALLEEG, 'FlatLineCriterion', 5, 'ChannelCriterion', 0.7, ...
    'LineNoiseCriterion', 4, 'Highpass', [0.75 1.25], 'BurstCriterion', 20, ...
    'WindowCriterion', 0.25, 'BurstRejection', 'on', 'Distance', 'Euclidian', ...
    'WindowCriterionTolerance', [-Inf 7], 'fusechanrej',1);

% recompute average reference and interpolating missing channel
ALLEEG = pop_reref(ALLEEG, [], 'interpchan', []);

%% compute ICA (Picard)

% runnig ICA
ALLEEG = pop_runica(ALLEEG, 'icatype', 'picard', 'concatcond', 'on', 'options', {'pca', -1});

% label artifacts 
ALLEEG = pop_iclabel(ALLEEG, 'default');
% flag artifacts 
ALLEEG = pop_icflag(ALLEEG, [NaN NaN; 0.9 1; 0.9 1; NaN NaN; NaN NaN; NaN NaN; NaN NaN]);

%% epoching

% note: events extracted are oddball_with_response & standard
ALLEEG = pop_epoch(ALLEEG, {'oddball_with_response', 'standard'}, [-1 2], 'epochinfo', 'yes');
ALLEEG = eeg_checkset(ALLEEG);
% remove baseline
ALLEEG = pop_rmbase(ALLEEG, [-1000 0], []);

%% create STUDY design

STUDY = std_maketrialinfo(STUDY, ALLEEG);
STUDY = std_makedesign(STUDY, ALLEEG, 1, 'name', 'STUDY.design1', 'delfiles', 'off', ...
    'defaultdesign', 'off', 'variable1', 'type', 'values1', {'oddball_with_response', 'standard'}, ...
    'vartype1', 'categorical', 'subjselect', {'sub-001', 'sub-002'});

%% precompute ERP at STUDY level
[STUDY ALLEEG] = std_precomp(STUDY, ALLEEG, {}, 'savetrials', 'on', 'rmicacomps', 'on', ...
    'interp', 'on', 'recompute', 'on', 'erp', 'on');

% plot ERP
% note time choosen is 350ms
STUDY = pop_erpparams(STUDY, 'topotime', 350);
% get chanlocs from all dataset
chanlocs = eeg_mergelocs(ALLEEG.chanlocs)
STUDY = std_erpplot(STUDY, ALLEEG, 'channels', {chanlocs.labels}, 'design', 1);

%% revert to default options 
pop_editoptions('option_storedisk', 0);


