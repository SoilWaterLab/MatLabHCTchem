% sub_program_p.m

% Author: Sheila Saia
% Email: sms493@cornell.edu
% Last Updated: Mar 1, 2013

% This file is needed to run 'program_p.m'. It initializes matrices and
% defines parameters based on wat, elem, crop, soil, and parameter files
% loaded in from 'program_p.m'.

% References: Easton et al 2007a and 2007b, Easton et al 2009

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

%% Water Balance Output File (wat.txt)

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

%% WEPP Element Output File (elem.txt)

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

%% Plant and Residue Output File (crop.txt)

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

%% Scheduling File (sched.txt)

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
for o=1:1:numofe
    for c=1:1:max(croptype);
        % Soil bulk density (g/cm^3)
        ps(c,o)=userinputdata(5+c-1,o);
        % Convert ps to kg/m^3
        ps(c,o)=ps(c,o)*1000;
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
% Density of water (g/cm^3) at 20C
pw=0.9980;
% Convert pw to kg/m^3
pw=pw*1000;
% DP immobilization rate (days)
tau=fixedinputdata(2);
% Factor change rate for a 10 degC change in temperature of the soil (no
% units) 
QS=fixedinputdata(4);
% Reference DP plant/soil export coefficient (kg/m)
mewTS=fixedinputdata(5);
% Reference tempemirature for soil (C)                   
TR=fixedinputdata(7);
% Reaction constant for bound P to DP (1/kg*d)
kdissolv=fixedinputdata(3);
% Average soil test P (mg/kg)
stpconc=userinputdata(34,:);
% Time step (delta t) of one day for the decay function
tstep=fixedinputdata(6);

%% P Application

% Application location and amount in kg/m^2
applnofe=scheddata(:,4:7)./10000;
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

%% Initialize Matrices

% Amount of water soluable P left in mixing layer (soil) (kg)
avalsolPfert=zeros(numsimdays,numofe);
% Amount of DP in overland flow due to fertilzer (kg)
lostPfert=zeros(numsimdays,numofe);      
% Amount of P lost in overland flow due to abiotic (i.e. sorption, soil
% moisture, etc.) and biotic (i.e. plant uptake, OM mineralization, etc.)
lostPplntsoil=zeros(numsimdays,numofe);
% Total P lost in overland flow (without sediment) (kg)
totalPlostOvlfnosed=zeros(numsimdays,numofe);
% Amount of P lost due to sediment transport (erosion) in ovld flow (kg)
lostPeros=zeros(numsimdays,numofe);
% Amount of P lost in lateral flow (kg)
lostPlatf=zeros(numsimdays,numofe);
% Amount of P lost in Percolation (kg)
lostPperc=zeros(numsimdays,numofe);
% Mixing depth (m)
hmix=zeros(numsimdays,numofe);

% Amount of water soluable P left in mixing layer (soil) (kg/m^2)
avalsolPfertkgm2=zeros(numsimdays,numofe);
% Amount of DP in overland flow due to fertilzer (kg/m^2)
lostPfertkgm2=zeros(numsimdays,numofe);      
% Amount of P lost in overland flow due to abiotic (i.e. sorption, soil
% moisture, etc.) and biotic (i.e. plant uptake, OM mineralization, etc.)
lostPplntsoilkgm2=zeros(numsimdays,numofe);
% Total P lost in overland flow (without sediment) (kg/m^2)
totalPlostOvlfnosedkgm2=zeros(numsimdays,numofe);
% Amount of P lost due to sediment transport (erosion) in ovld flow (kg)
lostPeroskgm2=zeros(numsimdays,numofe);
% Amount of P lost in lateral flow (kg/m^2)
lostPlatfkgm2=zeros(numsimdays,numofe);
% Amount of P lost in Percolation (kg/m^2)
lostPperckgm2=zeros(numsimdays,numofe);

%% Daily Simulation

k=1;
for id=numofe+1:1:watrow %start at second day
    i=daylst(id);
    ofe=ofelst(id);
    % Upslope P Contributions (dissolved P in runnoff and lateral flow)
    if ofe>1
        lostPfertUP=lostPfert(i,ofe-1);
        lostPplntsoilUP=lostPplntsoil(i,ofe-1);
        lostPlatUP=lostPlatf(i,ofe-1);
    else
        lostPfertUP=0;
        lostPplntsoilUP=0;
        lostPlatUP=0;
    end;
    % Calculate fraction of runoff make up of sediment (kg/kg)
    if ovldf(id)>0
        ovldfvol=ovldf(id)*ofeArea(ofe); % runoff volume
        ovldfmass=ovldfvol*pw;
        sedfrac=sed(id)/ovldfmass;
    else
        sedfrac=0;
    end;
    % Calculate p applied to ofe (kg/actual applied ofe area in m^2)
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
    else
        % Application day (cumulative)
        applnday=0;
        % Application amount (kg)
        applnamt=0;
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
    
    % Run P function
    out=dailyofePsimTrans(id,i,k,tstep,tau,hmix(i-1,ofe),mixdepth,ofeArea(ofe),kdissolv,stpconc(ofe),mewTS,QS,TR,plowday,applnday,applnamt,avalsolPfert(i-1,ofe),lostPfertUP,lostPplntsoilUP,lostPlatUP,avgT(id),ovldf(id),latf(id),perc(id),sed(id),sedfrac,ofe);
    
    % Mixing depth (m)
    hmix(i,ofe)=mixdepth;    
    
    % Losses (kg)
    avalsolPfert(out(3),ofe)=out(5);                                % Fertilizer P left in the profile
    lostPfert(out(3),ofe)=out(6);                                   % Fertilizer P (dissolved) lost to decay
    lostPplntsoil(out(3),ofe)=out(7);                               % P lost due to plant/soil complexes
    lostPeros(out(3),ofe)=out(8);                                   % Adsorbed P lost in overland flow 
    lostPlatf(out(3),ofe)=out(9);                                   % P (dissolved) lost in lateral flow
    lostPperc(out(3),ofe)=out(10);                                  % P (dissolved) lost in percolation to groundwater
    totalPlostOvlfnosed(out(3),ofe)=out(6)+out(7);                  % Total P lost in overland flow (dissolved)
    
    % Losses per area (kg/m^2)
    avalsolPfertkgm2(out(3),ofe)=out(5)/applnarea;                  % Fertilizer P left in the profile
    lostPfertkgm2(out(3),ofe)=out(6)/applnarea;                     % Fertilizer P (dissolved) lost to decay
    lostPplntsoilkgm2(out(3),ofe)=out(7)/applnarea;                 % P lost due to plant/soil complexes
    lostPeroskgm2(out(3),ofe)=out(8)/applnarea;                     % Adsorbed P lost in overland flow 
    lostPlatfkgm2(out(3),ofe)=out(9)/applnarea;                     % P (dissolved) lost in lateral flow
    lostPperckgm2(out(3),ofe)=out(10)/applnarea;                    % P (dissolved) lost in percolation to groundwater
    totalPlostOvlfnosedkgm2(out(3),ofe)=out(6)+out(7)/applnarea;	% Total P lost in overland flow (dissolved)
    
    % Iterator
    if daylst(id)<=sum(dayINyearlst(1:k))
        k=k+0;
    else
        k=k+1;
    end;
end;

%% Save Daily Data

% Daily p losses (kg)
dailyPdatakg=[avalsolPfert,lostPfert,lostPplntsoil,lostPeros,lostPlatf,lostPperc,totalPlostOvlfnosed];
% Daily p losses (kg/m^2)
dailyPdatakgm2=[avalsolPfertkgm2,lostPfertkgm2,lostPplntsoilkgm2,lostPeroskgm2,lostPlatfkgm2,lostPperckgm2,totalPlostOvlfnosedkgm2];

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
monthlylostPeros=zeros(mpy*numyrs,numofe);
monthlylostPovldfnosed=zeros(mpy*numyrs,numofe);
monthlylostPlatf=zeros(mpy*numyrs,numofe);
monthlylostPperc=zeros(mpy*numyrs,numofe);
srt=1;
for j=1:1:mpy*numyrs
    for i=1:1:numofe
        monthlylostPeros(j,i)=sum(lostPeroskgm2(srt:mbiglstcum(j),i));
        monthlylostPovldfnosed(j,i)=sum(totalPlostOvlfnosedkgm2(srt:mbiglstcum(j),i));
        monthlylostPlatf(j,i)=sum(lostPlatfkgm2(srt:mbiglstcum(j),i));
        monthlylostPperc(j,i)=sum(lostPperckgm2(srt:mbiglstcum(j),i));
    end;
    srt=mbiglstcum(j)+1;
end;

% Save montly data (kg/m^2)
monthlyPdata=[monthlylostPeros,monthlylostPovldfnosed,monthlylostPlatf,monthlylostPperc];

%% Monthly Total at Hillslope Base (i.e. last OFE)

monthlyPeroshill=zeros(mpy*numyrs,1);
monthlyPovldfnosedhill=zeros(mpy*numyrs,1);
monthlyPlatfhill=zeros(mpy*numyrs,1);
monthlyPperchill=zeros(mpy*numyrs,1);

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
    monthlyPeroshill(k)=monthlylostPeros(k,numofe);
    monthlyPovldfnosedhill(k)=monthlylostPovldfnosed(k,numofe);
    monthlyPlatfhill(k)=monthlylostPlatf(k,numofe);
    monthlyPperchill(k)=sum(monthlylostPperc(k,1:numofe).*(ofeLength/sum(ofeLength)));
end;

% Monthly total average data at bottom of the hillslope (kg/m^2)
monthlyPhilldata=[mpylstlong,yrslstlong,monthlyPeroshill,monthlyPovldfnosedhill,monthlyPlatfhill,monthlyPperchill];

%% Averaging Monthly Totals at Hillslope Base (kg/ha)

% Organize so columns are months and rows are years
monthlyPerosbymonthhill=zeros(numyrs,mpy);
monthlyPovldfnosedbymonthhill=zeros(numyrs,mpy);
monthlyPlatfbymonthhill=zeros(numyrs,mpy);
monthlyPpercbymonthhill=zeros(numyrs,mpy);

for k=1:1:mpy*numyrs
    monthlyPerosbymonthhill(yrslstlong(k),mpylstlong(k))=monthlyPeroshill(k);
    monthlyPovldfnosedbymonthhill(yrslstlong(k),mpylstlong(k))=monthlyPovldfnosedhill(k);
    monthlyPlatfbymonthhill(yrslstlong(k),mpylstlong(k))=monthlyPlatfhill(k);
    monthlyPpercbymonthhill(yrslstlong(k),mpylstlong(k))=monthlyPperchill(k);
end;

% Take mean of each month
monthlyavgPerosbymonthhill=zeros(mpy,1);
monthlyavgPovldfnosedbymonthhill=zeros(mpy,1);
monthlyavgPlatfbymonthhill=zeros(mpy,1);
monthlyavgPpercbymonthhill=zeros(mpy,1);

% convert to kg/ha
for k=1:1:mpy
    monthlyavgPerosbymonthhill(k)=mean(monthlyPerosbymonthhill(:,k))*10000*(ofeLength(numofe)/sum(ofeLength)); % must multiply by length last ofe/sum of all ofe lengths to get in right units for end of the hillslope b/c wepp .wat inputs are cumulative)
    monthlyavgPovldfnosedbymonthhill(k)=mean(monthlyPovldfnosedbymonthhill(:,k))*10000*(ofeLength(numofe)/sum(ofeLength));
    monthlyavgPlatfbymonthhill(k)=mean(monthlyPlatfbymonthhill(:,k))*10000*(ofeLength(numofe)/sum(ofeLength));
    monthlyavgPpercbymonthhill(k)=mean(monthlyPpercbymonthhill(:,k))*10000;
end;

% Monthly averages lost at base of hillslope (kg/ha)
monthlyPhillavgdata=[transpose(mpylst),monthlyavgPerosbymonthhill,monthlyavgPovldfnosedbymonthhill,monthlyavgPlatfbymonthhill,monthlyavgPpercbymonthhill];

%% Yearly

yearlylostPeros=zeros(numyrs,numofe);
yearlylostPovldfnosed=zeros(numyrs,numofe);
yearlylostPlatf=zeros(numyrs,numofe);
yearlylostPperc=zeros(numyrs,numofe);
srt=1;
for k=1:1:numyrs
    for i=1:1:numofe
        yearlylostPeros(k,i)=sum(lostPeroskgm2(srt:sum(dayINyearlst(1:k)),i));
        yearlylostPovldfnosed(k,i)=sum(totalPlostOvlfnosedkgm2(srt:sum(dayINyearlst(1:k)),i));
        yearlylostPlatf(k,i)=sum(lostPlatfkgm2(srt:sum(dayINyearlst(1:k)),i));
        yearlylostPperc(k,i)=sum(lostPperckgm2(srt:sum(dayINyearlst(1:k)),i));
    end;
    srt=srt+dayINyearlst(k);
end;

% Save yearly data (kg/m^2)
yearlyPdata=[yearlylostPeros,yearlylostPovldfnosed,yearlylostPlatf,yearlylostPperc];

%% Yearly Net Averages by OFE

yearlylostPerosavg=zeros(1,numofe);
yearlylostPovldfnosedavg=zeros(1,numofe);
yearlylostPlatfavg=zeros(1,numofe);
yearlylostPpercavg=zeros(1,numofe);

for ofe=1:1:numofe
    if ofe>1
        yearlylostPerosavg(1,ofe)=(sum(yearlylostPeros(:,ofe))-sum(yearlylostPeros(:,ofe-1)))/numyrs;
        yearlylostPovldfnosedavg(1,ofe)=(sum(yearlylostPovldfnosed(:,ofe))-sum(yearlylostPovldfnosed(:,ofe-1)))/numyrs;
        yearlylostPlatfavg(1,ofe)=(sum(yearlylostPlatf(:,ofe))-sum(yearlylostPlatf(:,ofe-1)))/numyrs;
        yearlylostPpercavg(1,ofe)=sum(yearlylostPperc(:,ofe))/numyrs;
    else
        yearlylostPerosavg(1,ofe)=sum(yearlylostPeros(:,ofe))/numyrs;
        yearlylostPovldfnosedavg(1,ofe)=sum(yearlylostPovldfnosed(:,ofe))/numyrs;
        yearlylostPlatfavg(1,ofe)=sum(yearlylostPlatf(:,ofe))/numyrs;
        yearlylostPpercavg(1,ofe)=sum(yearlylostPperc(:,ofe))/numyrs;   
    end;
end;

% Yearly average (kg/m^2)
yearlyPavgdata=[yearlylostPerosavg;yearlylostPovldfnosedavg;yearlylostPlatfavg;yearlylostPpercavg];

%% Yearly Total at Hillslope Base (i.e. last OFE)

yearlyPeroshill=zeros(numyrs,1);
yearlyPovldfnosedhill=zeros(numyrs,1);
yearlyPlatfhill=zeros(numyrs,1);
yearlyPperchill=zeros(numyrs,1);

for k=1:1:numyrs
    yearlyPeroshill(k)=yearlylostPeros(k,numofe).*(ofeLength(numofe)/sum(ofeLength)); % must multiply by length last ofe/sum of all ofe lengths to get in right units for end of the hillslope b/c wepp .wat inputs are cumulative)
    yearlyPovldfnosedhill(k)=yearlylostPovldfnosed(k,numofe).*(ofeLength(numofe)/sum(ofeLength));
    yearlyPlatfhill(k)=yearlylostPlatf(k,numofe).*(ofeLength(numofe)/sum(ofeLength));
    yearlyPperchill(k)=sum(yearlylostPperc(k,1:numofe).*(ofeLength/sum(ofeLength)));  % calc average of perc from all ofes
end;

% Yearly data at bottom of the hillslope (kg/m^2)
yearlyPhilldata=[yearlyPeroshill,yearlyPovldfnosedhill,yearlyPlatfhill,yearlyPperchill];

%% Yearly Total Averages at Hillslope Base (i.e. last OFE)

% Yearly averages lost at base of hillslope (kg/ha)
yearlyPhillavgdata=zeros(4,1);
for i=1:1:4
    yearlyPhillavgdata(i)=mean(yearlyPhilldata(:,i)).*10000;
end;

