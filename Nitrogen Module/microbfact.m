% Microbial Response Function

% Author: Sheila Saia
% Email: sms493@cornell.edu
% Last Updated: Mar 1, 2013

% This function calculates the magnitude of anaerobic microbial processes
% that aid in denitrification, this relys on theta which changes with
% depth.

% theta is the soil water content on any given day
% thetaS is the soil moisture content at saturation
% thetathresh is the threshold theta needed for microbial activity to occur

function em=microbfact(theta,thetaS,thetathresh)
em=((theta-thetathresh)/(thetaS-thetathresh))^2;
