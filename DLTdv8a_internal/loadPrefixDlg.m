function  [pfix,cncl] = loadPrefixDlg(pname)

% function  [pfix,cncl] = loadPrefixDlg(pname)
%
% Function for getting a loadPrefix from the user, because Mathworks broke
% uigetfile

% get list of extant data prefixes in this intended directory or set an
% intelligent default
pfxs=dir([pname,filesep,'*xypts.*sv']);
if numel(pfxs)>0
  for i=1:numel(pfxs)
    pfxsCell{i}=pfxs(i).name(1:end-9);
  end
else
  pfxsCell{1}='No DLTdv8a data were found';
end

fp = [400,400];          % figure position (lower left corner x,y)
w = 200;                 % figure width
%h = 15*numel(pfxs)+200;  % figure height
h = 215; % figure height without the broken size adjustment [2024-03-01]
fp = [fp(1) fp(2) w h];  % set full figure position

% set figure properties
fig_props = { ...
  'name'                   'Data file prefix' ...
  'color'                  get(0,'DefaultUicontrolBackgroundColor') ...
  'resize'                 'off' ...
  'numbertitle'            'off' ...
  'menubar'                'none' ...
  'windowstyle'            'modal' ...
  'visible'                'on' ...
  'createfcn'              ''    ...
  'position'               fp   ...
  'closerequestfcn'        'delete(gcbf)' ...
  };

% draw the figure
fig = figure(fig_props{:});

% set instructions
instructions='Pick the prefix of the data file set to load.';

% draw text
txt = uicontrol('style','text', ...
  'position',[1 h-100, 200, 100], ...
  'string',instructions');

% draw listbox
listbox = uicontrol('style','listbox',...
  'position',[1 70 200 80],...
  'string',pfxsCell,...
  'backgroundcolor','w',...
  'max',1,...
  'tag','pfxListBox',...
  'value',1, ...
  'callback', {@doListboxClick});

% setup textbox
textbox = uicontrol('style','edit', ...
  'position',[1 40 200 20],...
  'backgroundcolor','w',...
  'tag','pfxEdit',...
  'string',pfxsCell{1},'visible','off');

% setup ok button
ok_btn = uicontrol('style','pushbutton',...
  'string','Load',...
  'position',[4 4 70 30],...
  'callback',{@doOK,listbox});

% setup cancel button
cancel_btn = uicontrol('style','pushbutton',...
  'string','Cancel',...
  'position',[128 4 70 30],...
  'callback',{@doCancel,listbox});

% wait for the user to do something
uiwait(fig);

% process results
if isappdata(0,'ListDialogAppData__')
  ad = getappdata(0,'ListDialogAppData__');
  pfix = ad.prefix;
  cncl = ad.cancel;
  rmappdata(0,'ListDialogAppData__')
else
  % figure was deleted
  pfix = '';
  cncl = true;
end

function [] = doListboxClick(varargin)

% function [] = doListBoxClick(varargin)
%
% Part of savePrefixDlg

% get string list
lb=findobj('tag','pfxListBox');
sl=get(lb,'string');
val=get(lb,'value');

% set text
eb=findobj('tag','pfxEdit');
set(eb,'string',char(sl(val)));

%% OK callback
function doOK(varargin)

% part of savePrefixDlg

% get text
eb=findobj('tag','pfxEdit');

ad.cancel = false;
ad.prefix = get(eb,'string');
setappdata(0,'ListDialogAppData__',ad);
delete(gcbf);

%% Cancel callback
function doCancel(varargin)

% part of savePrefixDlg

ad.cancel = true;
ad.prefix = '';
setappdata(0,'ListDialogAppData__',ad)
delete(gcbf);