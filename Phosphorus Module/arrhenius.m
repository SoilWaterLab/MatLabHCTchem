% Temperature Response Function (Arrhenius equation)

% Author: Sheila Saia
% Email: sms493@cornell.edu
% Last Updated: Mar 1, 2013

% This function caluculates the Arrhenuis equation for reaction rate
% dependence on temperature given the current temperature of the soil and
% two other parameters (Tb and Q10).

% T is the current soil temperature at a given depth
% Tb is the base temperature where et = 1
% Q10 gives the percent change with a 10 degree (C) change in temperature

% References:  Johnsson et al 1987, Easton et al 2007

function et=arrhenius(T,Tb,Q10)
et=Q10^((T-Tb)/10);