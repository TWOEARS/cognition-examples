

% 'AuditoryMetaTaggingKS' class
% This knowledge source emulates results of an auditory-based category
% classifier.

% Author: Thomas Walther
% Date: 21.10.15
% Rev. 1.0

classdef HazardAssessmentKS < AbstractKS
    

    properties (SetAccess = public)
        robot;                        % Reference to the robot environment
                                      % of auditory objects
        
    end

    methods
        % the constructor
        function obj = HazardAssessmentKS(robot)
            obj = obj@AbstractKS();
            % call each frame
            obj.invocationMaxFrequency_Hz = inf;
            % set member variables
            obj.robot = robot; 
        
        end

        function [b, wait] = canExecute(obj)
            % self-explanatory
            b = true;
            wait = false;            
        end

        
        function execute(obj)
            
            % get the actual auditory objects
            auditoryObjectHyps={};
            try
                auditoryObjectHyps=...
                    obj.blackboard.getLastData(...
                                'auditoryObjectHypotheses').data;
              
                
            catch
            end
            
            
            % get the actual hazard estimate
            globalHazardHyp=globalHazardHypothesis();
            try
                globalHazardHyp=...
                    obj.blackboard.getLastData(...
                                'globalHazardHypothesis').data;
              
                
            catch
            end
            
            
            
                % reset the global hazard score
                globalHazardHyp.globalHazardScore=0.0;
                
                % count only entities which CAN be in hazard!
                entitiesInHazard=0;
                
                for i=1:size(auditoryObjectHyps,1)

                  
                    stress=auditoryObjectHyps{i,1}.scalarParametersReliabilities(1,1);
                    if stress<0
                        % this entity cant be stressed, set stress to 0
                        stress=0;
                    end
                    loudness=auditoryObjectHyps{i,1}.scalarParametersReliabilities(1,2);
                    age=auditoryObjectHyps{i,1}.scalarParametersReliabilities(1,3);
                    
                    categoryHuman=auditoryObjectHyps{i,1}.categoryReliabilities(1,1);
                    categoryAnimal=auditoryObjectHyps{i,1}.categoryReliabilities(1,2);
                    categoryThreat=auditoryObjectHyps{i,1}.categoryReliabilities(1,3);
                    categoryAlert=auditoryObjectHyps{i,1}.categoryReliabilities(1,4);
                    
                    [~,index]=max(auditoryObjectHyps{i,1}.categoryReliabilities);
                    mostLikelyCategory=obj.robot.availableCategories{1,index};
                    
                    [~,index]=max(auditoryObjectHyps{i,1}.roleReliabilities);
                    mostLikelyRole=obj.robot.availableRoles{1,index};
                    
                    roleVictim=auditoryObjectHyps{i,1}.roleReliabilities(1,3);
                    roleRescuer=auditoryObjectHyps{i,1}.roleReliabilities(1,2);
                    
                    genderMale=auditoryObjectHyps{i,1}.genderReliabilities(1,1);
                    genderFemale=auditoryObjectHyps{i,1}.genderReliabilities(1,2);
                    
                    distanceToRobot=norm(auditoryObjectHyps{i,1}.currentLocationEstimate(1:2,1)-...
                        obj.robot.referencePosition(1,1:2)');       
                    
                    rescueScore=0.0;
                    for j=1:size(auditoryObjectHyps,1)
                        partialRescueScore=auditoryObjectHyps{j,1}.roleReliabilities(1,2);
                    
                        distance=norm(auditoryObjectHyps{i,1}.currentLocationEstimate(1:2,1)-...
                        auditoryObjectHyps{j,1}.currentLocationEstimate(1:2,1));  
                        % only if there is at least a rough estimate for
                        % the positions of the estimates
                        if (~isnan(distance))
                            % degrade rescue score with increasing distance
                            partialRescueScore=partialRescueScore*exp(-distance.^2/2^2);

                            rescueScore=max(rescueScore,partialRescueScore);
                        end
                        
                    end
                    
                    
                    
                    threatScore=0.0;
                    for j=1:size(auditoryObjectHyps,1)
                        partialThreatScore=auditoryObjectHyps{j,1}.categoryReliabilities(1,3);
                    
                        distance=norm(auditoryObjectHyps{i,1}.currentLocationEstimate(1:2,1)-...
                        auditoryObjectHyps{j,1}.currentLocationEstimate(1:2,1));  
                        
                        % only if there is at least a rough estimate for
                        % the positions of the estimates
                        if (~isnan(distance))
                            % degrade rescue score with increasing distance
                            partialThreatScore=partialThreatScore*exp(-distance.^2/2^2);

                            threatScore=max(threatScore,partialThreatScore);
                        end
                        
                    end
                    
                   
                    % get the visual integrity of the source corresponding
                    % to the auditory object, will always be 1 is no vision is
                    % applied
                    
                    source=obj.robot.getSourceByName(auditoryObjectHyps{i,1}.label);
                    visualIntegrity=source.visualIntegrity;
                    
                    
                    % assemble the overall hazard score
                    hazardScore=        stress+...
                                        loudness+...
                                        roleVictim-...
                                        rescueScore+...
                                        threatScore;                                        
                                        
                                       
                                    
                            
                    % a threat can not be endangered!
                    if strcmp(mostLikelyCategory,'threat')
                        hazardScore=0.0;
                    end  
                    
                    % an alert can not be endangered!
                    if strcmp(mostLikelyCategory,'alert')
                        hazardScore=0.0;
                    end  
                    
                    % an animal is rescued late in the chain
                    if strcmp(mostLikelyCategory,'animal')
                        hazardScore=hazardScore*0.25;
                    end  
                    
                    if visualIntegrity<1.0
                        hazardScore=hazardScore*5.0;
                    end
                    
                    
%                     % a rescuer is rescued late in the chain
%                     if strcmp(mostLikelyRole,'rescuer')
%                         hazardScore=hazardScore*0.5;
%                     end  
                                    
                    % no reliable measurements are available, thus set
                    % observation to zero
                    if isnan(hazardScore)
                        hazardScore=0.0;
                    end
                    
                    
                    % prepare smmoothing of the per-entity hazard score
                    hazardArray=auditoryObjectHyps{i,1}.hazardArray;
                    
                    % actually to the smoothing of the per-source hazard
                    % score
                    
                    hazardArray(1,end+1)=hazardScore;
                    lookBack=min(30,size(hazardArray,2));

                    auditoryObjectHyps{i,1}.smoothedHazardScore=sum(hazardArray(end-lookBack+1:end))/...
                                            lookBack;
                     % the relevant objects counter has to be increased ONLY
                    % for objects which can be in hazard!
                    if auditoryObjectHyps{i,1}.smoothedHazardScore>0.0
                        entitiesInHazard=entitiesInHazard+1;
                    end
                    
                    
                    % add up per-entity hazard score to the global hazard
                    % score
                    globalHazardHyp.globalHazardScore=globalHazardHyp.globalHazardScore+auditoryObjectHyps{i,1}.smoothedHazardScore;
                            
                    
                    
                    % re-transfer the per-entity variables
                    auditoryObjectHyps{i,1}.hazardArray=hazardArray;
                    %auditoryObjectHyps{i,1}.hazardArrayIndex=hazardArrayIndex;
                    
                    
                end
                
                % average the global hazard score w.r.t the number of
                % entities in hazard
                if entitiesInHazard>0
                    globalHazardHyp.globalHazardScore=globalHazardHyp.globalHazardScore/entitiesInHazard;
                    % transfer this averaged score to the display window
                    
                    % store the current global hazard score for mean
                    % retrieval
                    globalHazardHyp.globalHazardArray=[globalHazardHyp.globalHazardArray,globalHazardHyp.globalHazardScore];
                    % find the global hazard mean
                    globalHazardHyp.globalHazardMean=mean(globalHazardHyp.globalHazardArray);
                    
                    
                end

                
            % push global hazard hypothesis onto blackboard, always at time
            % zero, in order to save memory
            obj.blackboard.addData( ...
                'globalHazardHypothesis',globalHazardHyp,false,0);
            
            % push auditory object hypotheses onto blackboard, always at time
            % zero, in order to save memory
            obj.blackboard.addData( ...
                'auditoryObjectHypotheses',auditoryObjectHyps,false,0);

            notify(obj, 'KsFiredEvent');   
          
        end
    end
end
