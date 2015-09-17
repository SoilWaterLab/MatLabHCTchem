# MatLabHCTchem
This repository contains the MatLab code for the HCT-chem model developed for Sheila Saia's MS project.  It is meant to be used in conjunction with the USDA WEPP model for predicting transport of P, N, and pesticide at the hillslope scale.


## Contact Information ##
Author: Sheila Saia
Email: sms493@cornell.edu
Updated: September 15, 2015


## HCT-chem Model Description ##

The associated ZIP file (HCT-chem_codeZIP.zip) provides the chemistry transport algorithm codes running behind the web-based Hydrologic Characterization Tool (HCT) developed by Erin Brooks et al. at the University of Idaho.  The tool can be accessed at http://wepp.ag.uidaho.edu/cgi-bin/HCT.pl/.  The chemistry algorithms use outputs from the United States Depart of Agriculture’s (USDA) Water Erosion Prediction Project (WEPP) model as inputs and are capable of predicting pesticide transport, phosphorus transport, and nitrogen transport from overland flow, lateral subsurface flow, percolation, and sediment erosion rates for a variety of climates, landscape types, soil types, and cropping systems.  The overall goal of this easy-to-use, web-based tool is to help watershed managers gain a better conceptual understanding of the dominant hydrologic processes occurring within a landscape of interest.  If they are better able to identify critical source areas with their local landscape they can suggest more effective management practices, and this in turn, will improve water quality.  For more information on the motivation for this project visit: http://wepp.ag.uidaho.edu/HCT_Motivation_Development_Background.pdf.


## HCT-chem Model Use ##

The MatLab code for the pesticide module is structured into five main files. The main pesticide program file (program_pesticide.m), the two sub pesticide program files depending on whether a vegetated buffer is present in the run (sub_program_pesticide.m and sub_program_pesticide_buff.m), and the two pesticide function files also depending on whether a vegetated buffer is present in the run (dailyofePestsimTrans.m and dailyofePestsimTransBuff.m). Seven different text file inputs are needed to initiate each run.  Of the seven files, three are from WEPP, including the water balance file (wat*.txt), the OFE line summary file (elem*.txt), and the plant file (crop*.txt). The ‘*’ indicates the number of the WEPP run, which must be given in at least two places (e.g. 1 as 01) and must be consecutive starting at 1. The four remaining input files include the user defined input file (userinput*.txt), the fixed input file (fixedinput*.txt), the file name path file (filename*.txt), and the scheduling file (sched*.txt) for each run.  The soil file (soil*.txt) is also included here but can be extracted from the WEPP file (text must be removed).  The weighted average of soil properties for the entire profile, which is needed for the user defined input file, can be calculated by running the avg_soil_properties.m script in MatLab.  Please see the 'Sample Input Text File' directory for sample input text files for two hypothetical runs (Run 01 and Run 02).  Also within this directory, please see the sample_input_text_file_formats_Run01_and_Run02.xlxs for easier to read input file formatting.  The same information is also preserved in the sample_input_text_file_formats_Run01.csv and sample_input_text_file_formats_Run02.csv files.

It should be noted that to run the avg_soil_properties.m file located in the 'Soil Calculations' directory must also load in the specific 'sched*.txt' file associated with that run.  All input text files must have text headers removed for the MatLab program to run them without errors.  All input files and model '.m' files must be located in the 'MATLAB' default directory on the pc processing the files.  This is typically accessible throught the pc's 'Documents' directory.  The current directory name should be edited in the program_pesticides.m file so that it follows the computer's path to the MatLab file.  For example the current directory Matlab on my computer is 'C:\Users\Sheila\Documents\MATLAB'.  There must also be a directory labeled 'outputs' in this MatLab directory in order for the program to print out text files of daily, monthly, and yearly pesticide losses.  This output location must also be specified in the 'program_pesticides.m' file.  For example, on my computer the outputs are sent to the empty output directory (called 'outputs') with the path 'C:\Users\Sheila\Documents\MATLAB\outputs'.  All output files will be sent to this directory.  Once all of the files are in order and loaded into the MatLab directory, you can open the Windows Command Prompt and type 'matlab -r program_pesticide.m' and it will run all of the simulations of which you have corresponding input files.  Sample output files are also provided within each directory of the model components.  Please see the program_pesticide.m, program_p.m, and program_n.m files for information on output formatting. 

The phosphorus and nitrogen models run exactly the same as the pesticide model but have a few more additional MatLab function files that need to be moved to the MatLab directory before runnning.  For example, the phosphorus model has the arrhenius.m function to calculate the impact of temperature on reaction rates.  Similarly, the nitrogen model has the arrhenius.m function as well as the moistfact.m and microbfact.m functions to determin the impact of water content on denitrifying bacteria. 

Each '.m' file is also saved as a '.txt' file so users without MatLab can view model files.

## HCT-chem MatLab Files ##

Pesticides Model .m Files
Note: Indentation below represent program heirarchy of information flow and whether program is called.
program_pesticide.m
    	sub_program_pesticide.m
    		dailyofePestsimTrans.m
    	sub_program_pesticide_buff.m
    		dailyofePestsimTransBuff.m

Phosphorus Model .m Files
Note: Indentation below represent program heirarchy of information flow and whether program is called.
program_p.m
	sub_program_p.m
		dailyofePsimTrans.m
			arrhenius.m
	sub_program_p_buff.m
		dailyofePsimTransBuff.m
			arrhenius.m
			
Nitrogen Model .m Files
Note: Indentation below represent program heirarchy of information flow and whether program is called.
program_n.m
	sub_program_n.m
		dailyofeNsiM1layTrans.m
			arrhenius.m
			moistfact.m
			microbfact.m
	sub_program_n_buff.m
		dailyofeNsiM1layTransBuff.m
			arrhenius.m
			moistfact.m
			microbfact.m

Please see the sample output folder in each chemistry module's directory for information on output formatting (ReadMe_*.txt).


## HCT-chem Licensing ##

Please be sure to contact Sheila Saia at sms493@cornell.edu if you use or modifiy  any aspects of this program.  HCT-chem is made available under the Open Data Commons Attribution License: http://opendatacommons.org/licenses/by/1.0.  For the human readible version of the Open Data Commons Attribution License: http://opendatacommons.org/licenses/by/summary/.

## Associated Peer Reviewed Publications ##

The pesticides component of this model was featured in two peer reviewed publications (see below).
Brooks, E.S., S.M. Saia, J. Boll, L. Wetzel, Z.M. Easton, T.S. Steenhuis. 2015. Assessing BMP Effectiveness and Guiding BMP Planning Using Process-Based Modeling. Journal of the American Water Resources Association. 51(2):343-358.

Saia, S.M., E.S. Brooks, Z.M. Easton, C. Baffaut, J. Boll, and T.S. Steenhuis. 2013. Incorporating Pesticide Transport into the WEPP-UI Model for Mulch Tillage and No Tillage Plots with an Underlying Claypan Soil. Applied Engineering in Agriculture. 29(3):373-382.
