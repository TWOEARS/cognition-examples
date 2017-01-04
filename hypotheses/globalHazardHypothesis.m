
%--------------------------------------------------------------------------
% Class:                globalHazardHypothesis
% Version:              1.0
% Last modification:    07.01.16
% Author:               T. Walther
%
% Description:
%   This class encodes an estimate of the current global hazard for a given
%   scenario.
%--------------------------------------------------------------------------

classdef globalHazardHypothesis < handle
    
    properties (Access = public)
        globalHazardScore;
        globalHazardArray;
        globalHazardMean;
    end
    
    methods (Access = public)
        
        % The constructor
        function obj=globalHazardHypothesis()
           obj.globalHazardScore=0.0;
           obj.globalHazardArray=[];
           obj.globalHazardMean=0.0;
        end
        
        
    end
end

