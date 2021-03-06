% program_n.m

% Author: Sheila Saia
% Email: sms493@cornell.edu
% Last Updated: Mar 1, 2013

% This program calculates N transport (inorganic and organic N) from ofe's
% for multiple runs and generates a yearly text and bar graph for each run.
% Daily outputs from the daily WEPP hillslope hydrology model (i.e. water
% balance, ofe element, and crop files) must be saved as numerical text
% files prior to running this program.  Parameters and other info must be
% imported from 'userinpu*.txt', 'fixedinput*.txt', 'filename*.txt', and
% 'sched*.txt' files.

% References: Johnsson et al 1987, SWAT Theoretical Documentation (USDA
% 2005 ch 3:1,4:2), Heinen et al 2006, Berstrom et al 1991, Meyer at al
% 2007, Williams et al 1984, Stotte et al 1986?, Brutsaert 1982

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
        % Running the sub program n model with buffer
        run('sub_program_n_buff');

        % Generating text files for each run (daily scaled to a single ofe 
        % in kg/m^2)
         txtstr1=sprintf('day_output');
         txtstr2=sprintf('NRun%02.0f',h);
         txtfile=[outputfolder,'\',txtstr1,'_',txtstr2,'.txt'];        
         dlmwrite(txtfile,dailyNlostdatakgm2);
         
        % Generating N pool text files  for each run (daily scaled to a
        % single ofe in kg/m^2)
        txtstr1=sprintf('day_pool_output');
         txtstr2=sprintf('NRun%02.0f',h);
         txtfile=[outputfolder,'\',txtstr1,'_',txtstr2,'.txt'];        
         dlmwrite(txtfile,dailyNpooldatakgm2);
        
        % Generating text files for each run (monthly average totals at 
        % hillslope base in kg/ha)
         txtstr1=sprintf('month_AVGoutput_base');
         txtstr2=sprintf('NRun%02.0f',h);
         txtfile=[outputfolder,'\',txtstr1,'_',txtstr2,'.txt'];        
         dlmwrite(txtfile,monthlyNhillavgdata);

        % Generating text files for each run (yearlyaverage totals at
        % hillslope base in kg/ha)
        txtstr1=sprintf('year_AVGoutput_base');
        txtstr2=sprintf('NRun%02.0f',h);
        txtfile=[outputfolder,'\',txtstr1,'_',txtstr2,'.txt'];        
        dlmwrite(txtfile,yearlyNhillavgdata);
        
    else
        % Running the sub program n model
        run('sub_program_n');

        % Generating text files for each run (daily scaled to a single ofe 
        % in kg/m^2)
         txtstr1=sprintf('day_output');
         txtstr2=sprintf('NRun%02.0f',h);
         txtfile=[outputfolder,'\',txtstr1,'_',txtstr2,'.txt'];        
         dlmwrite(txtfile,dailyNlostdatakgm2);
         
        % Generating N pool text files for each run (daily scaled to a
        % single ofe in kg/m^2)
        txtstr1=sprintf('day_pool_output');
         txtstr2=sprintf('NRun%02.0f',h);
         txtfile=[outputfolder,'\',txtstr1,'_',txtstr2,'.txt'];        
         dlmwrite(txtfile,dailyNpooldatakgm2);         
        
        % Generating text files for each run (monthly average totals at 
        % hillslope base in kg/ha)
         txtstr1=sprintf('month_AVGoutput_base');
         txtstr2=sprintf('NRun%02.0f',h);
         txtfile=[outputfolder,'\',txtstr1,'_',txtstr2,'.txt'];        
         dlmwrite(txtfile,monthlyNhillavgdata);

        % Generating text files for each run (yearlyaverage totals at
        % hillslope base in kg/ha)
        txtstr1=sprintf('year_AVGoutput_base');
        txtstr2=sprintf('NRun%02.0f',h);
        txtfile=[outputfolder,'\',txtstr1,'_',txtstr2,'.txt'];        
        dlmwrite(txtfile,yearlyNhillavgdata);
        
        % Figures are saved within each run.
    end;
end;  

%% Format of Output Text Files

% daily loss text files 
% Note: we assume 3 ofes here, columns depend on the number of ofes
% colm 1-3: no3 lost in overland flow (no sed) (kg/m^2)
% colm 4-6: no3 lost in lateral flow (no sed) (kg/m^2)
% colm 7-9: no3 lost in perc (no sed) (kg/m^2)
% colm 10-12: no3 lost to the the atmosphere (denitrification) (kg/m^2)
% colm 13-15: active orgN lost in overland flow (w/sed) (kg/m^2)
% colm 16-18: fresh orgN lost in overland flow (w/sed) (kg/m^2)
% colm 19-21: stable orgN lost in overland flow (w/sed) (kg/m^2)
% colm 22-24: total inorganic N lost (sum of col1 to col5) (kg/m^2)
% colm 25-27: total organic N lost (sum of col6 to col9) (kg/m^2)
% colm 28: (buffer runs only) particulate N trapped by buffer
% (kg/m^2)

% daily pools text files
% Note: we assume 3 ofes here, columns depend on the number of ofes
% colm 1-3: nh4 (kg/m^2)
% colm 4-6: no3 (kg/m^2)
% colm 7-9: plantN (kg/m^2)
% colm 10-12: orgNact (kg/m^2)
% colm 13-15: orgNfrsh (kg/m^2)
% colm 16-18: orgNstab (kg/m^2)
% colm 19-21: cact (kg/m^2)
% colm 22-24: cfrsh (kg/m^2)
% colm 25-27: cstab (kg/m^2)

% monthly text files (average for all simulations at hillslope base)
% colm1: month
% colm2: organic N lost in overland flow (w/sed) (kg/ha)
% colm3: inorganic N lost in overland flow (no sed) (kg/ha)
% colm4: N lost in lateral flow (kg/ha)
% colm5: N lost in deep percolation (kg/ha)
% colm6: N lost to the atmostphere (kg/ha)

% yearly text files (average for all simulations at hillslope base)
% row1: adsorbed N lost in overland flow (kg/ha)
% row2: dissolved N lost in overland flow (kg/ha)
% row3: N lost in lateral flow (kg/ha)
% row4: N lost in deep percolation (kg/ha)
% row5: N lost to the atmosphere (kg/ha)

