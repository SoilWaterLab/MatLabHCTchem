%% Import schedule data file

scheddata=importdata('sched01.txt'); % <--- enter schedule file name here
[sr,sc]=size(scheddata);
% List of all crop id's from schedule file
cropid=scheddata(:,2);
% List of all unique crop id's (condensed)
cropidselect=unique(cropid);
% Create a max root depth list for each crop id
maxrootdepthlst=zeros(length(cropidselect),1);
for i=1:1:length(cropidselect)
    a=find(cropid==cropidselect(i));
    firsta=a(1);
    % Assume that the crop has the same max root depth for all years
    maxrootdepthlst(i)=scheddata(a(i),12); % cm
end;

%% Import the soil data (bulk density, water concents, and organic matter)

soildata=importdata('soil01.txt'); % <--- enter soil file name here
% Average bulk density (g/cm^3) for the profile for each crop
avgbulkdens=zeros(length(cropidselect),1);
% Average organic matter (%) for the profile for each crop
avgom=zeros(length(cropidselect),1);
% Average water content at field capacity (decimal %) for each crop
avgthetaFC=zeros(length(cropidselect),1);
% Average water content at wilting point (decimal %) for each crop
avgthetaWP=zeros(length(cropidselect),1);
% Average water content at saturation (decimal %) for each crop
avgthetaS=zeros(length(cropidselect),1);
for k=1:1:length(cropidselect)
    depths=soildata(:,1)./10; % given in mm so convert to cm

    if depths(1)>maxrootdepthlst(k)
    % If max root depth is less than the end point of the first horizon
    % then the soil properies do not need to be averaged.
    avgbulkdens(k)=soildata(1,2);
        avgom(k)=soildata(1,9);
        avgthetaFC(k)=soildata(1,5);
        avgthetaWP(k)=soildata(1,6);
        avgthetaS(k)=1-(avgbulkdens(k)/2.65);
    else
    % If the max root depth is more than the end point of the first horizon
    % then a weighted average of the soil properties must be calculated.
    s=length(depths);
        for i=1:1:s
            if i<s
                if depths(i)<maxrootdepthlst(k)
                    avgbulkdens(k)=avgbulkdens(k)+(depths(i)/maxrootdepthlst(k))*soildata(i,2);
                    avgom(k)=avgom(k)+(depths(i)/maxrootdepthlst(k))*soildata(i,9);
                    avgthetaFC(k)=avgthetaFC(k)+(depths(i)/maxrootdepthlst(k))*soildata(i,5);
                    avgthetaWP(k)=avgthetaWP(k)+(depths(i)/maxrootdepthlst(k))*soildata(i,6);
                    avgthetaS(k)=1-(avgbulkdens(k)/2.65);
                end;
            else
            %Assume that last row is equal to or greater than the max root depth
                if (depths(i-1)<maxrootdepthlst(k))&&(depths(i)>maxrootdepthlst(k))
                    avgbulkdens(k)=avgbulkdens(k)+((sum(depths(1:i-1))-maxrootdepthlst(k))/maxrootdepthlst(k))*soildata(i,2);
                    avgom(k)=avgom(k)+((maxrootdepthlst(k)-depths(i-1))/maxrootdepthlst(k))*soildata(i,9);
                    avgthetaFC(k)=avgthetaFC(k)+((sum(depths(1:i-1))-maxrootdepthlst(k))/maxrootdepthlst(k))*soildata(i,5);
                    avgthetaWP(k)=avgthetaWP(k)+((sum(depths(1:i-1))-maxrootdepthlst(k))/maxrootdepthlst(k))*soildata(i,6);
                    avgthetaS(k)=1-(avgbulkdens(k)/2.65);
                end;
            end;    
        end;    
    end;
end;
