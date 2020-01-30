function homedir = experimentHomeFolder(monkey)

if nargin<1
    % choose monkey
    monkey = questdlg('Which Monkey?', ...
        'Monkey Menu', ...
        'Maeve','Jiji','Maeve');
end

env = getenv('COMPUTERNAME');

switch env
    case 'WITSHENEURO1'
        path = ['D:\Data\FlashProbe\' monkey '\'];
    case 'F7DDANWOO1NEUR'
        path = ['C:\Data\FlashProbe\' monkey '\'];
end
homedir = path;
% homedir = uigetdir(path,'Select which monkey:');