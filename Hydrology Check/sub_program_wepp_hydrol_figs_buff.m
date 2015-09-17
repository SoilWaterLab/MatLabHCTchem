% sub_program_wepp_hydrol_figs.m

% Author: Sheila Saia
% Email: sms493@cornell.edu
% Last Updated: Mar 1, 2013

% This file is needed to run 'program_wepp_hydrol_figs.m'. Basically, it
% keeps track of daily WEPP outputs and sums them over the entire year for
% each simulation.

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
% colm2: julien day
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
yrs=1:1:max(elemdata(:,4));
for k=1:1:max(elemdata(:,4));
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
% colm2: julien day
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
% cropdata=[watdata(:,1),cropdata];
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
        
%% Final Compiled Water Balance File (wat.txt)

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

%% Hydrologic Processes from WEPP

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
% Precipitation (snow or rain) (mm) (non-cumulative)
precip=watdata(:,5);
% Rainfall+snowmelt+irrigation (mm) (non-cumulative)
ris=watdata(:,6);
% Calculate the area of the ofe
ofeWidth=userinputdata(39,:);
ofeArea=ofeLength.*ofeWidth;
% Overland flow scaled to single ofe (mm)
ovldf=watdata(:,18);
% Lateral flow passing through the OFE (mm)
latf=watdata(:,14);
% Percolation (m)
perc=watdata(:,11);
% Sediment leaving an OFE per width (kg/m)
sedkgm=watdata(:,22);
% Sediment leaving an OFE (kg)
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
% Crop transpiration (mm)
cropevap=watdata(:,8);
% Soil evaporation (mm)
soilevap=watdata(:,9);
% Residue evaporation (mm)
residueevap=watdata(:,10);
% Evapotranspiration (ET) (mm)
et=cropevap+soilevap+residueevap;

%% Daily

dailyprecip=zeros(numsimdays,numofe);
dailyevap=zeros(numsimdays,numofe);
dailyovldf=zeros(numsimdays,numofe);
dailylatf=zeros(numsimdays,numofe);
dailyperc=zeros(numsimdays,numofe);
dailysedmass=zeros(numsimdays,numofe); % in kg
dailynetsed=zeros(numsimdays,numofe);  % in kg

for i=1:1:watrow
    dailyprecip(watdata(i,2),watdata(i,1))=precip(i);
    dailyevap(watdata(i,2),watdata(i,1))=et(i);
    dailyovldf(watdata(i,2),watdata(i,1))=ovldf(i);
    dailylatf(watdata(i,2),watdata(i,1))=latf(i);
    dailyperc(watdata(i,2),watdata(i,1))=perc(i);
    dailysedmass(watdata(i,2),watdata(i,1))=sed(i);
    dailynetsed(watdata(i,2),watdata(i,1))=netsed(i);
end;

% Saving everything
dailydata=[dailyovldf,dailylatf,dailyperc,dailysedmass,dailynetsed,dailyprecip,dailyevap];

%% Montly

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
monthlyprecip=zeros(mpy*numyrs,numofe);
monthlyevap=zeros(mpy*numyrs,numofe);
monthlyovldf=zeros(mpy*numyrs,numofe);
monthlylatf=zeros(mpy*numyrs,numofe);
monthlyperc=zeros(mpy*numyrs,numofe);
monthlysedmass=zeros(mpy*numyrs,numofe);
monthlynetsed=zeros(mpy*numyrs,numofe);
srt=1;
for j=1:1:mpy*numyrs
    for i=1:1:numofe
        monthlyprecip(j,i)=sum(dailyprecip(srt:mbiglstcum(j),i));
        monthlyevap(j,i)=sum(dailyevap(srt:mbiglstcum(j),i));
        monthlyovldf(j,i)=sum(dailyovldf(srt:mbiglstcum(j),i));
        monthlylatf(j,i)=sum(dailylatf(srt:mbiglstcum(j),i));
        monthlyperc(j,i)=sum(dailyperc(srt:mbiglstcum(j),i));
        monthlysedmass(j,i)=sum(dailysedmass(srt:mbiglstcum(j),i));
        monthlynetsed(j,i)=sum(dailynetsed(srt:mbiglstcum(j),i));
    end;
    srt=mbiglstcum(j)+1;
end;

% Save montly data
monthlydata=[monthlyprecip,monthlyevap,monthlyovldf,monthlylatf,monthlyperc,monthlysedmass,monthlynetsed];

%% Yearly

yearlyprecipsum=zeros(numyrs,numofe);
yearlyevapsum=zeros(numyrs,numofe);
yearlyovldfsum=zeros(numyrs,numofe);
yearlylatfsum=zeros(numyrs,numofe);
yearlypercsum=zeros(numyrs,numofe);
yearlysedmasssum=zeros(numyrs,numofe); % in kg
yearlynetsedsum=zeros(numyrs,numofe);  % in kg

srt=1;
for k=1:1:numyrs
    for ofe=1:1:numofe
        yearlyprecipsum(k,ofe)=sum(dailyprecip(srt:sum(dayINyearlst(1:k)),ofe));
        yearlyevapsum(k,ofe)=sum(dailyevap(srt:sum(dayINyearlst(1:k)),ofe));        
        yearlyovldfsum(k,ofe)=sum(dailyovldf(srt:sum(dayINyearlst(1:k)),ofe));
        yearlylatfsum(k,ofe)=sum(dailylatf(srt:sum(dayINyearlst(1:k)),ofe));
        yearlypercsum(k,ofe)=sum(dailyperc(srt:sum(dayINyearlst(1:k)),ofe));
        yearlysedmasssum(k,ofe)=sum(dailysedmass(srt:sum(dayINyearlst(1:k)),ofe));
        yearlynetsedsum(k,ofe)=sum(dailynetsed(srt:sum(dayINyearlst(1:k)),ofe));
    end;
    srt=srt+dayINyearlst(k);
end;

% Saving everything
yearlydata=[yearlyprecipsum,yearlyevapsum,yearlyovldfsum,yearlylatfsum,yearlypercsum,yearlysedmasssum,yearlynetsedsum,];

%% Yearly (for total hillslope, i.e. the last OFE)

% in m excep for sediment loss
yearlypreciphill=zeros(numyrs,1);
yearlyevaphill=zeros(numyrs,1);
yearlyovldfhill=zeros(numyrs,1);
yearlylatfhill=zeros(numyrs,1);
yearlyperchill=zeros(numyrs,1);
yearlysedhill=zeros(numyrs,1);    % in kg

for k=1:1:numyrs
    yearlypreciphill(k)=yearlyprecipsum(k,numofe);
    yearlyevaphill(k)=sum(yearlyevapsum(k,1:numofe).*(ofeLength/sum(ofeLength))); % weighted average of all ofe's
    yearlyovldfhill(k)=yearlyovldfsum(k,numofe).*(ofeLength(numofe)/sum(ofeLength));
    yearlylatfhill(k)=yearlylatfsum(k,numofe).*(ofeLength(numofe)/sum(ofeLength)); 
    yearlyperchill(k)=sum(yearlypercsum(k,1:numofe).*(ofeLength/sum(ofeLength))); % weighted average of all ofe's
    yearlysedhill(k)=(yearlysedmasssum(k,numofe)./(ofeWidth(numofe)*sum(ofeLength(1:numofe)))).*10000;
end;

% Saving everything
yearlyhilldata=[yearlypreciphill,yearlyevaphill,yearlyovldfhill,yearlylatfhill,yearlyperchill,yearlysedhill];

%% Yearly Average at Hillslope Base

yearlyhillavgdata=zeros(6,1);
for i=1:1:6
    yearlyhillavgdata(i)=mean(yearlyhilldata(:,i));
end;
