% Moisture Response Function

% Author: Sheila Saia
% Email: sms493@cornell.edu
% Last Updated: Mar 1, 2013

% % This function caluculates moisture factor (sm) or the response for
% various N cycle processes.

% es is a parameter that defines the minimum water content for a process to
% occure
% thetaWP is the soil moisture content at the wilting point
% thetaS is the soil moisture content at saturation
% thetaHO is the high water content parameter that defines where the soil
% moisture factor (em) is optimal
% thetaLO is the low water content parameter that defines where the soil
% moisture factor (em) is optimal
% theta is the soil water content on any given day

% References:  Johnsson et al 1987

% This function 
function em=moistfact(es,thetaWP,thetaS,thetaHO,thetaLO,theta)
if (thetaS>=theta)&&(theta>thetaHO)
    em=es+(1-es)*((thetaS-theta)/(thetaS-thetaHO));
elseif (thetaHO>=theta)&&(theta>=thetaLO)
    em=1;
elseif (thetaLO>theta)&&(theta>=thetaWP)
    em=(theta-thetaWP)/(thetaLO-thetaWP);  
elseif theta<thetaWP
    em=0;   %is this right?
end;