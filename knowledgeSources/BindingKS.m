

% This KS provides EMULATED data as expected from the segregation KS
% This means: a circular distribution is provided for each emulated sound
% source, using a mean mu and a concentration kappa (von Mises distribution)
% Also, a probability distribution (discrete) over all available categories
% is provided.

classdef BindingKS < AbstractKS
    

    properties (SetAccess = private)
        robot;                        % Reference to the robot environment
        fig;                          % debug figure
        debug;                        % use debug display?
        categories;                   % all observed categories
    end

    methods
        % the constructor
        function obj = BindingKS(robot)
            obj = obj@AbstractKS();
            % call each frame
            obj.invocationMaxFrequency_Hz = inf;
            % set member variables
            obj.robot = robot; 
            obj.debug=false;
            
            if obj.debug
                obj.fig=figure ('Name','Source overview:');
            end
            
            % get all available categories from the installed soound
            % sources
            obj.categories={};
            sources=obj.robot.audioVisualSources;
            for i=1:size(sources,1)
                category=sources{i,1}.category;
                obj.categories{1,end+1}=category;
            end
            obj.categories=unique(obj.categories);
        end

        function [b, wait] = canExecute(obj)
            % self-explanatory
            b = true;
            wait = false;            
        end

        
        function execute(obj)
            
            % debugging required?
            
            % get current robot pose in world coordinates
            
            % get current head pose in world coordinates
            headPose=obj.robot.referencePosition;
            hX=headPose(1,1);
            hY=headPose(1,2);
            hYaw=headPose(1,3);
            
            
            if obj.debug
                set(0, 'currentfigure', obj.fig);

                clf;
                cla;
                xlim([-5 5]);
                ylim([0 11]);
                hold on;
                plot(hX,hY,'or');
            end
            
            % instantiate a segregation hypothesis
            segHyp=bindingHypotheses();
            segHyp.headPosition=[hX,hY];
            segHyp.headOrientation=hYaw;
            
             
            % run over all available sound sources
            sources=obj.robot.audioVisualSources;
            for i=1:size(sources,1)
                % only for active sources
                if sources{i,1}.emitting
                    position=sources{i,1}.position;
                    name=sources{i,1}.name;
                    sX=position(1,1);
                    sY=position(1,2);
                    if obj.debug
                        plot(sX,sY,'ob');
                    end
                    % find the acoustic source's azimuth in head-centric
                    % coordinates [0...360[
                   
                    dirSource=[sX-hX;sY-hY;0]/norm([sX-hX;sY-hY;0]);
                    dirHeading=[cos(hYaw/180*pi);sin(hYaw/180*pi);0];
                    
                    azimuthH=atan2(dot(cross(dirHeading,dirSource),[0;0;1]),dot(dirHeading,dirSource))/pi*180;
                    azimuthH=mod(azimuthH,360);
                    

                    if obj.debug
                        % for debugging, display head-relative azimuth
                        azimuthD=azimuthH+hYaw;
                        genX=10.0*cos(azimuthD/180*pi);
                        genY=10.0*sin(azimuthD/180*pi);
                        plot([hX,hX+genX],[hY,hY+genY],'-g');
                    end                


                    
                    % formulate an entry in the segregation hypothesis

                    % only if there is at least one active source!
                    segHyp.azimuths{1,end+1}=azimuthH+normrnd(0.0,1.0);
                    segHyp.labels{1,end+1}=name;
                end
                
            end
            
            % push segregation hypothesis onto blackboard, always at time
            % zero, in order to save memory
            obj.blackboard.addData( ...
                'bindingHypotheses',segHyp,false,0);
            
            if obj.debug
                hold off;
                drawnow;
            end
            notify(obj, 'KsFiredEvent');            
        end
    end
end


