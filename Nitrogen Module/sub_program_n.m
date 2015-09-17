% sub_program_n.m

% Author: Sheila Saia
% Email: sms493@cornell.edu
% Last Updated: Mar 1, 2013

% This file is needed to run 'program_n.m'. It initializes matrices and
% defines parameters based on wat, elem, crop, soil, and ofe files loaded
% in from 'program_n.m'.

% References: Johnsson et al 1987, SWAT Theoretical Documentation (USDA
% 2005 ch 3:1,4:2), Heinen et al 2006, Berstrom et al 1991, Meyer at al
% 2007, Williams et al 1984, Stotte et al 1986?, Brutsaert 1982

%% Import wat, crop, elem, sched, filename files.

openfile=fopen(fullFileNamefile);
filenames=textscan(openfile,'%q');
fclose(openfile);
% WEPP water balance files give water depths for hydrologic processes
watdata=importdata(filenames{1}{1});
% WEPP crop files give detailed crop variables
cropdata=importdata(filenames{1}{2});
% WEPP element output files give some crop growth outputs, erosion
% outputs, and runoff
elemdata=importdata(filenames{1}{3});
% WEPP schedule output files give application, planting, harvest dates, and
% maximum rooting depth.
scheddata=importdata(filenames{1}{4});

%% Notes

% Unless marked otherwise these common itterators are used
% i=day number (cumulative over the entire simulation)
% j=month number
% k=year number
% Baseflow is not included here.  The only processes we focus on are
% overland flow (with sediment and without), lateral flow, and percolation.

%% Parameters

% ofe number
ofelst=watdata(:,1);
% ofe lengths (m)
ofeLength=userinputdata(38,1:numofe);
% Sum ofe lengths (m)
ofeLengthsum=sum(ofeLength);

%% Water Balance Output File 

% col1: ofe
% col2: day of the year (out of 365)
% col3: year
% col4: precipitation (snow or rain) (mm)
% col5: rainfall+irrigation+snowmelt (mm)
% col6: daily runoff over eff length (mm)
% col7: plant transpration (mm)
% col8: soil evap (mm)
% col9: residue evap (mm)
% col10: deep perc (mm)
% col11: runon added to ofe (mm)
% col12: subsurface ruon added to ofe (mm)
% col13: lateral flow (mm)
% col14: total soil water (unfrozen water in soil) (mm)
% col15: frozen water in soil profile (mm)
% col16: water in surface snow (mm)
% col17: daily runoff scaled to single ofe (mm)
% col18: tile drainage (mm)
% col19: irrigation (mm)
% col20: area that ddepths apply over (m^2)
[watrow,watcol]=size(watdata);

%% WEPP Element Output File 

% This file only prints out days when there is a water related event
% (rainfall, snowfall, runoff, etc.).
% colm1: ofe id
% colm2: day of the month (I convert to a cumulative day over the entire
% simulation period - see below)
% colm3: month
% colm4: year
% colm5: precipitation (snow or rain) (mm)
% colm6: runoff (mm)
% colm7: Effective intensity (mm/h)
% colm8: peak runoff (mm/h)
% colm9: Effective duration (h)
% colm10: enrichment ratio
% colm11: Keff (effective hydrolic conductivity of the surface soil - mm/h)
% colm12: Sm (total soil water content - mm)
% colm13: leaf area index (LAI - no units)
% colm14: canopy height (m)
% colm15: canopy cover (%)
% colm16: interill cover (%)
% colm17: rill cover (%)
% colm18: live biomass (kg/m^2)
% colm19: dead biomass (kg/m^2)
% colm20: Ki (interill erosion coefficient - )
% colm21: Kr (rill erosion coefficient - ) 
% colm22: Tcrit? (C)
% colm23: Rill width (m)
% colm24: sediment leaving (kg/m)
[elemrow,elemcol]=size(elemdata);

% Identifying leap years
mlst=[31,28,31,30,31,30,31,31,30,31,30,31];
mlstleap=[31,29,31,30,31,30,31,31,30,31,30,31];
% Month per year
mpy=12;
% Days in year (with leap year)
dayINyearlst=zeros(max(watdata(:,3)),1);
yrs=1:1:max(watdata(:,3));
for k=1:1:max(watdata(:,3));
   if mod(yrs(k),4)==0
       dayINyearlst(k)=366;
   else
       dayINyearlst(k)=365;
   end;   
end;
% Days in year (with leap year), long list (non-cumulative)
dayINyearlonglst=zeros(watrow,1);
for i=1:1:watrow
   if mod(watdata(i,3),4)==0
       dayINyearlonglst(i)=366;
   else
       dayINyearlonglst(i)=365;
   end;   
end;

% Modify the days so they are cumulative for the year and can be used as a
% id key for combination with other WEPP files.
dlst=zeros(elemrow,1);
for i=1:1:elemrow
    if elemdata(i,3)==1
        dlst(i)=elemdata(i,2);
    elseif elemdata(i,3)>1 && mod(elemdata(i,4),4)==0
        cum=sum(mlstleap(1:(elemdata(i,3))-1));
        dlst(i)=elemdata(i,2)+cum;
    elseif elemdata(i,3)>1 && mod(elemdata(i,4),4)~=0
        cum=sum(mlst(1:(elemdata(i,3))-1));
        dlst(i)=elemdata(i,2)+cum;
    end;  
end;

% Add dlst back into the element file
elemdata=[elemdata(:,1),dlst,elemdata(:,3:elemcol)];

% Uses dlst to make the days cumulative for the entire time period
elemid=zeros(elemrow,1);
for i=1:1:elemrow
    if elemdata(i,4)>1
       elemid(i)=elemdata(i,2)+sum(dayINyearlst(1:elemdata(i,4)-1));
    else   
       elemid(i)=elemdata(i,2);
    end;    
end;

% Add in the daily identifier that is unique for the entire time period
% (e.g. 10 years)
elemdata=[elemdata(:,1),elemid,elemdata(:,3:elemcol)];
[elemrow,elemcol]=size(elemdata);

%% Plant and Residue Output File 

% colm1: ofe
% colm2: day of the year
% colm3: year
% colm4: canopy height (m)
% colm5: canopy cover (%)
% colm6: leaf area index (LAI - no units)
% colm7: rill cover (%)
% colm8: interill cover (%)
% colm9: crop id #
% colm10: live biomass
% colm11: standing residue mass (kg/m^2)
% colm12: crop id # for the last crop harvested
% colm13: flat residue mass for the last crop harvested (kg/m^2)
% colm14: crop id # for the previous crop harvested
% colm15: flat residue mass for the previous crop harvested (kg/m^2)
% colm16: crop id # for all previous crops harvested
% colm17: flat residue mass for all previous crops harvested (kg/m^2)
% colm18: buried residue mass for the last crop harvested (kg/m^2)
% colm19: buried residue mass for the previous crop harvest (kg/m^2)
% colm20: buried residue mass for all previous crops harvested (kg/m^2)
% colm21: crop id # for the last crop harvested
% colm22: dead root mass for the last crop harvested (kg/m^2)
% colm23: crop id # for the previous crop harvested
% colm24: dead root mass for the previous crop harvested (kg/m^2)
% colm25: crop id # for all previous crops harvested
% colm26: dead root mass all previous crops harvested (kg/m^2)
% colm27: average temp (C)
% colm28: sediment (kg/m)
[croprow,cropcol]=size(cropdata);
% Crop type
croptype=cropdata(:,9);

% Create a daily identifier for the entire run.
srtyr=min(cropdata(:,3));
endyr=max(cropdata(:,3));
cropid=zeros(croprow,1);
for i=1:1:croprow
    if cropdata(i,3)>srtyr
        cropid(i)=cropid(i-numofe)+1;
    else
        cropid(i)=cropdata(i,2);    % Returns first year as is
    end;    
end;

% Add in the daily identifier
cropdata=[cropdata(:,1),cropid,cropdata(:,3:cropcol)];

% Add in sediment and soil moisture
a=[elemdata(:,2),elemdata(:,24)];           % Sediment (kg/m)
sednewlst=zeros(croprow,1);                 % New matrix (sediment in col 1, sm in col 2)
for i=1:1:elemrow
    % Sediment
    if a(i,2)>0
        idlook=a(i,1:2);                    % Identify sediment event day
        x=find(cropdata(:,2)==idlook(1),1); % Identify associated row id for the day (one row for each ofe so have to adjust for this by subtracting 1)
        sednewlst(x+elemdata(i,1)-1)=idlook(2);
    end;     
end;
cropdata=[cropdata,sednewlst];
[croprow,cropcol]=size(cropdata);
        
%% Final Compiled Water Balance File 

% col1: ofe
% col2: day identifier
% col3: day of the month
% col4: year
% col5: precipitation (snow or rain) (mm)
% col6: rainfall+irrigation+snowmelt (mm)
% col7: daily runoff over eff length (mm)
% col8: plant transpration (mm)
% col9: soil evap (mm)
% col10: residue evap (mm)
% col11: deep perc (mm)
% col12: runon added to ofe (mm)
% col13: subsurface ruon added to ofe (mm)
% col14: lateral flow (mm)
% col15: total soil water (unfrozen water in soil) (mm)
% col16: frozen water in soil profile (mm)
% col17: water in surface snow (mm)
% col18: daily runoff scaled to single ofe (mm)
% col19: tile drainage (mm)
% col20: irrigation (mm)
% col21: area that ddepths apply over (m^2)
% col22: sediment (kg/m)
% col23: leaf area index (LAI - no units)
% col24: average temperature (C)
% col25: row id (#)

id=1:1:watrow;
watdata=[watdata(:,1),cropdata(:,2),watdata(:,2:watcol),cropdata(:,28),cropdata(:,6),cropdata(:,27),transpose(id)];
[watrow,watcol]=size(watdata);

%% Scheduling File

% colm1: year
% colm2: crop id # (corresponds to crop type)
% colm3: application date (day of year)
% colm4: application amount for OFE1
% colm5: application amount for OFE2
% colm6: application amount for OFE3
% colm7: applicaiton amount for OFE 4 (buffer)
% colm8: plant date (day of year) (only for non-buffer OFEs)
% colm9: harvest date (day of year) (only for non-buffer OFEs)
% colm10: plow date (day of year)
% colm11: tillage depth (m)
% colm12: crop root depth (m)
% colm13: buffer root depth (m)
% colm14: N Fertilizer Code (1=manure, 2=fertilizer)

%% Defining Inputs from WEPP

% Number of simulation days
numsimdays=sum(dayINyearlst);
% Number of years
numyrs=max(elemdata(:,4));
% Number of days
noncumdaylst=watdata(:,3);
% Day identifier
daylst=watdata(:,2);
% Day of the month
dayofmnthlst=watdata(:,3);
% Year
yrlst=watdata(:,4);
% Precipitation (snow or rain) (m) (non-cumulative)
precip=watdata(:,5)./1000;
% Rainfall+snowmelt+irrigation (m) (non-cumulative)
ris=watdata(:,6)./1000;
% Calculate the area of the ofe
ofeWidth=userinputdata(39,:);
ofeArea=ofeLength.*ofeWidth;
% Overland flow scaled to single ofe (mm)
ovldf=watdata(:,18)/1000;
% Lateral flow passing through the OFE (mm)
latf=watdata(:,14)/1000;
% Percolation (m) (non-cumulative)
perc=watdata(:,11)./1000;
% Cumulative sediment leaving an OFE per width (kg/m)
sedkgm=watdata(:,22);
% Cumulative ediment leaving an OFE (kg)
sed=zeros(watrow,1);
for i=1:1:watrow
    sed(i)=sedkgm(i)*ofeWidth(watdata(i,1));
end;
% Net sediment loss (kg) (non-cumulative)
netsed=zeros(watrow,1);
for i=2:1:watrow
    if watdata(i,1)>1
        mass=sedkgm(i)*ofeWidth(watdata(i,1));
        massprev=sedkgm(i-1)*ofeWidth(watdata(i-1,1));
        netsed(i)=mass-massprev;
    else
        mass=sedkgm(i)*ofeWidth(watdata(i,1));
        netsed(i)=mass;
    end;
end;
% Crop transpiration (m)
cropevap=watdata(:,8)./1000;
% Soil evaporation (m)
soilevap=watdata(:,9)./1000;
% Residue evaporation (m)
residueevap=watdata(:,10)./1000;
% Evapotranspiration (m)
et=cropevap+soilevap+residueevap;
% Soil moisture (m)
soilmoist=watdata(:,15)./1000;
% Average temp (C)
avgT=watdata(:,24);

%% Parameters

% Initialize parameters for each crop
ps=zeros(max(croptype),numofe);
om=zeros(max(croptype),numofe);
thetaS=zeros(max(croptype),numofe);
thetaFC=zeros(max(croptype),numofe);
thetaWP=zeros(max(croptype),numofe);
for o=1:1:numofe
    for c=1:1:max(croptype);
        % Soil bulk density (g/cm^3)
        ps(c,o)=userinputdata(5+c-1,o);
        % Convert ps to kg/m^3
        ps(c,o)=ps(c,o)*1000;
        % Water content at saturation, import from WEPP
        thetaS(c,o)=userinputdata(9+c-1,o);
        % Field capacity (thetaFC)
        thetaFC(c,o)=userinputdata(13+c-1,o);
        % Wilding point capacity (thetaWP)
        thetaWP(c,o)=userinputdata(17+c-1,o);        
        % Percent organic matter in the mixing layer
        om(c,o)=userinputdata(21+c-1,numofe);
    end;
end;
% Max root depth (m), for each crop
% Second colm is buffer root depth
rootdepthshrt=scheddata(:,12:13);
rootdepth=zeros(croprow,1);
for i=1:1:croprow
    rflag=find(scheddata(:,1)==cropdata(i,3));
    r=rootdepthshrt(rflag,1);
    rsel=unique(r);
    rootdepth(i)=rsel;     
end;
% Incorporation (yes=1, no=0);
incorp=userinputdata(25,:);
% Percent organic carbon
oc=(om./100).*0.58;
% Density of water (g/cm^3) at 20C
pw=0.9980;
% Convert pw to kg/m^3
pw=pw*1000;
% Nitrate at the surface (ppm) (from SWAT ch 3 says 7ppm)
no3surf=userinputdata(35,:);
% Fraction of active N in manure (from SWAT ch 3)
fact=fixedinputdata(8);
% Fraction of roots above the ground after harvest (from Johnsson)
fabove=0.1;
% Fraction of roots left (for annual crop) aka live root fraction  (from
% Johnsson)
fleft=0; %for annual crop
% Fraction of roots harvested (from Johnsson)
fharv=0.6;
% Fraction of available mineral N (from Johnsson)
fmax=fixedinputdata(9);
% Fraction of N transfered between stable and active organic N pools (from
%SWAT ch 3)
ftrans=fixedinputdata(10);
% Nitrate-ammonium ratio characteristic for a particular soil (from
% Johnsson)
nq=fixedinputdata(11);
% Factor change rate for a 10C change in temperature of the soil (no units)
% (from Johnsson)
Q10=fixedinputdata(12);
% Optimal base temp (degC) (from Johnsson)
Tb=fixedinputdata(13);
% Half life of active organic N (days) (from Tammo)
thalfNact=fixedinputdata(14);
% Half life of fresh organic N (days) (from Tammo)
thalfNfrsh=fixedinputdata(15);
% Half life of stable organic N (days) (from Tammo)
thalfNstab=fixedinputdata(16);
% Potential rate of denitrification (kg/m^2*d) (from Johnsson)
kd=fixedinputdata(17);
% Saturation activity for moistfact function (from Johnsson)
es=fixedinputdata(18);
% Specific nitrification rate (1/d) (from Johnsson)
kn=fixedinputdata(19);
% Stable matter specific mineralization constant rate (1/d) (from Johnsson)
kh=fixedinputdata(20);
% Half saturation constant for denitrification (ppm or mg/kg) (from
% Johnsson)
cs=fixedinputdata(21);
% c/n ratio threshold for mobilization/immobilization (from Johnsson)
cnthrsh=fixedinputdata(22);
% Fresh matter decomposition rate (1/d) (from Johnsson)
kf=fixedinputdata(23);
% Synthsis efficiency constant for fresh carbon (from Johnsson)
fe=fixedinputdata(24);
% Carbon humification fraction (from Johnsson)
fh=fixedinputdata(25);
% Minimum soil T for processes to occure (nitrification, denitrification,
% decomposition,minearlization, immobilization, ntransfer), see Stotte et
% al. 1986
minT=fixedinputdata(26);
% Denitrification threshold water content (set this equal to thetaFC)
thetathresh=fixedinputdata(27);
% Threshold thetas for moistfact function (from Johnsson)
deltheta1=fixedinputdata(28);
deltheta2=fixedinputdata(29);
thetaLO=thetaWP+deltheta1;
thetaHO=thetaS-deltheta2;
% Time list
t=1:1:(numsimdays);
ttrans=transpose(t);
% Time step (for decay, in days)
tstep=fixedinputdata(30);
% Crop residue (kg/m^2?)
cropresidue=zeros(numsimdays,numofe);
for i=1:1:croprow
    % Residue available in soil is sum of burried and dead root mass
    %(kg/m^2)
    cropresidue(cropdata(i,2),cropdata(i,1))=cropdata(i,13)+cropdata(i,15)+cropdata(i,17)+cropdata(i,18)+cropdata(i,19)+cropdata(i,20)+cropdata(i,22)+cropdata(i,24)+cropdata(i,26);
end;

%% Water Content

% Also considers soil water content losses due to crop and soil evaporation
% ( residue evaporation is left out)
theta=(soilmoist-et)./rootdepth;

%% Soil Temperature

% Deviation from average air temperature (degC)
% Note: Since WEPP doesn't give hi/low I use the previous and following
% average temperatures to calculate deltT
delT=zeros(watrow,1);
for i=1:1:watrow
    if i<=(watrow-numofe)
        delT(i)=abs(avgT(i,1)-avgT(i+numofe));
    else
        % fill in the last three rows with the delT of the previous day
        delT(i)=delT(watrow-numofe);
    end;
end;
% Calculate the temperature of the soil temperature below the surface (C)
% Note:  Here we assume that the temperature at the middle of the layer is
% the average for the entire layer 
soilTlst=zeros(watrow,1);
for i=1:1:watrow
    soilTlst(i)=soiltemp(avgT(i),delT(i),rootdepth(i)/2,rootdepth(i),dayINyearlonglst(i),watdata(i,3));
end;

%% Leaf Area Index (LAI)

% Normalize LAI for the growing year (ranges from zero to 1, therefore this
% becomes a %).

lai=zeros(numsimdays,numofe);
for i=1:1:croprow
    lai(watdata(i,2),watdata(i,1))=cropdata(i,6);
end;

% Verify the maximum (yearly)
maxlaiverif=zeros(numyrs,numofe);
srt=1;
stp=dayINyearlst(1);
for k=1:1:numyrs
    if k<numyrs
        for ofe=1:1:numofe
            maxlaiverif(k,ofe)=max(lai(srt:stp,ofe));
        end;
        srt=stp+1;
        stp=stp+dayINyearlst(k+1);
    elseif k==numyrs
        for ofe=1:1:numofe
            maxlaiverif(k,ofe)=max(lai(numsimdays-dayINyearlst(k)+1:numsimdays,ofe));
        end;  
    end;
end;

% Make a maximum list (daily)
maxlailst=zeros(numsimdays,numofe);
srt=1;
stp=dayINyearlst(1);
for k=1:1:numyrs
    if k<numyrs
        for ofe=1:1:numofe
            maxlailst(srt:stp,ofe)=maxlaiverif(k,ofe);
        end;
        srt=stp+1;
        stp=stp+dayINyearlst(k+1);
    elseif k==numyrs
        for ofe=1:1:numofe
            maxlailst(numsimdays-dayINyearlst(k)+1:numsimdays,ofe)=maxlaiverif(k,ofe);
        end;
    end;
end;

% Make a normalized list with lai from 0-1
normallai=lai./maxlailst;

%% Planting, N Application, Harvesting, and Plowing Days

% Application location and amount in kg/m^2
applnofe=scheddata(:,4:7)./10000;
% Application type (1=manure, 2=fertilizer)
applntype=scheddata(:,14);
% Application, planting, harvest, and plow dates
applndate=scheddata(:,3);
plantdate=scheddata(:,8);
harvdate=scheddata(:,9);
plowdate=scheddata(:,10);
% Convert date to a cumulative date for the simulation
[sr,sc]=size(scheddata);
applndatecum=zeros(sr,1);
plantdatecum=zeros(sr,1);
harvdatecum=zeros(sr,1);
plowdatecum=zeros(sr,1);
for s=1:1:sr
    if applndate(s)>0
        if scheddata(s,1)==1 % first year
            applndatecum(s)=applndate(s);
        else % second year and on
            applndatecum(s)=applndate(s)+sum(dayINyearlst(1:scheddata(s,1)-1));
        end;
    else % just in case
        applndatecum(s)=0;
    end;
    % Planting
    if plantdate(s)>0
        if scheddata(s,1)==1 % first year
            plantdatecum(s)=plantdate(s);      
        else % second year and on
            plantdatecum(s)=plantdate(s)+sum(dayINyearlst(1:scheddata(s,1)-1));
        end;
    else % just in case
        plantdatecum(s)=0;
    end;
    % Harvest
    if harvdate(s)>0
        if scheddata(s,1)==1 % first year
            harvdatecum(s)=harvdate(s);            
        else % second year and on
            harvdatecum(s)=harvdate(s)+sum(dayINyearlst(1:scheddata(s,1)-1));
        end;
    else % just in case
        harvdatecum(s)=0;
    end;    
    % Plowing
    if plowdate(s)>0
        if scheddata(s,1)==1 % first year
            plowdatecum(s)=plowdate(s);            
        else % second year and on
            plowdatecum(s)=plowdate(s)+sum(dayINyearlst(1:scheddata(s,1)-1));
        end;
    else % just in case
        plowdatecum(s)=0;
    end;    
end;
plowdepth=scheddata(:,11);

%% Initialize Inorganic N Matrices

% Ammonium (kg), None until application
nh4=zeros(numsimdays,numofe);
% Nitrate (kg)
no3=zeros(numsimdays,numofe);

%% Initialize Plant N Matrix

% Plant N for the whole profile (kg)
% No plants yet so no initial plant N
plantN=zeros(numsimdays,numofe);

%% Initialize Organic N Matrices (from SWAT ch 3)

% Soil N concentration for the whole profile (ppm or mg/kg) 
soilNconc=10^4.*(oc./14);
% Soil N by mass (kg)
soilNmass=zeros(numsimdays,numofe);
for i=1:1:watrow
    soilNmass(watdata(i,2),watdata(i,1))=soilNconc(croptype(i),watdata(i,1))*ps(croptype(i),watdata(i,1))*rootdepth(i)*ofeArea(watdata(i,1));
end;
% Stable organic N for the whole profile (kg) 
orgNstab=zeros(numsimdays,numofe);
% Active organic N for the whole profile (kg)
orgNact=zeros(numsimdays,numofe);
% Fresh organic N for the whole profile (kg)
orgNfrsh=zeros(numsimdays,numofe);
% Fresh N is 0.15% of plant residue

%% Initialize Carbon Matrices

% Active carbon pool (kg)
cact=zeros(numsimdays,numofe);
% Fresh carbon (kg) 
cfrsh=zeros(numsimdays,numofe);
% Stable carbon (kg) 
cstab=zeros(numsimdays,numofe);

%% Initialize Inputs from the Atmosphere

% Count number of days with rainfall
rainfallCount=0;
rainfalllst=zeros(numsimdays,numofe);
for i=1:1:watrow
    if precip(i)>0
       rainfallCount=rainfallCount+1;
       rainfalllst(watdata(i,2),watdata(i,1))=1;
    end;
end;
% Wet and dry input of NH4 and NO3 from atm NASA gives nh4 and no3 wet and
% dry concentrations in kg/ha/d so we have to convert these to kg/m^2 
nh4constWET=1.38/10000;    
no3constWET=1.64/10000;
nh4constDRY=0.23/10000;
no3constDRY=0.18/10000;

% nh4 and no3 in rain (kg/ofe area)
nh4rain=zeros(numsimdays,numofe);
no3rain=zeros(numsimdays,numofe);
for i=1:1:watrow
    if rainfalllst(watdata(i,2),watdata(i,1))==1
        nh4rain(watdata(i,2),watdata(i,1))=nh4constWET*ofeArea(watdata(i,1))+nh4constDRY*ofeArea(watdata(i,1));
        no3rain(watdata(i,2),watdata(i,1))=no3constWET*ofeArea(watdata(i,1))+no3constDRY*ofeArea(watdata(i,1));
    else
        nh4rain(watdata(i,2),watdata(i,1))=nh4constDRY*ofeArea(watdata(i,1));
        no3rain(watdata(i,2),watdata(i,1))=no3constDRY*ofeArea(watdata(i,1));
    end;
end;

% Note: In the future atmospheric depostion should be modified to import
% spatially unique concentrations of NO3 and NH4. Possible resrouces to
% improve this aspect of the model include: The National Atmosphereic
% Deposition Program (http://nadp.sws.uiuc.edu/data/).

%% Initialize Lost N Matrices

% Nitrogen lost from overland flow (kg)
no3lostovlf=zeros(numsimdays,numofe);
% Nitrogen lost due to lateral flow (kg)
no3lostlatf=zeros(numsimdays,numofe);
% Nitrogen lost due to percolation (kg)
no3lostperc=zeros(numsimdays,numofe);
% Nitrogen lost due to denitrification (kg)
no3lostdenit=zeros(numsimdays,numofe);
% Total organic active N lost (kg)
orgnactlostsed=zeros(numsimdays,numofe);
% Total organic fresh N lost with sediment (kg)
orgnstablostsed=zeros(numsimdays,numofe);
% Total organic stable N lost with sediment (kg) 
orgnfrshlostsed=zeros(numsimdays,numofe);
% Total inorganic N lost (kg)
totalInorgNlost=zeros(numsimdays,numofe);
% Total organic N lost (kg)
totalOrgNlost=zeros(numsimdays,numofe);
% Sediment fraction (kg/kg)
sedfraclst=zeros(numsimdays,numofe);
% Mixing depth (m)
hmix=zeros(numsimdays,numofe);

% % Nitrogen lost from overland flow (kg/m^2)
no3lostovlfkgm2=zeros(numsimdays,numofe);
% Nitrogen lost due to lateral flow (kg/m^2)
no3lostlatfkgm2=zeros(numsimdays,numofe);
% Nitrogen lost due to percolation (kg/m^2)
no3lostperckgm2=zeros(numsimdays,numofe);
% Nitrogen lost due to denitrification (kg/m^2)
no3lostdenitkgm2=zeros(numsimdays,numofe);
% Total organic active N lost (kg/m^2)
orgnactlostsedkgm2=zeros(numsimdays,numofe);
% Total organic fresh N lost with sediment (kg/m^2)
orgnfrshlostsedkgm2=zeros(numsimdays,numofe);
% Total organic stable N lost with sediment (kg/m^2) 
orgnstablostsedkgm2=zeros(numsimdays,numofe);
% Total inorganic N lost (kg/m^2)
totalInorgNlostkgm2=zeros(numsimdays,numofe);
% Total organic N lost (kg/m^2)
totalOrgNlostkgm2=zeros(numsimdays,numofe);

%% Initialize pools per area (kg/m^2)

% Ammonium pool (kg/m^2)
nh4kgm2=zeros(numsimdays,numofe);
% Nitrate pool (kg/m^2)
no3kgm2=zeros(numsimdays,numofe);
% Plant N pool (kg/m^2)
plantNkgm2=zeros(numsimdays,numofe);
% Organic active N pool (kg/m^2)
orgNactkgm2=zeros(numsimdays,numofe);
% Organic fresh N pool (kg/m^2)
orgNfrshkgm2=zeros(numsimdays,numofe);
% Organic stable N pool (kg/m^2)
orgNstabkgm2=zeros(numsimdays,numofe);
% Active carbon pool (kg/m^2)
cactkgm2=zeros(numsimdays,numofe);
% Fresh carbon pool (kg/m^2)
cfrshkgm2=zeros(numsimdays,numofe);
% Stable carbon pool (kg/m^2)
cstabkgm2=zeros(numsimdays,numofe);

%% Daily Simulation

k=1;
for id=numofe+1:1:watrow % start on the second day
    i=daylst(id);
    ofe=ofelst(id);
    numday=noncumdaylst(id);
    % Upslope Pesticide Contributions (no3 in runnoff and lateral flow and no)
    if ofe>1
    	no3lostovldfUP=no3lostovlf(i-1,ofe-1);
        no3lostlaftUP=no3lostlatf(i-1,ofe-1);
        orgNactlostovldUP=orgnactlostsed(i-1,ofe-1);
        orgNfrshlostovldUP=orgnfrshlostsed(i-1,ofe-1);
        orgNstablostovldUP=orgnstablostsed(i-1,ofe-1);        
    else
        no3lostovldfUP=0;
        no3lostlaftUP=0;
        orgNactlostovldUP=0;
        orgNfrshlostovldUP=0;
        orgNstablostovldUP=0;
    end;
    % Calculate fraction of runoff make up of sediment (kg/kg)
    if ovldf(id)>0
        ovldfvol=ovldf(id)*ofeArea(ofe); % runoff volume
        ovldfmass=ovldfvol*pw;
        sedfrac=sed(id)/ovldfmass;
    else
        sedfrac=0;
    end;
    % Calculate pesticide applied to ofe (kg)
    bermwidth=userinputdata(40,ofe); % m
    width=userinputdata(39,ofe); % m
    applnarea=(width-2*bermwidth)*(ofeLength(ofe)-2*bermwidth);
    % Identify application day for the year
    d=find(scheddata(:,1)==k); % identify position
    allappdays=applndatecum(d(:));
    if intersect(allappdays,i)>0
        % Application day (cumulative)
        applnday=intersect(allappdays,i);
        % Application row
        applnrow=find(applndatecum(:)==applnday);
        % Application amount (convert to kg)
        applnamt=unique(applnofe(applnrow,ofe))*applnarea;
        % Application type (1=manure, 2=fertilizer -> can only handle one
        % type of application on any one day
        ferttype=unique(applntype(applnrow));
        if ferttype==1
            manureN=applnamt;
            fertN=0;
        elseif ferttype==2
            manureN=0;
            fertN=applnamt; 
        else
            manureN=0;
            fertN=0;
        end;
    else
        % Application day (cumulative)
        applnday=0;
        % Application amount and type (kg)
        manureN=0;
        fertN=0;
    end;  
    % Define depth of mixing layer
    allplowdays=plowdatecum(d(:));
    if intersect(allplowdays,i)>0
        % Plow day
        plowday=intersect(allplowdays,i);
        % Plow row
        plowrow=find(plowdatecum(:)==plowday);
        % Mixing layer depth (m)
        mixdepth=unique(plowdepth(plowrow));
    else
        % Non plow day 
        plowday=0;
        mixdepth=userinputdata(41,ofe);
    end;
    % Harvest days
    allharvdays=harvdatecum(d(:));
    if intersect(allharvdays,i)>0
        % Harvest day
        harvestday=intersect(allharvdays,i);
    else
        % Non harvest day 
        harvestday=0;
    end;
        
    % Non-uniform application with transport between OFEs
    out=dailyofeNsiM1layTrans(id,i,k,numday,applnarea,cropresidue(i,ofe),rootdepth(id),no3surf(ofe),soilNmass(i,ofe),manureN,fertN,applnday,normallai(id),harvestday,plowday,thalfNact,thalfNfrsh,thalfNstab,ps(croptype(id),ofe),oc(croptype(id),ofe),thetaS(croptype(id),ofe),thetaWP(croptype(id),ofe),thetaHO(croptype(id),ofe),thetaLO(croptype(id),ofe),thetathresh,theta(id),kd,fact,fabove,fleft,fharv,fmax,nq,tstep,Q10,Tb,es,kn,cs,kh,ftrans,cnthrsh,kf,fe,fh,minT,no3rain(i,ofe),nh4rain(i,ofe),plantN(i-1,ofe),nh4(i-1,ofe),no3(i-1,ofe),orgNact(i-1,ofe),orgNfrsh(i-1,ofe),orgNstab(i-1,ofe),no3lostovldfUP,no3lostlaftUP,orgNactlostovldUP,orgNfrshlostovldUP,orgNstablostovldUP,cact(i-1,ofe),cfrsh(i-1,ofe),cstab(i-1,ofe),avgT(id),soilTlst(id),ovldf(id),latf(id),perc(id),sedfrac,ofe);
    % Mixing depth (m)
    hmix(i,ofe)=mixdepth;
    % Sediment fraction
    sedfraclst(i,ofe)=sedfrac;
    
    % Losses (kg)
    no3lostovlf(out(3),ofe)=out(5); 
    no3lostlatf(out(3),ofe)=out(6); 
    no3lostperc(out(3),ofe)=out(7);
    no3lostdenit(out(3),ofe)=out(8);
    orgnactlostsed(out(3),ofe)=out(9); 
    orgnfrshlostsed(out(3),ofe)=out(10);
    orgnstablostsed(out(3),ofe)=out(11);
    totalInorgNlost(out(3),ofe)=out(5)+out(6)+out(7)+out(8);
    totalOrgNlost(out(3),ofe)=out(9)+out(10)+out(11);
    % Pools (kg)
    nh4(out(3),ofe)=out(12); 
    no3(out(3),ofe)=out(13); 
    plantN(out(3),ofe)=out(14);
    orgNact(out(3),ofe)=out(15); 
    orgNfrsh(out(3),ofe)=out(16); 
    orgNstab(out(3),ofe)=out(17);      
    cact(out(3),ofe)=out(18); 
    cfrsh(out(3),ofe)=out(19); 
    cstab(out(3),ofe)=out(20);
    
    % Losses per area (kg/m^2)
    no3lostovlfkgm2(out(3),ofe)=out(5)/applnarea; 
    no3lostlatfkgm2(out(3),ofe)=out(6)/applnarea; 
    no3lostperckgm2(out(3),ofe)=out(7)/applnarea;
    no3lostdenitkgm2(out(3),ofe)=out(8)/applnarea;
    orgnactlostsedkgm2(out(3),ofe)=out(9)/applnarea; 
    orgnfrshlostsedkgm2(out(3),ofe)=out(10)/applnarea;
    orgnstablostsedkgm2(out(3),ofe)=out(11)/applnarea;
    totalInorgNlostkgm2(out(3),ofe)=(out(5)+out(6)+out(7)+out(8))/applnarea;
    totalOrgNlostkgm2(out(3),ofe)=(out(9)+out(10)+out(11))/applnarea;
    % Pools per area (kg/m^2)
    nh4kgm2(out(3),ofe)=out(12)/applnarea; 
    no3kgm2(out(3),ofe)=out(13)/applnarea; 
    plantNkgm2(out(3),ofe)=out(14)/applnarea;
    orgNactkgm2(out(3),ofe)=out(15)/applnarea; 
    orgNfrshkgm2(out(3),ofe)=out(16)/applnarea; 
    orgNstabkgm2(out(3),ofe)=out(17)/applnarea;      
    cactkgm2(out(3),ofe)=out(18)/applnarea; 
    cfrshkgm2(out(3),ofe)=out(19)/applnarea; 
    cstabkgm2(out(3),ofe)=out(20)/applnarea;  
    
    % Iterator
    if daylst(id)<=sum(dayINyearlst(1:k))
        k=k+0;
    else
        k=k+1;
    end;
end;
%% Daily

% Daily N lost (kg)
dailyNlostdata=[no3lostovlf,no3lostlatf,no3lostperc,no3lostdenit,orgnactlostsed,orgnfrshlostsed,orgnstablostsed,totalInorgNlost,totalOrgNlost];
% Daily N (and C) pools (kg)
dailyNpooldata=[nh4,no3,plantN,orgNact,orgNfrsh,orgNstab,cact,cfrsh,cstab];
%
% Daily N lost (kg/m^2)
dailyNlostdatakgm2=[no3lostovlfkgm2,no3lostlatfkgm2,no3lostperckgm2,no3lostdenitkgm2,orgnactlostsedkgm2,orgnfrshlostsedkgm2,orgnstablostsedkgm2,totalInorgNlostkgm2,totalOrgNlostkgm2];
% Daily N (and C) pools (kg/m^2)
dailyNpooldatakgm2=[nh4kgm2,no3kgm2,plantNkgm2,orgNactkgm2,orgNfrshkgm2,orgNstabkgm2,cactkgm2,cfrshkgm2,cstabkgm2];

%% Monthly

% Month list for the entire simulation
mbiglst=zeros(mpy*numyrs,1);
srt=1;
for k=1:1:numyrs
    if dayINyearlst(k)==365
        mbiglst(srt:srt+mpy-1)=mlst;
    else
        mbiglst(srt:srt+mpy-1)=mlstleap;
    end;
    srt=srt+mpy;
end;

% Cumulative monthly list for the entire simulation
mbiglstcum=zeros(mpy*numyrs,1);
for j=1:1:mpy*numyrs
    if j==1
        mbiglstcum(j)=mbiglst(1);
    else
        mbiglstcum(j)=sum(mbiglst(1:j));
    end;
end;

% Use mbiglstcum to add up all daily processes
monthlylostNeros=zeros(mpy*numyrs,numofe);
monthlylostNovldfnosed=zeros(mpy*numyrs,numofe);
monthlylostNlatf=zeros(mpy*numyrs,numofe);
monthlylostNperc=zeros(mpy*numyrs,numofe);
monthlylostNatm=zeros(mpy*numyrs,numofe);
srt=1;
for j=1:1:mpy*numyrs
    for i=1:1:numofe
        monthlylostNeros(j,i)=sum(totalOrgNlostkgm2(srt:mbiglstcum(j),i));
        monthlylostNovldfnosed(j,i)=sum(totalInorgNlostkgm2(srt:mbiglstcum(j),i));
        monthlylostNlatf(j,i)=sum(no3lostlatfkgm2(srt:mbiglstcum(j),i));
        monthlylostNperc(j,i)=sum(no3lostperckgm2(srt:mbiglstcum(j),i));
        monthlylostNatm(j,i)=sum(no3lostdenitkgm2(srt:mbiglstcum(j),i));
    end;
    srt=mbiglstcum(j)+1;
end;

% Save montly data (kg/m^2)
monthlyNdata=[monthlylostNeros,monthlylostNovldfnosed,monthlylostNlatf,monthlylostNperc,monthlylostNatm];

%% Monthly Total at Hillslope Base (i.e. last OFE)

monthlyNeroshill=zeros(mpy*numyrs,1);
monthlyNovldfnosedhill=zeros(mpy*numyrs,1);
monthlyNlatfhill=zeros(mpy*numyrs,1);
monthlyNperchill=zeros(mpy*numyrs,1);
monthlyNatmhill=zeros(mpy*numyrs,1);

% make a list of 1-12's to organize montly data
mpylst=1:1:mpy;
mpylstlong=zeros(mpy*numyrs,1);
yrslstlong=zeros(mpy*numyrs,1);
srt=1;
srtyr=1;
for k=1:1:numyrs
    mpylstlong(srt:srt+mpy-1)=mpylst;
    yrslstlong(srt:srt+mpy-1)=srtyr;
    srt=srt+mpy;
    srtyr=srtyr+1;
end

for k=1:1:mpy*numyrs
    monthlyNeroshill(k)=monthlylostNeros(k,numofe);
    monthlyNovldfnosedhill(k)=monthlylostNovldfnosed(k,numofe);
    monthlyNlatfhill(k)=monthlylostNlatf(k,numofe);
    monthlyNperchill(k)=sum(monthlylostNperc(k,1:numofe).*(ofeLength/sum(ofeLength)));
    monthlyNatmhill(k)=sum(monthlylostNatm(k,1:numofe).*(ofeLength/sum(ofeLength)));
end;

% Monthly total average data at bottom of the hillslope (kg/m^2)
monthlyNhilldata=[mpylstlong,yrslstlong,monthlyNeroshill,monthlyNovldfnosedhill,monthlyNlatfhill,monthlyNperchill,monthlyNatmhill];

%% Averaging Monthly Totals at Hillslope Base (kg/ha)

% Organize so columns are months and rows are years
monthlyNerosbymonthhill=zeros(numyrs,mpy);
monthlyNovldfnosedbymonthhill=zeros(numyrs,mpy);
monthlyNlatfbymonthhill=zeros(numyrs,mpy);
monthlyNpercbymonthhill=zeros(numyrs,mpy);
monthlyNatmbymonthhill=zeros(numyrs,mpy);

for k=1:1:mpy*numyrs
    monthlyNerosbymonthhill(yrslstlong(k),mpylstlong(k))=monthlyNeroshill(k);
    monthlyNovldfnosedbymonthhill(yrslstlong(k),mpylstlong(k))=monthlyNovldfnosedhill(k);
    monthlyNlatfbymonthhill(yrslstlong(k),mpylstlong(k))=monthlyNlatfhill(k);
    monthlyNpercbymonthhill(yrslstlong(k),mpylstlong(k))=monthlyNperchill(k);
    monthlyNatmbymonthhill(yrslstlong(k),mpylstlong(k))=monthlyNatmhill(k);
end;

% Take mean of each month
monthlyavgNerosbymonthhill=zeros(mpy,1);
monthlyavgNovldfnosedbymonthhill=zeros(mpy,1);
monthlyavgNlatfbymonthhill=zeros(mpy,1);
monthlyavgNpercbymonthhill=zeros(mpy,1);
monthlyavgNatmbymonthhill=zeros(mpy,1);

% convert to kg/ha
for k=1:1:mpy
    monthlyavgNerosbymonthhill(k)=mean(monthlyNerosbymonthhill(:,k))*10000*(ofeLength(numofe)/sum(ofeLength)); % must multiply by length last ofe/sum of all ofe lengths to get in right units for end of the hillslope b/c wepp .wat inputs are cumulative)
    monthlyavgNovldfnosedbymonthhill(k)=mean(monthlyNovldfnosedbymonthhill(:,k))*10000*(ofeLength(numofe)/sum(ofeLength));
    monthlyavgNlatfbymonthhill(k)=mean(monthlyNlatfbymonthhill(:,k))*10000*(ofeLength(numofe)/sum(ofeLength));
    monthlyavgNpercbymonthhill(k)=mean(monthlyNpercbymonthhill(:,k))*10000; % already took weighted average above
    monthlyavgNatmbymonthhill(k)=mean(monthlyNatmbymonthhill(:,k))*10000; % already took weighted average above
end;

% Monthly averages lost at base of hillslope (kg/ha)
monthlyNhillavgdata=[transpose(mpylst),monthlyavgNerosbymonthhill,monthlyavgNovldfnosedbymonthhill,monthlyavgNlatfbymonthhill,monthlyavgNpercbymonthhill,monthlyavgNatmbymonthhill];

%% Yearly

yearlylostNeros=zeros(numyrs,numofe);
yearlylostNovldfnosed=zeros(numyrs,numofe);
yearlylostNlatf=zeros(numyrs,numofe);
yearlylostNperc=zeros(numyrs,numofe);
yearlylostNatm=zeros(numyrs,numofe);
srt=1;
for k=1:1:numyrs
    for i=1:1:numofe
        yearlylostNeros(k,i)=sum(totalOrgNlostkgm2(srt:sum(dayINyearlst(1:k)),i));
        yearlylostNovldfnosed(k,i)=sum(totalInorgNlostkgm2(srt:sum(dayINyearlst(1:k)),i));
        yearlylostNlatf(k,i)=sum(no3lostlatfkgm2(srt:sum(dayINyearlst(1:k)),i));
        yearlylostNperc(k,i)=sum(no3lostperckgm2(srt:sum(dayINyearlst(1:k)),i));
        yearlylostNatm(k,i)=sum(no3lostdenitkgm2(srt:sum(dayINyearlst(1:k)),i));
    end;
    srt=srt+dayINyearlst(k);
end;

% Save yearly data (kg/m^2)
yearlyNdata=[yearlylostNeros,yearlylostNovldfnosed,yearlylostNlatf,yearlylostNperc,yearlylostNatm];

%% Yearly Net Averages by OFE

yearlylostNerosavg=zeros(1,numofe);
yearlylostNovldfnosedavg=zeros(1,numofe);
yearlylostNlatfavg=zeros(1,numofe);
yearlylostNpercavg=zeros(1,numofe);
yearlylostNatmavg=zeros(1,numofe);

for ofe=1:1:numofe
    if ofe>1
        yearlylostNerosavg(1,ofe)=(sum(yearlylostNeros(:,ofe))-sum(yearlylostNeros(:,ofe-1)))/numyrs;
        yearlylostNovldfnosedavg(1,ofe)=(sum(yearlylostNovldfnosed(:,ofe))-sum(yearlylostNovldfnosed(:,ofe-1)))/numyrs;
        yearlylostNlatfavg(1,ofe)=(sum(yearlylostNlatf(:,ofe))-sum(yearlylostNlatf(:,ofe-1)))/numyrs;
        yearlylostNpercavg(1,ofe)=sum(yearlylostNperc(:,ofe))/numyrs;
        yearlylostNatmavg(1,ofe)=sum(yearlylostNatm(:,ofe))/numyrs;
    else
        yearlylostNerosavg(1,ofe)=sum(yearlylostNeros(:,ofe))/numyrs;
        yearlylostNovldfnosedavg(1,ofe)=sum(yearlylostNovldfnosed(:,ofe))/numyrs;
        yearlylostNlatfavg(1,ofe)=sum(yearlylostNlatf(:,ofe))/numyrs;
        yearlylostNpercavg(1,ofe)=sum(yearlylostNperc(:,ofe))/numyrs;
        yearlylostNatmavg(1,ofe)=sum(yearlylostNatm(:,ofe))/numyrs;
    end;
end;

% Yearly average (kg/m^2)
yearlyNavgdata=[yearlylostNerosavg;yearlylostNovldfnosedavg;yearlylostNlatfavg;yearlylostNpercavg;yearlylostNatmavg];

%% Yearly Total at Hillslope Base (i.e. last OFE)

yearlyNeroshill=zeros(numyrs,1);
yearlyNovldfnosedhill=zeros(numyrs,1);
yearlyNlatfhill=zeros(numyrs,1);
yearlyNperchill=zeros(numyrs,1);
yearlyNatmhill=zeros(numyrs,1);

for k=1:1:numyrs
    yearlyNeroshill(k)=yearlylostNeros(k,numofe).*(ofeLength(numofe)/sum(ofeLength)); % must multiply by length last ofe/sum of all ofe lengths to get in right units for end of the hillslope b/c wepp .wat inputs are cumulative)
    yearlyNovldfnosedhill(k)=yearlylostNovldfnosed(k,numofe).*(ofeLength(numofe)/sum(ofeLength));
    yearlyNlatfhill(k)=yearlylostNlatf(k,numofe).*(ofeLength(numofe)/sum(ofeLength));
    yearlyNperchill(k)=sum(yearlylostNperc(k,1:numofe).*(ofeLength/sum(ofeLength))); % calc average of perc from all ofes
    yearlyNatmhill(k)=sum(yearlylostNatm(k,1:numofe).*(ofeLength/sum(ofeLength))); % calc average of perc from all ofes
end;

% Yearly data at bottom of the hillslope (kg/m^2)
yearlyNhilldata=[yearlyNeroshill,yearlyNovldfnosedhill,yearlyNlatfhill,yearlyNperchill,yearlyNatmhill];

%% Yearly Total Averages at Hillslope Base (i.e. last OFE)

% Yearly averages lost at base of hillslope (kg/ha)
yearlyNhillavgdata=zeros(4,1);
for i=1:1:4
    yearlyNhillavgdata(i)=mean(yearlyNhilldata(:,i)).*10000;
end;

