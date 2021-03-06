% program_wepp_hydrol_figs.m

% Author: Sheila Saia
% Email: sms493@cornell.edu
% Last Updated: Mar 1, 2013

% This program compiles all the daily WEPP outputs and generates daily andn
% yearly text files of water amount vs time for various hydrological
% processs including: overland flow, lateral flow, and percolation for each
% run. Sediment loss is also outputted vs time for each run.  Daily outputs
% from the daily WEPP hillslope hydrology model (i.e. water balance, ofe
% element, and crop files) must be saved as numerical text files prior to
% running this program.  Additionally, ofe data not included in the WEPP
% outputs must be saved in a numerical text file according to the format of
% associated tabs in 'sample_input_text_file_formats.txt'.

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
    % wat files
    baseFileNameuser=userinputfiles(h).name;
    fullFileNameuser=fullfile(weppfiles, baseFileNameuser);
    % Fixed input files
    baseFileNamefix=fixedinputfiles(h).name;
    fullFileNamefix=fullfile(weppfiles, baseFileNamefix);
    % File name input fils
    baseFileNamefile=filenamefiles(h).name;
    fullFileNamefile=fullfile(weppfiles,baseFileNamefile);
    
	% User defined inputs
	userinputdata=importdata(fullFileNameuser);
    % Number of ofe's
	numofe=userinputdata(3,1);
    % Fixed inputs
	fixedinputdata=importdata(fullFileNamefix);

    if userinputdata(37,1)==1 % Buffer
        run('sub_program_wepp_hydrol_figs_buff');
        % For plots see 'sub_program_wepp_hydrol_figs'

        % Generating text files for each run (daily)
        txtstr1=sprintf('day_wepp_output');
        txtstr2=sprintf('Run%02.0f',h);
        txtfile=[outputfolder,'\',txtstr1,'_',txtstr2,'.txt'];        
        dlmwrite(txtfile,dailydata);
        
        % Generating text files for each run (yearly average totals at
        % hillslope base)
        txtstr1=sprintf('year_AVGwepp_output_base');
        txtstr2=sprintf('Run%02.0f',h);
        txtfile=[outputfolder,'\',txtstr1,'_',txtstr2,'.txt'];        
        dlmwrite(txtfile,yearlyhillavgdata);
        
    else
        run('sub_program_wepp_hydrol_figs');
        % For plots see 'sub_program_wepp_hydrol_figs'

        % Generating text files for each run (daily)
        txtstr1=sprintf('day_wepp_output');
        txtstr2=sprintf('Run%02.0f',h);
        txtfile=[outputfolder,'\',txtstr1,'_',txtstr2,'.txt'];        
        dlmwrite(txtfile,dailydata);
        
        % Generating text files for each run (yearly average totals at
        % hillslope base)
        txtstr1=sprintf('year_AVGwepp_output_base');
        txtstr2=sprintf('Run%02.0f',h);
        txtfile=[outputfolder,'\',txtstr1,'_',txtstr2,'.txt'];        
        dlmwrite(txtfile,yearlyhillavgdata);
        
    end;
end;

%% Format of Output Text Files

% daily text files (if 3 ofes, i.e. no buffer)
% colm1: overland flow ofe 1 (mm/day)
% colm2: overland flow ofe 2 (mm/day)
% colm3: overland flow ofe 3 (mm/day)
% colm7: lateral flow ofe 1 (mm/day)
% colm8: lateral flow ofe 2 (mm/day)
% colm9: lateral flow ofe 3 (mm/day)
% colm10: percolation ofe 1 (mm/day)
% colm11: percolation ofe 2 (mm/day)
% colm12: percolation ofe 3 (mm/day)
% colm13: sediment loss ofe 1 (kg/day)
% colm14: sediment loss ofe 2 (kg/day)
% colm15: sediment loss ofe 3 (kg/day)
% colm16: net sediment loss ofe 1 (kg/day)
% colm17: net sediment loss ofe 2 (kg/day)
% colm18: net sediment loss ofe 3 (kg/day)
% colm19: precipitation ofe 1 (mm)
% colm20: precipitation ofe 2 (mm)
% colm21: precipitation ofe 3 (mm)
% colm22: evapotranspiration ofe 1 (mm)
% colm23: evapotranspiration ofe 2 (mm)
% colm24: evapotranspiration ofe 3 (mm)

% yearly text files (average for all simulations at base of hillslope)
% row1: precipitation (mm)
% row2: evapotranspiration (mm)
% row3: overland flow (mm)
% row4: lateral flow (mm)
% row5: percolation (mm)
% row6: sediment loss (kg)
% row7: net sediment loss (kg)

% Note: Rows indicate each similation day
