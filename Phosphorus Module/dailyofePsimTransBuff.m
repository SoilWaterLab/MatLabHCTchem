% Daily Phosphorus Tranport Function

% Author: Sheila Saia
% Email: sms493@cornell.edu
% Last Updated: Mar 1, 2013

% This function calcultes the change in fertilizer P over time.  These
% changes as well as the losses from the fertilizer P pool are exported as
% outputs expressed in units kg.  In this model fertilzer P concentrations
% are used to determine dissolved and particulate bound P loss from
% overland flow processes while soil test P values are used to calculate
% losses from lateral flow and percolation.  This model only simulates P
% transport in/out of the mixing (top) and transition (bottom) layer.

% References: Easton et al 2007a and 2007b, Easton et al 2009

function phosphorusDailyDATA=dailyofePsimTransBuff(id,day,yr,tstep,tau,hmixprev,mixdepth,ofeArea,kdissolv,stpconc,mewTS,QS,TR,plowday,applnday,applnamt,avalsolPfertprev,lostPfertUP,lostPplntsoilUP,lostPlatUP,avgT,qovlf,qlatf,qperc,sed,sedfrac,ofe,buffernum)
% P concentration in soil pore water
swpconc=0.1*stpconc;

% Rename incoming variables
dissolvPnow=avalsolPfertprev;
% Adding in P lost from upslope ofes
dissolvPnow=dissolvPnow+lostPfertUP+lostPplntsoilUP;

% Plowing day indicates a mixing of pesticide to the deeper transition
% later based on the plow depth, determine fraction that enters by
% comparing the previous mixing depth to the current mixing depth (=plow
% depth)
if day==plowday
    fplow=hmixprev/mixdepth;
    dissolvPnow=fplow*dissolvPnow;
end;

if day==applnday
    if applnamt>0
        % No P lost to decay the day it's added
        dissolvPnow=dissolvPnow+applnamt;        
    else
        % P lost to decay
        dissolvPnow=dissolvPnow*exp(-tstep/tau);
    end;
else
    % P lost to decay
    dissolvPnow=dissolvPnow*exp(-tstep/tau);
end;

% P lost from fertilized areas (in overland flow)
if qovlf>0
    if dissolvPnow>0
        lostPfert=dissolvPnow*((kdissolv*dissolvPnow*qovlf)/(1+(kdissolv*dissolvPnow*qovlf)));
        if lostPfert<=dissolvPnow
            lostPfert=dissolvPnow*((kdissolv*dissolvPnow*qovlf)/(1+(kdissolv*dissolvPnow*qovlf)));
            dissolvPnow=dissolvPnow-lostPfert;
        else
            lostPfert=dissolvPnow;
            dissolvPnow=0;
        end;
    else
        lostPfert=0;
        dissolvPnow=0;
    end;
else
    lostPfert=0;
end;

% P lost due to plant (biotic) and soil (aboitic) interactions (in
% overland flow)
if qovlf>0
    mewS=mewTS*arrhenius(avgT,TR,QS);
    swpmass=swpconc*(qovlf*ofeArea); % mass=conc*volume
    lostPplntsoil=mewS*(swpmass+lostPlatUP)*qovlf; 
else
    lostPplntsoil=0;
end;

% P lost due to erosion
if sed>0
    if ofe<buffernum
        lostPeros=sedfrac*sed;
        bufferP=0;
    else
        lostPeros=0;
        bufferP=sedfrac*sed;
    end;
else
    lostPeros=0;
    bufferP=0;
end;

% P lost due to lateral flow (includes upslope losses)
if qlatf>0
    mewS=mewTS*arrhenius(avgT,TR,QS);
    swpmasslatf=swpconc*(qlatf*ofeArea); % mass=conc*volume
    % latfconc=swpconc+(lostPlatUP/(qlatf*ofeArea));
    % lostPlatf=latfconc*qlatf;
    lostPlatf=mewS*(swpmasslatf+lostPlatUP)*qlatf;
else
    lostPlatf=0;
end;

% P Lost Due to Percolation
if qperc>0
    mewS=mewTS*arrhenius(avgT,TR,QS);
    swpmassperc=swpconc*(qperc*ofeArea); % mass=conc*volume
    % percconc=swpconc+(lostPlatUP/(qperc*ofeArea));
    % lostPperc=percconc*qperc;
    lostPperc=mewS*(swpmassperc+lostPlatUP)*qperc;
else
    lostPperc=0;
end;
phosphorusDailyDATA=[id,ofe,day,yr,dissolvPnow,lostPfert,lostPplntsoil,lostPeros,lostPlatf,lostPperc,bufferP];

