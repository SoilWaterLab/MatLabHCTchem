% Daily Pesticide Tranport Function

% Author: Sheila Saia
% Email: sms493@cornell.edu
% Last Updated: Mar 1, 2013

% This function calcultes the change in soil pesticide over time for a thin
% mixing layer at the surface and a thicker transition layer (root
% depth-mixing layer depth=transition layer depth).  These changes as well
% as the losses from the soil pesticide pool are exported as outputs
% expressed in units kg. Additions and processes included in this
% function are: additions from upslope ofes, pesticide application,
% leaching (dissolved and adsorbed pesticide), and decay.

% References: Steenhuis and Walter 1980, Sinkevich et al 2005, Ghidey et
% al. 2005

function pesticideDailyDATA=dailyofePestsimTrans(id,day,yr,tstep,apc,applnamt,mixdepth,hmixprev,ps,pw,thetaS,rootdepth,applnday,plowday,thalf,pestleftTop,pestleftBot,lostPestovldfWUP,lostPestovldfSUP,lostPestlaftUP,rain,evap,qovlf,qlatf,qperc,sedfrac,ofe)

% Rename incoming variables
pestleftTopnow=pestleftTop;
pestleftBotnow=pestleftBot;

% Transported Pesticides from upslope OFEs
pestleftTopnow=pestleftTopnow+lostPestovldfWUP+lostPestovldfSUP;
pestleftBotnow=pestleftBotnow+lostPestlaftUP;

% Plowing day indicates a mixing of pesticide to the deeper transition
% later based on the plow depth, determine fraction that enters by
% comparing the previous mixing depth to the current mixing depth (=plow
% depth)
if day==plowday
    % ensure fraction is less than 1
    if (hmixprev/mixdepth)>1
        fplow=mixdepth/hmixprev;
    else
        fplow=hmixprev/mixdepth;
    end;    
    pestleftTopnow=fplow*pestleftTopnow;
    pestleftBotnow=(1-fplow)*pestleftTopnow+pestleftBotnow;
end;

% For calculations with runoff we want smallest mixing depth
hmixnow=min(hmixprev,mixdepth);

% Application of pesticide to mixing layer of soil (=top layer)
if day==applnday
    if applnamt>0
        pestleftTopnow=pestleftTopnow+applnamt;
        % No pesticide lost to decay in the top layer the day it's added
        % but pesticide is lost from the bottom layer
        pestleftBotnow=pestleftBotnow*exp(-0.69*tstep/thalf);
    else
        % Pesticide lost to decay
        pestleftTopnow=pestleftTopnow*exp(-0.69*tstep/thalf);
        pestleftBotnow=pestleftBotnow*exp(-0.69*tstep/thalf);
    end;
else
    % Pesticide lost to decay
    pestleftTopnow=pestleftTopnow*exp(-0.69*tstep/thalf);
    pestleftBotnow=pestleftBotnow*exp(-0.69*tstep/thalf);
end;

if qovlf==0 % No runoff
    %No pesticide lost to overland flow (dissolved or sediment bound)
    %because soil is not saturated
    pestlostovlfTot=0;
    pestlostovlfW=0;
	pestlostovlfS=0;
    
    %Pesticide lost to shallow percolation (from mixing to deeper layer)
    if (pestleftTopnow>0)&&(rain-evap>0)
        pestlostshalperc=pestleftTopnow*(1-exp(-(rain-evap)/(hmixnow*(thetaS+apc*ps))));
        if pestlostshalperc<=pestleftTopnow
            pestlostshalperc=pestleftTopnow*(1-exp(-(rain-evap)/(hmixnow*(thetaS+apc*ps))));
            pestleftTopnow=pestleftTopnow-pestlostshalperc;
            pestleftBotnow=pestleftBotnow+pestlostshalperc;
        else
            pestleftTopnow=0;
            pestleftBotnow=pestleftBotnow+pestleftTopnow;
            pestlostshalperc=pestleftTopnow;
        end;
    else
        pestlostshalperc=0;        
    end;
    
    %Pesticide lost in lateral flow (from below mixing layer)
    if (pestleftBotnow>0)&&(qlatf>0)
         pestlostlatf=pestleftBotnow*(1-exp(-(qlatf)/((rootdepth-hmixnow)*(thetaS+apc*ps))));
         if pestlostlatf<=pestleftBotnow
            pestlostlatf=pestleftBotnow*(1-exp(-(qlatf)/((rootdepth-hmixnow)*(thetaS+apc*ps))));
            pestleftBotnow=pestleftBotnow-pestlostlatf;           
         else
            pestleftBotnow=0;
            pestlostlatf=pestleftBotnow;
         end; 
    else
        pestlostlatf=0;
    end;
    
    %Pesticide lost in percolation (from below mixing layer)
    if (pestleftBotnow>0)&&(qperc>0)
        pestlostperc=pestleftBotnow*(1-exp(-(qperc)/((rootdepth-hmixnow)*(thetaS+apc*ps))));
        if pestlostperc<=pestleftBotnow
            pestlostperc=pestleftBotnow*(1-exp(-(qperc)/((rootdepth-hmixnow)*(thetaS+apc*ps))));
            pestleftBotnow=pestleftBotnow-pestlostperc;
        else
            pestleftBotnow=0;
            pestlostperc=pestleftBotnow;
        end;
    else
        pestlostperc=0;
    end;
            
elseif qovlf>0
    %Overland flow with sediment (m)
    qovlfx=qovlf*(1+(((sedfrac*apc)/(1-sedfrac))*pw)); 
    %Total pesticide lost
    pestlostovlfTot=pestleftTopnow*(1-exp(-(qovlfx)/(hmixnow*(thetaS+apc*ps))));
    if pestlostovlfTot<=pestleftTopnow
        pestlostovlfTot=pestleftTopnow*(1-exp(-(qovlfx)/(hmixnow*(thetaS+apc*ps))));
        pestleftTopnow=pestleftTopnow-pestlostovlfTot;
        %Dissolved pesticide lost in overland flow (kg/m^2)
        pestlostovlfW=(pestlostovlfTot*(1-sedfrac))/(1+sedfrac*(apc*pw-1));
        %Sorbed pesticide lost in overland flow (kg/m^2)
        pestlostovlfS=(pestlostovlfTot*apc*pw*sedfrac)/(1+sedfrac*(apc*pw-1));
    else
        pestlostovlfTot=pestleftTopnow;
        pestleftTopnow=0;
        %Dissolved pesticide lost in overland flow (kg/m^2)
        pestlostovlfW=(pestlostovlfTot*(1-sedfrac))/(1+sedfrac*(apc*pw-1));
        %Sorbed pesticide lost in overland flow (kg/m^2)
        pestlostovlfS=(pestlostovlfTot*apc*pw*sedfrac)/(1+sedfrac*(apc*pw-1));
    end;
    
    %Pesticide lost to shallow percolation (from mixing to deeper layer)
    if (pestleftTopnow>0)&&(rain-evap>0)
        pestlostshalperc=pestleftTopnow*(1-exp(-(rain-evap)/(hmixnow*(thetaS+apc*ps))));
        if pestlostshalperc<=pestleftTopnow
            pestlostshalperc=pestleftTopnow*(1-exp(-(rain-evap)/(hmixnow*(thetaS+apc*ps))));
            pestleftTopnow=pestleftTopnow-pestlostshalperc;
            pestleftBotnow=pestleftBotnow+pestlostshalperc;
        else
            pestleftTopnow=0;
            pestleftBotnow=pestleftBotnow+pestleftTopnow;
            pestlostshalperc=pestleftTopnow;
        end;
    else
        pestlostshalperc=0;
    end;
    
    %Pesticide lost in lateral flow (from below mixing layer)
    if (pestleftBotnow>0)&&(qlatf>0)
         pestlostlatf=pestleftBotnow*(1-exp(-(qlatf)/((rootdepth-hmixnow)*(thetaS+apc*ps))));
         if pestlostlatf<=pestleftBotnow
            pestlostlatf=pestleftBotnow*(1-exp(-(qlatf)/((rootdepth-hmixnow)*(thetaS+apc*ps))));
            pestleftBotnow=pestleftBotnow-pestlostlatf;           
         else
            pestleftBotnow=0;
            pestlostlatf=pestleftBotnow;
         end; 
    else
        pestlostlatf=0;
    end;
    
    %Pesticide lost in percolation (from below mixing layer)
    if (pestleftBotnow>0)&&(qperc>0)
        pestlostperc=pestleftBotnow*(1-exp(-(qperc)/((rootdepth-hmixnow)*(thetaS+apc*ps))));
        if pestlostperc<=pestleftBotnow
            pestlostperc=pestleftBotnow*(1-exp(-(qperc)/((rootdepth-hmixnow)*(thetaS+apc*ps))));
            pestleftBotnow=pestleftBotnow-pestlostperc;            
        else
            pestleftBotnow=0;
            pestlostperc=pestleftBotnow;
        end;
    else
        pestlostperc=0;
    end;
end;

pesticideDailyDATA=[id,ofe,day,yr,pestlostovlfTot,pestlostovlfW,pestlostovlfS,pestlostlatf,pestlostshalperc,pestlostperc,pestleftTopnow,pestleftBotnow];

