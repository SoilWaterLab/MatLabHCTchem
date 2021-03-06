% Daily Nitrogen Transport Function

% Author: Sheila Saia
% Email: sms493@cornell.edu
% Last Updated: Mar 1, 2013

% This function calcultes the change in various N pools over time (no3,
% nh4, organic N active, organic N fresh, and organic N stable) for all
% ofe's.  These changes as well as the losses from each pool are lumped for
% the entire extent of the profile and exported as outputs expressed in
% units kg.  Additions and processes included in this function are:
% additions from upslope ofes, additions from rainfall, manure and
% fertilization application, plant uptake of no3 and nh4, nitrification,
% denitrification, decomposition, minearlization, immobilization, N
% transfer between organic N active and organic N stable pools, leaching of
% no3, decay of organic N pools, as well as harvesting and plowing of the
% crop (if necessary).  This model only simulates N transport in/out of the
% one layer of the soil where the depth is defined by the maximum root
% depth.

% References: Johnsson et al 1987, SWAT Theoretical Documentation (USDA
% 2005 ch 3:1,4:2), Heinen et al 2006, Berstrom et al 1991, Meyer at al
% 2007, Williams et al 1984, Stotte et al 1986?, Brutsaert 1982

% TO DO/CHECK
% 1. decay of organic c and nitrate pools?
% 2. check mineralization/immobi of orgN active pool to nh4
% 3. manure application goes to c pools?
% 4. processes stopped when temp is below minT...check which are included
% 5. active c cycling in immob/mineralization? does this happen?
% 6. plowing for mulch till?
% 7. fresh residue (cropresidues) for the entire profile...average wepp
% outputs?
% 8. check initialization of carbon pools

function nitrogenDailyDATA=dailyofeNsiM1layTrans(id,day,yr,numday,applnarea,cropresidue,rootdepth,no3surf,soilNmass,manureN,fertN,applnday,normallai,harvestday,plowday,thalfNact,thalfNfrsh,thalfNstab,ps,oc,thetaS,thetaWP,thetaHO,thetaLO,thetathresh,theta,kd,fact,fabove,fleft,fharv,fmax,nq,tstep,Q10,Tb,es,kn,cs,kh,ftrans,cnthrsh,kf,fe,fh,minT,no3rain,nh4rain,plantNprev,nh4prev,no3prev,orgNactprev,orgNfrshprev,orgNstabprev,no3lostovldfUP,no3lostlaftUP,orgNactlostovldUP,orgNfrshlostovldUP,orgNstablostovldUP,cactprev,cfrshprev,cstabprev,avgT,soilTlst,qovldf,qlatf,qperc,sedfrac,ofe)

% Rename incoming variables
plantNnow=plantNprev;
nh4now=nh4prev;
no3now=no3prev;
orgNactnow=orgNactprev;
orgNfrshnow=orgNfrshprev;
orgNstabnow=orgNstabprev;
cactnow=cactprev;
cfrshnow=cfrshprev;
cstabnow=cstabprev;

% Additions from upslope ofes, rainfall, manure application, inorganic
% fertilizer application, carbon pools, harvest of crop and plowing of
% field
for soillyr=1    
    % Transported N from upslope ofe's
    no3now=no3now+no3lostovldfUP+no3lostlaftUP;
    orgNactnow=orgNactnow+orgNactlostovldUP;
    orgNfrshnow=orgNfrshnow+orgNfrshlostovldUP;
    orgNstabnow=orgNstabnow+orgNstablostovldUP;
    
    % Deposition from rain
    nh4now=nh4now+nh4rain;
    no3now=no3now+no3rain;
      
    % One time manure application
    if day==applnday(1)
        % One time manure application
        nh4now=nh4now+0.5*manureN;
        orgNactnow=orgNactnow+0.25*manureN;
        orgNfrshnow=orgNfrshnow+0.125*manureN;
        orgNstabnow=orgNstabnow+0.125*manureN;
        % cfrsh added?
        % cact added?
        % One time inorganic fertilizer application
        no3now=no3now+fertN;
    end;
    
    % One time harvesting of crop
    if day==harvestday
        orgNfrshnow=orgNfrshnow+normallai*(1-fabove-fleft-fharv)*plantNnow;
        cfrshnow=cfrshnow+25*(1-fabove-fleft-fharv)*plantNnow;  % 25 is C-N ratio for roots
    end;
    
    % One time plowing of crop
    if day==plowday
        orgNfrshnow=orgNfrshnow+(fabove+fleft)*plantNnow;
        cfrshnow=cfrshnow+50*(fabove+normallai)*plantNnow;  % 50 is C-N ratio for above-ground harvest residues   %check this!
    end;
    
    % Yearly addition to pools
    if numday==1
        % no3
        intno3conc=no3surf*exp(-rootdepth/1000);
        no3now=no3now+(intno3conc*ps*(rootdepth*applnarea));
        % orgNact
        orgNactnow=orgNactnow+soilNmass*fact;
        % orgNfrsh
        orgNfrshnow=orgNfrshnow+0.0015*cropresidue;
        % orgNstab
        orgNstabnow=orgNstabnow+soilNmass*(1-fact);
        % cact (equal to 10% of crop residual on ground)
        cactnow=0.1*cropresidue;
        % cfresh (equal to 58% of crop residue on ground)
        cfrshnow=0.58*cropresidue;
        % cstab (equal to OC% in soil as mass)
        cstabnow=oc*ps*(rootdepth*applnarea);
    end;
end;
        
% Plant uptake of nh4 and no3
for soillyr=1
    if applnday(1)<=day<harvestday
        % Potential nh4 uptake
        if (nh4now+no3now)<=0       % Prevents inf and negatives
            potnh4plantup=0;
        else
            potnh4plantup=normallai*(nh4now/(nh4now+no3now));
        end;
        
        % Actual nh4 uptake
        if potnh4plantup<=nh4now
            % Case where soil has enough nh4
            nh4now=nh4now-potnh4plantup;
            plantNnow=plantNnow+potnh4plantup;
        else
            % Case where soil does not have enough nh4
            nh4now=nh4now-nh4now;
            plantNnow=plantNnow+nh4now;
        end;
        
        % Potential no3 uptake
        if (nh4now+no3now)<=0       % Prevents inf and negatives
            potno3plantup=0;
        else
            potno3plantup=normallai*(no3now/(nh4now+no3now));
        end;
        
        % Actual no3 uptake        
        if potno3plantup<=no3now
            % Case where soil has enough no3
            no3now=no3now-potno3plantup;
            plantNnow=plantNnow+potno3plantup;            
        else
            % Case where soil does not have enough no3
            no3now=no3now-no3now;
            plantNnow=plantNnow+no3now+no3now; 
        end;
    end;
end;
    
% Chemical processes
% These include:  nitrification, denitrification,
% decomposition,minearlization, immobilization, ntransfer
% Note:  Here we assume that the soil T must be above a minimum temperature
% (minT) for these processes to occure
for soillyr=1;
    if avgT>minT
        % Nitrification of nh4 (nh4 to no3)
        if nh4now>0
            if (no3now/nh4now)<nq     % nq is the no3/nh4 ratio for a given soil
                nitrifN=kn*arrhenius(soilTlst,Tb,Q10)*moistfact(es,thetaWP,thetaS,thetaHO,thetaLO,theta)*(nh4now-(no3now/nq));
                if nitrifN<=nh4now
                    nh4now=nh4now-nitrifN;
                    no3now=no3now+nitrifN;
                else
                    nh4now=nh4now-nh4now;
                    no3now=no3now+nh4now;
                end;
            end;
        end;
        
        % Denitrification (no3 to n gas) (see Johnsson, see Heinen)
        if no3now>0&&cactnow>0
            no3conc=(no3now)/(ps*rootdepth); % mass to concentration
            denitN=kd*microbfact(theta,thetaS,thetathresh)*arrhenius(soilTlst,Tb,Q10)*(no3conc/(no3conc+cs))*cactnow;
            if denitN<=no3now
                no3now=no3now-denitN;
                no3lostdenit=denitN;
            else
                no3now=no3now-no3now;
                no3lostdenit=no3now;
            end;
        else
            no3lostdenit=0;
        end;
        
        % Mineralization of stable orgN (orgNstab to nh4)   
        if orgNstabnow>0
            mineralstaborgN=kh*arrhenius(soilTlst,Tb,Q10)*moistfact(es,thetaWP,thetaS,thetaHO,thetaLO,theta)*orgNstabnow;
            if mineralstaborgN<=orgNstabnow
                orgNstabnow=orgNstabnow-mineralstaborgN;
                nh4now=nh4now+mineralstaborgN;
            else
                orgNstabnow=orgNstabnow-orgNstabnow;
                nh4now=nh4now+orgNstabnow;
            end;    
        end;
        % Note: According to Johnsson, the decomposition of orgNact and
        % orgNfrsh pools are controled by cact and cfrsh pools so that
        % minerailzation/immobilization is poportional to the decomposition
        % rate.  SWAT also uses c-n balance to determine this transfer
        % between organic N pools and the nh4 pool

        % Minerailzation/immobilization of fresh orgN (between orgNfrsh and
        % nh4)
        if  cfrshnow>0
            % Calculate cycling between carbon pools
            cfrshdecomp=kf*arrhenius(soilTlst,Tb,Q10)*moistfact(es,thetaWP,thetaS,thetaHO,thetaLO,theta)*cfrshnow;
            cfrshnow=cfrshnow-(1-fe)*cfrshdecomp;     % Subtract from cfrsh
            cfrshnow=cfrshnow-fe*fh*cfrshdecomp;      % Subtract from cfrsh, add to cstab
            cstabnow=cstabnow+fe*fh*cfrshdecomp; 
            cfrshnow=cfrshnow+fe*(1-fh)*cfrshdecomp;  % Cycling of cfrsh/litter formation
        end;
        
        % Minearlization/immobilization of fresh orgN
        if cfrshnow>0
            mineralfrshorgN=((orgNfrshprev/cfrshnow)-cnthrsh)*cfrshdecomp;
            % When mineralfrshorgN is negative then immobilization (add abs
            % value to orgNfrsh and subtract from nh4) when mineralfrshorgN
            % is positive = mobilization (add to nh4 and subtract from
            % orgNfrsh)
            if (nh4now+no3now)>0 
                if mineralfrshorgN<0
                    % If negative then immobilization of nh4 but its
                    % conversion is proportational to the amount of nh4
                    % available
                    if (nh4now>0)&&(no3now>0)
                        immobf=fmax*(nh4now/(nh4now+no3now))*abs(mineralfrshorgN);       
                        if immobf<=nh4now
                            nh4now=nh4now-immobf;
                            orgNfrshnow=orgNfrshnow+immobf;
                        else
                            nh4now=nh4now-nh4now;
                            orgNfrshnow=orgNfrshnow+nh4now;
                        end;
                    else
                    	orgNfrshnow=orgNfrshnow+0;
                        nh4now=nh4now+0;
                    end;                        
                elseif mineralfrshorgN==0
                    % If zero then nothing happens
                    orgNfrshnow=orgNfrshnow+0;
                    nh4now=nh4now+0;
                elseif mineralfrshorgN>0
                    % If positive then mineralization
                    if (nh4now>0)&&(no3now>0)
                        minrlf=fmax*(nh4now/(nh4now+no3now))*abs(mineralfrshorgN);      
                        if minrlf<=orgNfrshnow
                            nh4now=nh4now+minrlf;
                            orgNfrshnow=orgNfrshnow-minrlf;
                        else
                            nh4now=nh4now+orgNfrshnow;
                            orgNfrshnow=orgNfrshnow-orgNfrshnow;
                        end;
                    else
                    	orgNfrshnow=orgNfrshnow+0;
                        nh4now=nh4now+0;
                    end;
                end;
            end;
        end;
        
        % Minerailzation/immobilization of active orgN (between orgNact and
        % nh4)
        if  cactnow>0
            % Calculate cycling between carbon pools
            cactdecomp=kf*arrhenius(soilTlst,Tb,Q10)*moistfact(es,thetaWP,thetaS,thetaHO,thetaLO,theta)*cactnow;
            cactnow=cactnow-(1-fe)*cactdecomp;     % Subtract from cfrsh
            cactnow=cactnow-fe*fh*cactdecomp;      % Subtract from cfrsh, add to cstab
            cstabnow=cstabnow+fe*fh*cactdecomp; 
            cactnow=cactnow+fe*(1-fh)*cactdecomp;  % Cycling of cfrsh/litter formation
        end;
        
        % Minerailzation/immobilization of active orgN
        if cactnow>0
            mineralactorgN=((orgNactprev/cactnow)-cnthrsh)*cactdecomp;
            % When mineralfrshorgN is negative then immobilization (add abs
            % value to orgNfrsh and subtract from nh4) when mineralfrshorgN
            % is positive = mobilization (add to nh4 and subtract from
            % orgNfrsh)
            if (nh4now+no3now)>0 
                if mineralactorgN<0
                    % If negative then immobilization of nh4 but its
                    % conversion is proportational to the amount of nh4
                    % available
                    if (nh4now>0)&&(no3now>0)
                        immoba=fmax*(nh4now/(nh4now+no3now))*abs(mineralactorgN);       
                        if immoba<=nh4now
                            nh4now=nh4now-immoba;
                            orgNactnow=orgNactnow+immoba;
                        else
                            nh4now=nh4now-nh4now;
                            orgNactnow=orgNactnow+nh4now;
                        end;
                    else
                    	orgNactnow=orgNactnow+0;
                        nh4now=nh4now+0;
                    end;                        
                elseif mineralactorgN==0
                    % If zero then nothing happens
                    orgNactnow=orgNactnow+0;
                    nh4now=nh4now+0;
                elseif mineralactorgN>0
                    % If positive then mineralization
                    if (nh4now>0)&&(no3now>0)
                        minrla=fmax*(nh4now/(nh4now+no3now))*abs(mineralactorgN);      
                        if minrla<=orgNactnow
                            nh4now=nh4now+minrla;
                            orgNactnow=orgNactnow-minrla;
                        else
                            nh4now=nh4now+orgNactnow;
                            orgNactnow=orgNactnow-orgNactnow;
                        end;
                    else
                    	orgNactnow=orgNactnow+0;
                        nh4now=nh4now+0;
                    end;
                end;
            end;
        end;

        % Transfer between orgNact and orgNstab pools
        % Calculate the potention N transfer
        if (orgNactnow>0)&&(orgNstabnow>0)
            ntrans=(ftrans*orgNactnow*((1/fact)-1))-orgNstabnow;
            % Define the direction of transfer
            if ntrans>0
                % Goes from active to stable pool
                if ntrans<=orgNactnow
                    orgNstabnow=orgNstabnow+ntrans;
                    orgNactnow=orgNactnow-ntrans;
                else
                    orgNstabnow=orgNstabnow+orgNactnow;
                    orgNactnow=orgNactnow-orgNactnow;
                end;
            elseif ntrans==0
                % No change
                orgNstabnow=orgNstabnow+0;
                orgNactnow=orgNactnow+0;
            elseif ntrans<0
                % Goes from stable to active pool
                if abs(ntrans)<=orgNstabnow
                    orgNstabnow=orgNstabnow-abs(ntrans);
                    orgNactnow=orgNactnow+abs(ntrans);
                else
                    orgNstabnow=orgNstabnow-orgNstabnow;
                    orgNactnow=orgNactnow+orgNstabnow;
                end;
            end; 
        end;
        
        % Decay of organic active N pool
        if orgNactnow>0
            aact=(0.69/thalfNact)*arrhenius(soilTlst,Tb,Q10);
            orgNactnow=orgNactnow*exp(-aact*tstep);
        end;

        % Decay of organic fresh N pool
        if orgNfrshnow>0
            afrsh=(0.69/thalfNfrsh)*arrhenius(soilTlst,Tb,Q10);
            orgNfrshnow=orgNfrshnow*exp(-afrsh*tstep);    
        end;

        % Decay of organic stable N pool
        if orgNstabnow>0
            astab=(0.69/thalfNstab)*arrhenius(soilTlst,Tb,Q10);
            orgNstabnow=orgNstabnow*exp(-astab*tstep);    
        end;
    else
        no3lostdenit=0;
    end;
end;
    
% Phsical processes (leaching and decay)    
for soillyr=1;
    % Leaching of no3 in interflow, lateral flow, and percolation
    if (no3now>0)&&(qlatf+qovldf+qperc)>0     
        no3conc=no3now/(ps*rootdepth*applnarea);
        totalflowout=qlatf+qovldf+qperc;
        % Keep track of no3 lost in overland and lateral flow (w/out
        % sediment)
        no3now=no3now-no3conc*(qlatf/totalflowout)*qlatf;
        no3now=no3now-no3conc*(qovldf/totalflowout)*qovldf;
        no3now=no3now-no3conc*(qperc/totalflowout)*qperc;
        
        % Define losses
        no3lostovlf=no3conc*(qlatf/totalflowout)*qlatf;
        no3lostlatf=no3conc*(qovldf/totalflowout)*qovldf;
        no3lostperc=no3conc*(qperc/totalflowout)*qperc;        
    else
        % Define losses
        no3lostovlf=0;
        no3lostlatf=0;
        no3lostperc=0;          
    end;
    
    % Leaching of organic N pools (bound to sediment in overland flow)
    % Active orgN conc
    if orgNactnow>0
        orgNactconc=orgNactnow/(ps*rootdepth*applnarea);
    else
        orgNactconc=0;
    end;
    % Fresh orgN conc
    if orgNfrshnow>0
        orgNfrshconc=orgNfrshnow/(ps*rootdepth*applnarea);
    else
        orgNfrshconc=0;
    end;
    % Stab orgN conc
    if orgNstabnow>0
        orgNstabconc=orgNstabnow/(ps*rootdepth*applnarea);
    else
        orgNstabconc=0;
    end;   
    % Calculate the amount of orgN lost due to attachment to sediment
    if ((orgNactconc+orgNfrshconc+orgNstabconc)>0)&&(sedfrac>0)   
        sedorgNlost=orgNactconc+orgNfrshconc+orgNstabconc;
        orgNactnow=orgNactnow-((orgNactconc/sedorgNlost)*qovldf*sedfrac);
        orgNfrshnow=orgNfrshnow-((orgNfrshconc/sedorgNlost)*qovldf*sedfrac);
        orgNstabnow=orgNstabnow-((orgNstabconc/sedorgNlost)*qovldf*sedfrac);
        
        % Define Losses
        orgNactlostovld=(orgNactconc/sedorgNlost)*qovldf*sedfrac;
        orgNfrshlostovld=(orgNfrshconc/sedorgNlost)*qovldf*sedfrac;
        orgNstablostovld=(orgNstabconc/sedorgNlost)*qovldf*sedfrac;
    else
        % Define Losses
        orgNactlostovld=0;
        orgNfrshlostovld=0;
        orgNstablostovld=0;        
    end;
end; 
        
for soillyr=1;    
    % Plant N 
    if day<harvestday
        plantNnow=plantNnow+0;
    elseif (day>=harvestday)&&(day<plowday)
        plantNharv=(1-fharv)*plantNnow;
        plantNnow=plantNnow-(1-fharv)*plantNharv;       % Fraction of plantN left after harvest          
    elseif day>=plowday
        plantNnow=0;                                    % PlantN left is zero after plowing
    end; 
end;

nitrogenDailyDATA=[id,ofe,day,yr,no3lostovlf,no3lostlatf,no3lostperc,no3lostdenit,orgNactlostovld,orgNfrshlostovld,orgNstablostovld,nh4now,no3now,plantNnow,orgNactnow,orgNfrshnow,orgNstabnow,cactnow,cfrshnow,cstabnow];
