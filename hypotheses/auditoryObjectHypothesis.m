
%--------------------------------------------------------------------------
% Class:                auditoryObjectHypothesis
% Version:              1.0
% Last modification:    07.01.16
% Author:               T. Walther
%
% Description:
%   This class encodes an estimate of all overheard sources. It allows
%   Kalman filtering of the sources' absolute azimuths and positions, and
%   stores all viable observations that are made during robot motion.
%--------------------------------------------------------------------------

classdef auditoryObjectHypothesis < handle
    
    properties (Access = public)
        label;                   % the estimated label for this hypothesis
        currentLocationEstimate; % the estimate of the source's position,
                                 % according to the available data
     
       
        
        categoryReliabilities;     % the categories as estimated for this source
        
        
        roleReliabilities;          % the roles as estimated for this source
        
        
        genderReliabilities;        % the genders as estimated for this source
        
        scalarParametersReliabilities;       % the emotions as estimated for this source
        
        isReliable;          % is this hypothesis valid?
        smoothedLocationInstability;          % how agile is this source w.r.t. triangulation?
        smoothedHazardScore;            % is this source in hazard?
        hazardArray;            % to smooth the hazard observations
        
        rescueOrderNumber;      % the position of this object in the rescue list
        % helper variables for source localization 
        R;
        q;
        previousLocationEstimate;
        locationInstabilityTimeCourse;
        % end of helper variables 
    end
    
    methods (Access = public)
        
        % The constructor
        function obj=auditoryObjectHypothesis(label)
            
          
            
            
            obj.categoryReliabilities=zeros(1,100);
            obj.roleReliabilities=zeros(1,100);
            obj.genderReliabilities=zeros(1,100);
            obj.scalarParametersReliabilities=zeros(1,100);
            obj.isReliable=true;
            obj.label=label;
            obj.hazardArray=zeros(1,30);
            obj.rescueOrderNumber=-1;
            
        end
        
        
    end
end

