

% This KS builds forms the auditory objects, including their positions, and
% position reliabilities in the x/y-plane

classdef AuditoryObjectFormationKS < AbstractKS
    

    properties (SetAccess = private)
        robot;                        % Reference to the robot environment
        categories;                   % all observed categories
        envMaps;                      % the environmental maps structure
        domainX;                      % the X domain of the envMaps
        domainY;                      % the Y domain of the envMaps
        gridX;                        % the grid domain in X
        gridY;                        % the grid domain in Y
        figA;                          % a debug figure
        figB;                          % a debug figure
        
        envMapsGMM;                   % a GMM representing the environmental maps for
                                      % each category
        firstRun;                     % is this the first run of this KS?
        memory;                       % the storage for all label-related lines
        debug;        
    end

    methods
        % the constructor
        function obj = AuditoryObjectFormationKS(robot)
            obj = obj@AbstractKS();
            obj.debug=false;
            % call each frame
            obj.invocationMaxFrequency_Hz = inf;
            % set member variables
            obj.robot = robot; 
            
            obj.memory=containers.Map();
            if obj.debug
                obj.figA=figure ('Name','Environmental maps:');
                %obj.figB=figure ('Name','Img:');
            end
            
        end

        function [b, wait] = canExecute(obj)
            % self-explanatory
                b = true;
                wait = false;            
        end

        
        function execute(obj)
           
            
                 
            if obj.debug
                set(0, 'currentfigure', obj.figA);

                clf;
            end
            
            % read segregation hypothesis from blackboard
            segHyp=...
                    obj.blackboard.getLastData(...
                                'bindingHypotheses').data;
            
            % read auditory hypotheses from blackboard
            auditoryObjectHyps={};
            try
                auditoryObjectHyps=...
                    obj.blackboard.getLastData(...
                                'auditoryObjectHypotheses').data;
            catch
            end
            
            
            
        
            globalLocalizationInstability=0.0;
            for i=1:size(segHyp.azimuths,2)

                
                azimuth=segHyp.azimuths{1,i};
                label=segHyp.labels{1,i};
                
                
                
                % is there already an auditory object hypothesis for this label?
                
                index=-1;
                for l=1:size(auditoryObjectHyps,1)
                    if strcmp(auditoryObjectHyps{l,1}.label,label)
                        index=l;
                    end
                end
                
                % the auditory object hypothesis matching the current label
                aoh=[];
                
                
                if index>-1
                    % ok, label is already stored
                    aoh=auditoryObjectHyps{index,1};

                else
                    % label has not been observed before, store it
                    auditoryObjectHyps{end+1,1}=...
                        auditoryObjectHypothesis(label);
                    
                    
                    aoh=auditoryObjectHyps{end,1};
                    index=size(auditoryObjectHyps,1);
                    
                    % for a new stimulus, set the position uncertainty to
                    % values that are large enough to not accept the
                    % corresponding source as reliably localized
                    aoh.smoothedLocationInstability=inf;
                    aoh.R=zeros(2,2);
                    aoh.q=zeros(2,1);
                    aoh.previousLocationEstimate=[nan;nan];
                    aoh.locationInstabilityTimeCourse=[];
                    aoh.currentLocationEstimate=[nan;nan];
                    
                end
                
                
                
                if obj.debug
                    subplot(3,2,i);
                    title(label);
                    hold on;
                    %cla;
                    xlim([-4 4]);
                    ylim([2 12]);
                end
                
                
                
                headX=segHyp.headPosition(1,1);
                headY=segHyp.headPosition(1,2);
                headOrientation=segHyp.headOrientation;
                
                % find the connection line from head to source
                ofs=[headX;headY];
                dir=[cos((azimuth+headOrientation)/180*pi);sin((azimuth+headOrientation)/180*pi)];
                
                R=aoh.R;
                q=aoh.q;
                previousLocationEstimate=aoh.previousLocationEstimate;
                locationInstabilityTimeCourse=aoh.locationInstabilityTimeCourse;
                % find intersection point
                I=[1 0; 0 1];
                R=R+(I-dir*dir');        
                q=q+(I-dir*dir')*ofs;      
                locationEstimate=pinv(R)*q;

                
                locationInstability=norm(locationEstimate-previousLocationEstimate);
                if isnan(locationInstability)
                    % sufficient to keep the estimation process running
                    locationInstability=1.0;
                end
                locationInstabilityTimeCourse(1,end+1)=locationInstability;
                lookBack=min(10,size(locationInstabilityTimeCourse,2));

                smoothedLocationInstability=sum(locationInstabilityTimeCourse(end-lookBack+1:end))/...
                                            lookBack;
                aoh.R=R;
                aoh.q=q;
                aoh.previousLocationEstimate=aoh.currentLocationEstimate;
                aoh.locationInstabilityTimeCourse=locationInstabilityTimeCourse;
                aoh.smoothedLocationInstability=smoothedLocationInstability;
                aoh.currentLocationEstimate=locationEstimate;
                
                obj.robot.visualizerInterface.addSourceHypothesis(...
                                                    label,...
                                                    aoh.currentLocationEstimate...
                                                );
                
                
                auditoryObjectHyps{index,1}=aoh;
                
                if obj.debug
                    plot(intersectionPoint(1,1),intersectionPoint(2,1),'g*');
                end
                
                
                
                
                if obj.debug
                    plot(intersectionPoint(1,1),intersectionPoint(2,1),'g*');
                    
                
                    for s=1:size(obj.robot.audioVisualSources,1)
                         pos=obj.robot.audioVisualSources{s,1}.position;
                         plot(pos(1,1),pos(1,2),'bo');
                    end
                end
                
                if obj.debug
                    hold off;
                end
             
                
                
            
            
            end
            
            for i=1:size(auditoryObjectHyps,1)
                globalLocalizationInstability=globalLocalizationInstability+...
                    auditoryObjectHyps{i,1}.smoothedLocationInstability;
            end
            
            globalLocalizationInstability=globalLocalizationInstability/size(auditoryObjectHyps,1);
            
            
            % not hypotheses so far, just allow the robot to do
            % surveillance
            if isnan(globalLocalizationInstability)
                globalLocalizationInstability=1.0;
            end
            
            
            if obj.debug
                drawnow;
            end

            % push auditory object hypotheses onto blackboard, always at time
            % zero, in order to save memory
            obj.blackboard.addData( ...
                'auditoryObjectHypotheses',auditoryObjectHyps,false,0);
            
            % push global localization change onto blackboard, always at time
            % zero, in order to save memory
            obj.blackboard.addData( ...
                'globalLocalizationInstability',globalLocalizationInstability,false,0);

            notify(obj, 'KsFiredEvent');            
            
        end
    
    end  
end


