classdef BaselineVisualizer < handle
    
    % This class allows a baseline 2D visualization of the processed
    % scenario. It is sufficient to test most of the KSs that have been
    % developed for BEFT
    
    properties (Access = public)
        canvas;     % the canvas used to draw the 2D depiction of
                    % the scenario
        parent;     % the parenting virtual enviŕonment
        dT;         % the timestep used for the emulation
        t;          % the system time
        headPose;   % the head's pose
        robotPose;  % the robot's pose
        currentTask;% the task currently executed
        rotationGoal; % the target angle for rotation
        translationGoal; % the target distance for translation
        velocity; % the velocity for the current motion
        taskPending; % is a task currently pending?
        phi;        % the computed rotation angle
        hypList; % list of source hypotheses
        currentSuperTask; % the super task currently performed
    end
    
    methods (Access = public)
        
        % The constructor
        function obj = BaselineVisualizer(parent)
            obj.parent=parent;
            obj.dT=parent.BlockSize/parent.SampleRate;
            obj.canvas=figure('Name','Scenario');
            obj.currentTask='';
            obj.rotationGoal=[];
            obj.translationGoal=[];
            obj.velocity=0.0;
            obj.taskPending=false;
            obj.hypList=containers.Map();
            obj.currentSuperTask='';
        end
        
        function issueTask(obj,taskStr)
            strSplit=strsplit(taskStr,',');  
            task=strSplit{1};
            value=str2double(strSplit{2});
            vel=str2double(strSplit{3});
            obj.currentTask=task;
            
            pose=obj.headPose;
            
            x=pose(1,1);
            y=pose(1,2);
            yaw=pose(1,3);
            
            obj.taskPending=true;
            obj.velocity=vel;
            
            if strcmp(task,'translateRelative')
                
                heading=[cos(yaw/180.0*pi);sin(yaw/180.0*pi)];
                heading=value*heading;
                newPos=[x;y]+heading;
                obj.translationGoal=[newPos(1,1);newPos(2,1)];
            end
            
            if strcmp(task,'rotateRelative')
                obj.rotationGoal=value+yaw;
                obj.rotationGoal=mod(obj.rotationGoal,360);
                
                h=[cos(yaw/180*pi);sin(yaw/180*pi);0];
                n=[cos(obj.rotationGoal/180*pi);sin(obj.rotationGoal/180*pi);0];
                cp=cross(h,n);
                A=dot(cp,[0;0;1]);
                B=dot(h,n);
                obj.phi=180/pi*atan2(A,B);
                
            end
            
            
            
        end
        
        function addSourceHypothesis(obj,label,hyp)
            obj.hypList(label)=hyp;
        end
        
        
        function ret=isTaskPending(obj)
            ret=obj.taskPending;
        end
        
        % propel and display the simulation's status
        function stepSimulation(obj)
            
            
            obj.t=obj.t+obj.dT;
            
            
            pose=obj.headPose;
            
            x=pose(1,1);
            y=pose(1,2);
            yaw=pose(1,3);
            
            if strcmp(obj.currentTask,'translateRelative')
                
                remainingDistance=norm([x;y]-obj.translationGoal);
                dS=obj.velocity*obj.dT;
                
                if (remainingDistance<=dS)
                    x=obj.translationGoal(1,1);
                    y=obj.translationGoal(2,1);
                    obj.taskPending=false;
                else
                    heading=[cos(yaw/180.0*pi);sin(yaw/180.0*pi)];
                    heading=dS*heading;
                    newPos=[x;y]+heading;
                    x=newPos(1,1);
                    y=newPos(2,1);
                end
                
                pose=[x,y,yaw];
                obj.headPose=pose;
                obj.robotPose=obj.headPose;
                
            end
            
            
            
            if strcmp(obj.currentTask,'rotateRelative')
                
                h=[cos(yaw/180*pi);sin(yaw/180*pi);0];
                n=[cos(obj.rotationGoal/180*pi);sin(obj.rotationGoal/180*pi);0];
                sp=acos(dot(h,n))*180/pi;
                
                dPhi=obj.velocity*obj.dT;
                
                
                if (abs(sp)<=dPhi)
                    yaw=obj.rotationGoal;
                    obj.taskPending=false;
                else
                    if obj.phi<0.0
                        yaw=yaw-dPhi;
                    else
                        yaw=yaw+dPhi;
                    end
                end
                
                pose=[x,y,yaw];
                obj.headPose=pose;
                obj.robotPose=obj.headPose;
                
            end
            
            
            
            % plot the scenario
            set(0,'currentfigure',obj.canvas);
            clf;
            %cla;
            
            axisMain=axes('Position',[0 0 1 1],'Visible','on');
            axisPlot=axes('Position',[0.3 0.1 0.6 0.8]);
            
           
            xlim([-5,5]);
            ylim([0,12]);
            hold on;


            
            
            
           
            
            % plot the ground-truth source positions 
            for i=1:size(obj.parent.audioVisualSources,1)
                source=obj.parent.audioVisualSources{i,1};
                    
                plot(axisPlot,source.position(1,1),source.position(1,2),'xr');

                if source.emitting
                    plot(axisPlot,source.position(1,1),source.position(1,2),'ob');
                end

            end
            
            
            % plot the source position hypotheses
            k=keys(obj.hypList);
            for i=1:size(k,2)
                label=k{1,i};
                try
                    source=obj.parent.getSourceByName(label);
                    
                    pos=obj.hypList(k{1,i});
                    plot(axisPlot,pos(1,1),pos(2,1),'*g');
                catch
                end
            end
            
            % plot robot
            x=pose(1,1);
            y=pose(1,2);
            yaw=pose(1,3);
            h=0.5;
            
            plot(axisPlot,pose(1,1),pose(1,2),'*');
            
            plot(axisPlot,  [x,x+h*cos((yaw/180)*pi)],...
                            [y,y+h*sin((yaw/180)*pi)],...
                            'b');
            
            hold off;
            
            axes(axisMain);
            set(gca,'visible','off');
            strTime=sprintf('t: %.2f [s]',obj.parent.simulationTime);
            text(0.1,0.95,strTime);
              
            strSuperTask=sprintf('Current task: %s',obj.currentSuperTask);
            text(0.3,0.95,strSuperTask);
            
            drawnow;
           
            
            
            
           
        end
        
        
        % sets the current super task
        function setCurrentSuperTask(obj,sTask)
            obj.currentSuperTask=sTask;
        end
        
        
        % retrieves time, robot pose, and head pose as a formatted string
        function data=getEnvironmentalData(obj)
            data=sprintf('%f,%f,%f,%f,%f,%f,%f',...
                obj.t,...
                obj.robotPose(1,1),...
                obj.robotPose(1,2),...
                obj.robotPose(1,3),...
                obj.headPose(1,1),...
                obj.headPose(1,2),...
                obj.headPose(1,3));
                
        end
        
        function resetTime(obj)
            obj.t=0.0;
        end
        
    end
    
end

