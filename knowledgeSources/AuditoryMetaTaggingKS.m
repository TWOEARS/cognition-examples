

% 'AuditoryMetaTaggingKS' class
% This knowledge source emulates results of an auditory-based category
% classifier.

% Author: Thomas Walther
% Date: 21.10.15
% Rev. 1.0

classdef AuditoryMetaTaggingKS < AbstractKS
    

    properties (SetAccess = public)
        robot;                        % Reference to the robot environment
                                      % of auditory objects
        
    end

    methods
        % the constructor
        function obj = AuditoryMetaTaggingKS(robot)
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
                for i=1:size(auditoryObjectHyps,1)

                   
                        % find the matching av source
                        matchingAVSource=obj.robot.getSourceByName(auditoryObjectHyps{i}.label);
                        % receive data ONLY IF this source is acoustically
                        % active!
                        if matchingAVSource.emitting
                            categoryReliabilities=matchingAVSource.getCategoryEstimates();
                            roleReliabilities=matchingAVSource.getRoleEstimates();
                            genderReliabilities=matchingAVSource.getGenderEstimates();
                            scalarParameterReliabilities=matchingAVSource.getEmotionEstimates();

                                 auditoryObjectHyps{i,1}.categoryReliabilities=...
                                    categoryReliabilities;

                                  auditoryObjectHyps{i,1}.roleReliabilities=...
                                    roleReliabilities;

                                  auditoryObjectHyps{i,1}.genderReliabilities=...
                                    genderReliabilities;

                                  auditoryObjectHyps{i,1}.scalarParametersReliabilities=...
                                    scalarParameterReliabilities;
                           
                        end
                           
                   

                end
                
                % write back the modified auditory object hypotheses to the
                % blackboard, time=0, in order to save memory
                obj.blackboard.addData( ...
                'auditoryObjectHypotheses',auditoryObjectHyps,...
                            false, 0);
                
            
            notify(obj, 'KsFiredEvent');   
          
        end
    end
end
