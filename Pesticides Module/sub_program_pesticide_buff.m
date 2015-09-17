% sub_program_pesticide_buff.m

% Author: Sheila Saia
% Email: sms493@cornell.edu
% Last Updated: Mar 1, 2013

% This file is needed to run 'program_pesticide.m'. Basically, it
% initializes matrices and defines parameters based on wat, elem, crop,
% soil, and ofe files loaded in from 'program_pesticide.m'.

% References: Steenhuis and Walter 1980, Sinkevich et al 2005

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

%% Parameters

% OFE number
ofelst=watdata(:,1);
% OFE lengths (m)
ofeLength=userinputdata(38,1:numofe);
% Sum OFE lengths (m)
ofeLengthsum=sum(ofeLength);
% Buffer OFE (# assume last)
buffernum=fixedinputdata(35);

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

%% WEPP Element Output File

% This file only prints out days when there is a water related event
% (rainfall, snowfall, runoff, etc.).
% col1: OFE id
% col2: day (I convert to a cumulative day over the entire
% simulation period - see below)
% col3: month
% col4: year
% col5: precipitation (snow or rain) (mm)
% col6: runoff (mm)
% col7: Effective intensity (mm/h)
% col8: peak runoff (mm/h)
% col9: Effective duration (h)
% col10: enrichment ratio
% col11: Keff (effective hydrolic conductivity of the surface soil - mm/h)
% col12: Sm (total soil water content - mm)
% col13: leaf area index (LAI - no units)
% col14: canopy height (m)
% col15: canopy cover (%)
% col16: interill cover (%)
% col17: rill cover (%)
% col18: live biomass (kg/m^2)
% col19: dead biomass (kg/m^2)
% col20: Ki (interill erosion coefficient - )
% col21: Kr (rill erosion coefficient - ) 
% col22: Tcrit? (C)
% col23: Rill width (m)
% col24: sediment leaving (kg/m)
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

% col1: OFE
% col2: day of the year
% col3: year
% col4: canopy height (m)
% col5: canopy cover (%)
% col6: leaf area index (LAI - no units)
% col7: rill cover (%)
% col8: interill cover (%)
% col9: crop id #
% col10: live biomass
% col11: standing residue mass (kg/m^2)
% col12: crop id # for the last crop harvested
% col13: flat residue mass for the last crop harvested (kg/m^2)
% col14: crop id # for the previous crop harvested
% col15: flat residue mass for the previous crop harvested (kg/m^2)
% col16: crop id # for all previous crops harvested
% col17: flat residue mass for all previous crops harvested (kg/m^2)
% col18: buried residue mass for the last crop harvested (kg/m^2)
% col19: buried residue mass for the previous crop harvest (kg/m^2)
% col20: buried residue mass for all previous crops harvested (kg/m^2)
% col21: crop id # for the last crop harvested
% col22: dead root mass for the last crop harvested (kg/m^2)
% col23: crop id # for the previous crop harvested
% col24: dead root mass for the previous crop harvested (kg/m^2)
% col25: crop id # for all previous crops harvested
% col26: dead root mass all previous crops harvested (kg/m^2)
% col27: average temp (C)
% col28: sediment (kg/m)
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
a=[elemdata(:,2),elemdata(:,24)];         % Sediment (kg/m)
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
% colm7: applicaiton amount for OFE4 (buffer)
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
% Day (cumulative)
daylst=watdata(:,2);
% Day (of the month)
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
% Overland flow passing through the OFE (m)
ovldf=watdata(:,18)./1000;
% Lateral flow passing through the OFE (m)
latf=watdata(:,14)./1000;
% Percolation (m) (non-cumulative)
perc=watdata(:,11)./1000;
% Sediment leaving an OFE per width (kg/m)
sedkgm=watdata(:,22);
% Sdiment leaving an OFE (kg)
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
% Initialize parameters for each crop
ps=zeros(max(croptype),numofe);
om=zeros(max(croptype),numofe);
thetaS=zeros(max(croptype),numofe);
thetaFC=zeros(max(croptype),numofe);
koc=zeros(max(croptype),numofe);
thalf=zeros(max(croptype),numofe);
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
        % Percent organic matter in the mixing layer
        om(c,o)=userinputdata(21+c-1,numofe);
        % Pesticide (here, atrazine) organic carbon adsorption coefficient
        % (cm^3/g), see Excel spreadsheet for values
        koc(c,o)=userinputdata(26+c-1,o);
        % Convert to m^3/kg
        koc(c,o)=koc(c,o)/1000;
        % Half-life for atrazine (or other pesticide) (days)
        thalf(c,o)=userinputdata(30+c-1,o);
    end;
end;
% Max root depth (m), for each crop
% Second colm is buffer root depth
rootdepthshrt=scheddata(:,12:13); % convert to m
rootdepth=zeros(croprow,1);
for i=1:1:croprow
    if croptype(i)==max(croptype) % for buffer
        rflag1=find(scheddata(:,1)==cropdata(i,3));
        rflag2=find(scheddata(:,2)==max(croptype));
        rflagfin=intersect(rflag1,rflag2);
        r=rootdepthshrt(rflagfin,2);
        rsel=unique(r);
        rootdepth(i)=rsel;
    else % for non-buffer crops
        rflag1=find(scheddata(:,1)==cropdata(i,3));
        rflag2=find(scheddata(:,2)<max(croptype));
        rflagfin=intersect(rflag1,rflag2);
        r=rootdepthshrt(rflagfin,1);
        rsel=unique(r);
        rootdepth(i)=rsel;
    end;        
end;
% Incorporation (yes=1, no=0);
incorp=userinputdata(25,:);
% Percent organic carbon
oc=(om./100).*0.58;
% Adsorption partition coefficient (see Sinkevich 2005) (m^3/kg)
apc=koc.*oc;
% Density of water (g/cm^3) at 20C
pw=0.9980;
% Convert pw to kg/m^3
pw=pw*1000;
% Time step (for decay, in days)
tstep=1;

%% Water Content

% Also considers soil water content losses due to crop and soil evaporation
% ( residue evaporation is left out)
theta=(soilmoist-et)./rootdepth;

%% Pesticide Application Inforamation (date and amount), Planting Date, and Harvest Date

% Application location and amount in kg/m^2
applnofe=scheddata(:,4:7)./10000;
% Application and plow dates
applndate=scheddata(:,3);
plowdate=scheddata(:,10);
% Convert date to a cumulative date for the simulation
[sr,sc]=size(scheddata);
applndatecum=zeros(sr,1);
plowdatecum=zeros(sr,1);
for s=1:1:sr
    % Application of pesticide
    if applndate(s)>0
        if scheddata(s,1)==1 % first year
            applndatecum(s)=applndate(s);
        else % second year and on
            applndatecum(s)=applndate(s)+sum(dayINyearlst(1:scheddata(s,1)-1));
        end;
    else % just in case
        applndatecum(s)=0;
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

% Pesticide in the mixing layer (kg)
pestleftTop=zeros(numsimdays,numofe);
% Pesticide in the deep layer (kg)
pestleftBot=zeros(numsimdays,numofe);
% Total pesticide lost in overland flow with sediment (dissolved and sorbed, kg)
pestlostovlfTot=zeros(numsimdays,numofe);
% Dissolved pesticide lost in overland flow pesticide (kg)
pestlostovlfW=zeros(numsimdays,numofe);
% Sorbed pesticide lost in overland flow pesticide (kg)
pestlostovlfS=zeros(numsimdays,numofe);
% Pesticide lost due to lateral flow (kg)
pestlostlatf=zeros(numsimdays,numofe);
% Pesticide lost due to shallow percolation (kg) (to below mixing layer)
pestlostshalperc=zeros(numsimdays,numofe);
% Pesticide lost due to percolation (kg)
pestlostperc=zeros(numsimdays,numofe);
% Sediment fraction (kg/kg)
sedfraclst=zeros(numsimdays,numofe);
% Mixing depth (m)
hmix=zeros(numsimdays,numofe);
% Pesticide trapped in buffer (kg/m^2)
bufferPest=zeros(numsimdays,numofe);

% Pesticide in the mixing layer (kg/m^2)
pestleftTopkgm2=zeros(numsimdays,numofe);
% Pesticide in the deep layer (kg/m^2)
pestleftBotkgm2=zeros(numsimdays,numofe);
% Total pesticide lost in overland flow with sediment (dissolved and sorbed, kg/m^2)
pestlostovlfTotkgm2=zeros(numsimdays,numofe);
% Dissolved pesticide lost in overland flow pesticide (kg/m^2)
pestlostovlfWkgm2=zeros(numsimdays,numofe);
% Sorbed pesticide lost in overland flow pesticide (kg/m^2)
pestlostovlfSkgm2=zeros(numsimdays,numofe);
% Pesticide lost due to lateral flow (kg/m^2)
pestlostlatfkgm2=zeros(numsimdays,numofe);
% Pesticide lost due to shallow percolation (kg/m^2) (to below mixing layer)
pestlostshalperckgm2=zeros(numsimdays,numofe);
% Pesticide lost due to percolation (kg/m^2)
pestlostperckgm2=zeros(numsimdays,numofe);
% Pesticide trapped in buffer (kg/m^2)
bufferPestkgm2=zeros(numsimdays,numofe);

%% Daily Simulation

k=1;
for id=numofe+1:1:watrow %start at second day and end on second to last day
    i=daylst(id);
    ofe=ofelst(id); 
    % Upslope Pesticide Contributions (dissolved pesticide and particulate
    % pesticide in runnoff as well as dissolved pesticide in lateral flow)
    if ofe>1
        lostPestovldfWUP=pestlostovlfW(i,ofe-1);
        lostPestovldfSUP=pestlostovlfS(i,ofe-1);
        lostPestlaftUP=pestlostlatf(i,ofe-1);
    else
        lostPestovldfWUP=0;
        lostPestovldfSUP=0;
        lostPestlaftUP=0;
    end;
    % Calculate fraction of runoff make up of sediment (kg/kg)
    if ovldf(id)>0
        ovldfvol=ovldf(id)*ofeArea(ofe); % runoff volume
        ovldfmass=ovldfvol*pw;
        sedfrac=sed(id)/ovldfmass;
    else
        sedfrac=0;
    end;
     % Calculate pesticide applied to ofe (kg/actual applied ofe area in m^2)
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
        % Application amount (kg/m^2)
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
        if ofe==numofe % Buffer
            mixdepth=fixedinputdata(1);
        else
            mixdepth=userinputdata(41,ofe);
        end;
    end;
    
    % Set ET of buffer equal to previous OFE
    etnow=et(id);
%     if ofe==numofe
%         etnow=et(id-1);
%     else
%         etnow=et(id);
%     end;
               
    % Non-uniform application with transport between OFEs
    out=dailyofePestsimTransBuff(id,i,k,tstep,apc(croptype(id),ofe),applnamt,mixdepth,hmix(i-1,ofe),ps(croptype(id),ofe),pw,thetaS(croptype(id),ofe),rootdepth(id),applnday,plowday,thalf(croptype(id),ofe),pestleftTop(i-1,ofe),pestleftBot(i-1,ofe),lostPestovldfWUP,lostPestovldfSUP,lostPestlaftUP,ris(id),etnow,ovldf(id),latf(id),perc(id),sedfrac,ofe,buffernum);

    % Mixing depth (m)
    hmix(i,ofe)=mixdepth;    
    
    % Losses (kg)
    pestlostovlfTot(out(3),out(2))=out(5);  % Dissolved and particulate pesticide lost in overland flow (cumulative)
    pestlostovlfW(out(3),out(2))=out(6);    % Dissolved pesticide lost in overland flow (cumulative)
    pestlostovlfS(out(3),out(2))=out(7);    % Particulate pesticide lost in overland flow (cumulative)
    pestlostlatf(out(3),out(2))=out(8);     % Dissolved pesticide lost in lateral flow (cumulative)
    pestlostshalperc(out(3),out(2))=out(9); % Dissolved pesticide lost in shallow percolation (to transition layer, not cumulative)
    pestlostperc(out(3),out(2))=out(10);    % Dissolved pesticide lost in deep percolation (to groundwater, not cumulative)
    pestleftTop(out(3),out(2))=out(11);     % Pesticide left in the mixing layer
    pestleftBot(out(3),out(2))=out(12);     % Pesticide left in the transition layer
    bufferPest(out(3),numofe)=out(13);
    
    % Losses per area (kg/m^2)
    pestlostovlfTotkgm2(out(3),out(2))=out(5)/applnarea;  % Dissolved and particulate pesticide lost in overland flow (cumulative)
    pestlostovlfWkgm2(out(3),out(2))=out(6)/applnarea;    % Dissolved pesticide lost in overland flow (cumulative)
    pestlostovlfSkgm2(out(3),out(2))=out(7)/applnarea;    % Particulate pesticide lost in overland flow (cumulative)
    pestlostlatfkgm2(out(3),out(2))=out(8)/applnarea;     % Dissolved pesticide lost in lateral flow (cumulative)
    pestlostshalperckgm2(out(3),out(2))=out(9)/applnarea; % Dissolved pesticide lost in shallow percolation (to transition layer, not cumulative)
    pestlostperckgm2(out(3),out(2))=out(10)/applnarea;    % Dissolved pesticide lost in deep percolation (to groundwater, not cumulative)
    pestleftTopkgm2(out(3),out(2))=out(11)/applnarea;     % Pesticide left in the mixing layer
    pestleftBotkgm2(out(3),out(2))=out(12)/applnarea;     % Pesticide left in the transition layer
    bufferPestkgm2(out(3),numofe)=out(13)/applnarea;      % Pesticides in the buffer

    % Itterator
    if daylst(id)<=sum(dayINyearlst(1:k))
        k=k+0;
    else
        k=k+1;
    end;
end;

%% Daily

% Daily pesticide losses (kg)
dailyPestdatakg=[pestleftTop,pestleftBot,pestlostovlfTot,pestlostovlfW,pestlostovlfS,pestlostlatf,pestlostshalperc,pestlostperc,bufferPest];
% Daily pesticide losses (kg/m^2)
dailyPestdatakgm2=[pestleftTopkgm2,pestleftBotkgm2,pestlostovlfTotkgm2,pestlostovlfWkgm2,pestlostovlfSkgm2,pestlostlatfkgm2,pestlostshalperckgm2,pestlostperckgm2,bufferPestkgm2];

%% Montly

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
monthlylostPesteros=zeros(mpy*numyrs,numofe);
monthlylostPestovldfnosed=zeros(mpy*numyrs,numofe);
monthlylostPestlatf=zeros(mpy*numyrs,numofe);
monthlylostPestperc=zeros(mpy*numyrs,numofe);
srt=1;
for j=1:1:mpy*numyrs
    for i=1:1:numofe
        monthlylostPesteros(j,i)=sum(pestlostovlfSkgm2(srt:mbiglstcum(j),i));
        monthlylostPestovldfnosed(j,i)=sum(pestlostovlfWkgm2(srt:mbiglstcum(j),i));
        monthlylostPestlatf(j,i)=sum(pestlostlatfkgm2(srt:mbiglstcum(j),i));
        monthlylostPestperc(j,i)=sum(pestlostperckgm2(srt:mbiglstcum(j),i));
    end;
    srt=mbiglstcum(j)+1;
end;

% Save montly data (kg/m^2)
monthlyPestdata=[monthlylostPesteros,monthlylostPestovldfnosed,monthlylostPestlatf,monthlylostPestperc];

%% Monthly Total at Hillslope Base (i.e. last OFE)

monthlyPesteroshill=zeros(mpy*numyrs,1);
monthlyPestovldfnosedhill=zeros(mpy*numyrs,1);
monthlyPestlatfhill=zeros(mpy*numyrs,1);
monthlyPestperchill=zeros(mpy*numyrs,1);

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
    monthlyPesteroshill(k)=monthlylostPesteros(k,numofe);
    monthlyPestovldfnosedhill(k)=monthlylostPestovldfnosed(k,numofe);
    monthlyPestlatfhill(k)=monthlylostPestlatf(k,numofe);
    monthlyPestperchill(k)=sum(monthlylostPestperc(k,1:numofe).*(ofeLength/sum(ofeLength)));
end;

% Monthly total average data at bottom of the hillslope (kg/m^2)
monthlyPesthilldata=[mpylstlong,yrslstlong,monthlyPesteroshill,monthlyPestovldfnosedhill,monthlyPestlatfhill,monthlyPestperchill];

%% Averaging Monthly Totals at Hillslope Base (kg/ha)

% Organize so columns are months and rows are years
monthlyPesterosbymonthhill=zeros(numyrs,mpy);
monthlyPestovldfnosedbymonthhill=zeros(numyrs,mpy);
monthlyPestlatfbymonthhill=zeros(numyrs,mpy);
monthlyPestpercbymonthhill=zeros(numyrs,mpy);

for k=1:1:mpy*numyrs
    monthlyPesterosbymonthhill(yrslstlong(k),mpylstlong(k))=monthlyPesteroshill(k);
    monthlyPestovldfnosedbymonthhill(yrslstlong(k),mpylstlong(k))=monthlyPestovldfnosedhill(k);
    monthlyPestlatfbymonthhill(yrslstlong(k),mpylstlong(k))=monthlyPestlatfhill(k);
    monthlyPestpercbymonthhill(yrslstlong(k),mpylstlong(k))=monthlyPestperchill(k);
end;

% Take mean of each month
monthlyavgPesterosbymonthhill=zeros(mpy,1);
monthlyavgPestovldfnosedbymonthhill=zeros(mpy,1);
monthlyavgPestlatfbymonthhill=zeros(mpy,1);
monthlyavgPestpercbymonthhill=zeros(mpy,1);

% convert to kg/ha
for k=1:1:mpy
    monthlyavgPesterosbymonthhill(k)=mean(monthlyPesterosbymonthhill(:,k))*10000*(ofeLength(numofe)/sum(ofeLength)); % must multiply by length last non-buf ofe/sum of all ofe lengths to get in right units for end of the hillslope b/c wepp .wat inputs are cumulative)
    monthlyavgPestovldfnosedbymonthhill(k)=mean(monthlyPestovldfnosedbymonthhill(:,k))*10000*(ofeLength(numofe)/sum(ofeLength));
    monthlyavgPestlatfbymonthhill(k)=mean(monthlyPestlatfbymonthhill(:,k))*10000*(ofeLength(numofe)/sum(ofeLength));
    monthlyavgPestpercbymonthhill(k)=mean(monthlyPestpercbymonthhill(:,k))*10000; % already took weighted average above
end;

% Monthly averages lost at base of hillslope (kg/ha)
monthlyPesthillavgdata=[transpose(mpylst),monthlyavgPesterosbymonthhill,monthlyavgPestovldfnosedbymonthhill,monthlyavgPestlatfbymonthhill,monthlyavgPestpercbymonthhill];

%% Yearly

yearlylostPesteros=zeros(numyrs,numofe);
yearlylostPestovldfnosed=zeros(numyrs,numofe);
yearlylostPestlatf=zeros(numyrs,numofe);
yearlylostPestperc=zeros(numyrs,numofe);
srt=1;
for k=1:1:numyrs
    for i=1:1:numofe
        yearlylostPesteros(k,i)=sum(pestlostovlfSkgm2(srt:sum(dayINyearlst(1:k)),i));
        yearlylostPestovldfnosed(k,i)=sum(pestlostovlfWkgm2(srt:sum(dayINyearlst(1:k)),i));
        yearlylostPestlatf(k,i)=sum(pestlostlatfkgm2(srt:sum(dayINyearlst(1:k)),i));
        yearlylostPestperc(k,i)=sum(pestlostperckgm2(srt:sum(dayINyearlst(1:k)),i));
    end;
    srt=srt+dayINyearlst(k);
end;

% Save yearly data (kg/m^2)
yearlyPestdata=[yearlylostPesteros,yearlylostPestovldfnosed,yearlylostPestlatf,yearlylostPestperc];

%% Yearly Net Averages by OFE

yearlylostPesterosavg=zeros(1,numofe);
yearlylostPestovldfnosedavg=zeros(1,numofe);
yearlylostPestlatfavg=zeros(1,numofe);
yearlylostPestpercavg=zeros(1,numofe);

for ofe=1:1:numofe
    if ofe>1
        yearlylostPesterosavg(1,ofe)=(sum(yearlylostPesteros(:,ofe))-sum(yearlylostPesteros(:,ofe-1)))/numyrs;
        yearlylostPestovldfnosedavg(1,ofe)=(sum(yearlylostPestovldfnosed(:,ofe))-sum(yearlylostPestovldfnosed(:,ofe-1)))/numyrs;
        yearlylostPestlatfavg(1,ofe)=(sum(yearlylostPestlatf(:,ofe))-sum(yearlylostPestlatf(:,ofe-1)))/numyrs;
        yearlylostPestpercavg(1,ofe)=sum(yearlylostPestperc(:,ofe))/numyrs;
    else
        yearlylostPesterosavg(1,ofe)=sum(yearlylostPesteros(:,ofe))/numyrs;
        yearlylostPestovldfnosedavg(1,ofe)=sum(yearlylostPestovldfnosed(:,ofe))/numyrs;
        yearlylostPestlatfavg(1,ofe)=sum(yearlylostPestlatf(:,ofe))/numyrs;
        yearlylostPestpercavg(1,ofe)=sum(yearlylostPestperc(:,ofe))/numyrs;   
    end;
end;

% Yearly average (kg/m^2)
yearlyPestavgdata=[yearlylostPesterosavg;yearlylostPestovldfnosedavg;yearlylostPestlatfavg;yearlylostPestpercavg];

%% Yearly Total at Hillslope Base (i.e. buffer)

yearlyPesteroshill=zeros(numyrs,1);
yearlyPestovldfnosedhill=zeros(numyrs,1);
yearlyPestlatfhill=zeros(numyrs,1);
yearlyPestperchill=zeros(numyrs,1);

for k=1:1:numyrs
    yearlyPesteroshill(k)=yearlylostPesteros(k,numofe).*(ofeLength(numofe)/sum(ofeLength)); % must multiply by length last non-buffer ofe/sum of all ofe lengths to get in right units for end of the hillslope b/c wepp .wat inputs are cumulative)
    yearlyPestovldfnosedhill(k)=yearlylostPestovldfnosed(k,numofe).*(ofeLength(numofe)/sum(ofeLength));
    yearlyPestlatfhill(k)=yearlylostPestlatf(k,numofe).*(ofeLength(numofe)/sum(ofeLength));
    yearlyPestperchill(k)=sum(yearlylostPestperc(k,1:numofe).*(ofeLength/sum(ofeLength))); % calc average of perc from all ofes
end;

% numofeFIX=3;
% for k=1:1:numyrs
%     yearlyPesteroshill(k)=yearlylostPesteros(k,numofeFIX).*(70/270); % must multiply by length last non-buffer ofe/sum of all ofe lengths to get in right units for end of the hillslope b/c wepp .wat inputs are cumulative)
%     yearlyPestovldfnosedhill(k)=yearlylostPestovldfnosed(k,numofeFIX).*(70/270);
%     yearlyPestlatfhill(k)=yearlylostPestlatf(k,numofeFIX).*(70/270);
%     yearlyPestperchill(k)=sum(yearlylostPestperc(k,1:numofeFIX).*(70/270)); % calc average of perc from all ofes
% end;

% Yearly data at bottom of the hillslope (kg/m^2)
yearlyPesthilldata=[yearlyPesteroshill,yearlyPestovldfnosedhill,yearlyPestlatfhill,yearlyPestperchill];

%% Yearly Total Averages at Hillslope Base (i.e. buffer)

% Yearly averages lost at base of hillslope (kg/ha)
yearlyPesthillavgdata=zeros(4,1);
for i=1:1:4
    yearlyPesthillavgdata(i)=mean(yearlyPesthilldata(:,i)).*10000;
end;
