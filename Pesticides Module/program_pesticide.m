% program_pesticide.m

% Author: Sheila Saia
% Email: sms493@cornell.edu
% Last Updated: Mar 1, 2013

% This program calculates pesticide transport (dissolved and particulate
% bound) from ofe's for multiple runs and generates daily, monthly, and
% yearly text files of the outputs. Daily outputs from the daily WEPP
% hillslope hydrology model (i.e. water balance, ofe element, and crop
% files) must be saved as numerical text files prior to running this
% program.  Parameters and other info must be imported from
% 'userinpu*.txt', 'fixedinput*.txt', 'filename*.txt', and 'sched*.txt'
% files.

% References: Steenhuis and Walter 1980, Sinkevich et al 2005, Ghidey et
% al. 2005

%%
% Identify location of WEPP output text files
weppfiles='C:\Users\Sheila\Documents\MATLAB';
% Return a list of user and fixed input files
userinput=fullfile(weppfiles,'userinput*.txt');
fixedinput=fullfile(weppfiles,'fixedinput*.txt');
filenameinputs=fullfile(weppfiles,'filename*.txt');
% Define the user input and fixed input files in the current matlab
% directory
userinputfiles=dir(userinput);
fixedinputfiles=dir(fixedinput);
filenamefiles=dir(filenameinputs);
% Save all outputs to this folder
outputfolder=fullfile('C:\Users\Sheila\Documents\MATLAB\outputs');
% Set current directory (location of all program files)
cd('C:\Users\Sheila\Documents\MATLAB');

%%
for h=1:1:length(userinputfiles)
    % Select the files from the folder for each of k hillslopes 
    % User input files
    baseFileNameuser=userinputfiles(h).name;
    fullFileNameuser=fullfile(weppfiles, baseFileNameuser);
    % Fixed input files
    baseFileNamefix=fixedinputfiles(h).name;
    fullFileNamefix=fullfile(weppfiles, baseFileNamefix);
    % File name input files
    baseFileNamefile=filenamefiles(h).name;
    fullFileNamefile=fullfile(weppfiles,baseFileNamefile);
	
	% User defined inputs
	userinputdata=importdata(fullFileNameuser);
    % Number of ofe's
	numofe=userinputdata(3,1);
    % Fixed inputs
	fixedinputdata=importdata(fullFileNamefix);
        
    % Running the sub hydrology program to generate bar graphs for each
    % wepp run.  Note that the sub program that is chosen depends on
    % whether the there is a buffer or not.    
    if userinputdata(37,1)==1 % Buffer
        % Running the sub program pesticide model with buffer
        run('sub_program_pesticide_buff');

        % Generating text files for each run (daily scaled to a single ofe 
        % in kg/m^2)
         txtstr1=sprintf('day_output');
         txtstr2=sprintf('pestRun%02.0f',h);
         txtfile=[outputfolder,'\',txtstr1,'_',txtstr2,'.txt'];        
         dlmwrite(txtfile,dailyPestdatakgm2);
        
        % Generating text files for each run (monthly average totals at 
        % hillslope base in kg/ha)
         txtstr1=sprintf('month_AVGoutput_base');
         txtstr2=sprintf('pestRun%02.0f',h);
         txtfile=[outputfolder,'\',txtstr1,'_',txtstr2,'.txt'];        
         dlmwrite(txtfile,monthlyPesthillavgdata);

        % Generating text files for each run (yearlyaverage totals at
        % hillslope base in kg/ha)
        txtstr1=sprintf('year_AVGoutput_base');
        txtstr2=sprintf('pestRun%02.0f',h);
        txtfile=[outputfolder,'\',txtstr1,'_',txtstr2,'.txt'];        
        dlmwrite(txtfile,yearlyPesthillavgdata);
        
    else
        % Running the sub program pesticide model
        run('sub_program_pesticide');

        % Generating text files for each run (daily scaled to a single ofe 
        % in kg/m^2)
         txtstr1=sprintf('day_output');
         txtstr2=sprintf('pestRun%02.0f',h);
         txtfile=[outputfolder,'\',txtstr1,'_',txtstr2,'.txt'];        
         dlmwrite(txtfile,dailyPestdatakgm2);
        
        % Generating text files for each run (monthly average totals at 
        % hillslope base in kg/ha)
         txtstr1=sprintf('month_AVGoutput_base');
         txtstr2=sprintf('pestRun%02.0f',h);
         txtfile=[outputfolder,'\',txtstr1,'_',txtstr2,'.txt'];        
         dlmwrite(txtfile,monthlyPesthillavgdata);

        % Generating text files for each run (yearlyaverage totals at
        % hillslope base in kg/ha)
        txtstr1=sprintf('year_AVGoutput_base');
        txtstr2=sprintf('pestRun%02.0f',h);
        txtfile=[outputfolder,'\',txtstr1,'_',txtstr2,'.txt'];        
        dlmwrite(txtfile,yearlyPesthillavgdata);
        
        % Figures are saved within each run.
    end;
end;

%% Format of Output Text Files

% daily text files
% Note: we assume 3 ofes here and each row represents a simulation day
% colm 1-3: pesticide left in the top layer for ofe 1 to 3 (kg/m^2)
% colm 4-6: pesticide left in the bottom layer for ofe 1 to 3 (kg/m^2)
% colm 7-9: total pesticide lost in overland flow for ofe 1 to 3 (kg/m^2)
% colm 10-12: dissolved pesticide lost in overland flow for ofe 1 to 3
% (kg/m^2)
% colm 13-15: adsorbed pesticide lost in overland flow for ofe 1 to 3
% (kg/m^2)
% colm 16-18: pesticide lost in lateral flow for ofe 1 through 3 (kg/m^2)
% colm 19-21: pesticide lost in shallow percolation for ofe 1 to 3 (from
% top layer into bottom layer) (kg/m^2)
% colm 22-24: pesticide lost in deep percolation for ofe 1 to 3 (kg/m^2)
% colm 25: (buffer runs only) particulate pesticide trapped by buffer
% (kg/m^2)

% monthly text files (average for all simulations at hillslope base)
% colm1: month
% colm2: adsorbed pesticide lost in overland flow (kg/ha)
% colm3: dissolved pesticide lost in overland flow (kg/ha)
% colm4: pesticide lost in lateral flow (kg/ha)
% colm5: pesticide lost in deep percolation (kg/ha)

% yearly text files (average for all simulations at hillslope base)
% row1: adsorbed pesticide lost in overland flow (kg/ha)
% row2: dissolved pesticide lost in overland flow (kg/ha)
% row3: pesticide lost in lateral flow (kg/ha)
% row4: pesticide lost in deep percolation (kg/ha)
