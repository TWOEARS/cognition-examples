
%--------------------------------------------------------------------------
% Class:                bindingHypotheses
% Version:              1.0
% Last modification:    17.07.16
% Author:               T. Walther
%
% Description:
%   This class encodes hypotheses of the current segregation of audio
%   streams. It contains the number of overheard sources, the azimuths of
%   all sources (in head-centric KS), the corresponding kappa concentration parameters, and a
%   per-source map container of category memberships (discrete). Also, it
%   contains the head orientation at the time the current hypothesis had
%   been generated.
%--------------------------------------------------------------------------

classdef bindingHypotheses < handle
    
    properties (Access = public)
        headPosition;
        headOrientation;
        azimuths; % [-pi,+pi]
        kappas;
        categoryMemberships;
        labels;
    end
    
    methods (Access = public)
        
        % The constructor
        function obj=bindingHypotheses()
            obj.azimuths={};
            obj.kappas={};
            obj.categoryMemberships={};
            obj.labels={};
        end
        
        
    end
end

