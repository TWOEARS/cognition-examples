




classdef VisualCuePlanningKS < AbstractKS
    

    properties (SetAccess = public)
        robot;                        % Reference to the robot environment
        taskStack;                    % stack for all provided tasks and subtasks
        taskIsPending;                % is a task pending?
        currentTask;                  % the task the robot currently performs
        wayPoints;                    % the way points of the planned robot path  
        rescueSchedule;               % the schedule for rescue of all threatened entities
        waitInitiated;                 % for spending some time in waiting mode
        waitCounter;                  % similar to the above: for spending some time in waiting mode
    end

    methods
        % the constructor
        function obj = VisualCuePlanningKS(robot)
            obj = obj@AbstractKS();
            % call each frame
            obj.invocationMaxFrequency_Hz = inf;
            % set member variables
            obj.robot = robot; 
            % prime the task stack with the 'exploration' task
            obj.taskStack=java.util.Stack();
            obj.rescueSchedule=java.util.PriorityQueue();
                        
            obj.taskStack.push('standardExploration');
            obj.wayPoints=containers.Map();
            obj.wayPoints('surveillancePosition1')=[ 2.37, 9.96,-106.0];
            obj.wayPoints('surveillancePosition2')=[ 0.88, 4.70,-166.0];
            obj.wayPoints('surveillancePosition3')=[-1.17, 4.57,-157.0];
            obj.wayPoints('surveillancePosition4')=[-0.14, 6.91, 139.0];
            
            obj.wayPoints('idlePosition')=[1.75, 3.65, 90.0];
            obj.wayPoints('alertTriggerPosition')=[2.57, 5.80, 90.0];
            obj.taskIsPending=false;
            obj.waitInitiated=false;
            obj.waitCounter=0;
            
        end

        function [b, wait] = canExecute(obj)
            % self-explanatory
            b = true;
            wait = false;            
        end

        
         
        function execute(obj)
            
            % get auditory object hypotheses from blackboard
            auditoryObjectHyps={};
            try
                auditoryObjectHyps=...
                    obj.blackboard.getLastData(...
                                'auditoryObjectHypotheses').data;
            catch
            end
            
            
            % get the actual hazard estimate
            globalHazardHyp={};
            try
                globalHazardHyp=...
                    obj.blackboard.getLastData(...
                                'globalHazardHypothesis').data;
              
                
            catch
            end
            
            
            % get the actual super task
            currentSuperTask='';
            try
                currentSuperTask=...
                    obj.blackboard.getLastData(...
                                'currentSuperTask').data;
              
                
            catch
            end
            
            
            % get the actual sub task
            currentSubTask='';
            try
                currentSubTask=...
                    obj.blackboard.getLastData(...
                                'currentSubTask').data;
              
                
            catch
            end
            
            
            % get global localization change
            globalLocalizationInstability=inf;
            try
                globalLocalizationInstability=...
                    obj.blackboard.getLastData(...
                                'globalLocalizationInstability').data;


            catch
            end
            
            
            
            
            % planning part
                    
            if strcmp(currentSuperTask,...
                            'standardExploration') && ...
                    globalLocalizationInstability<1e-3

                % the robot has allocated all acoustically
                % observable sources with sufficient precision.
                % This allows is to go to its idle position and set
                % idle mode

                % all previous tasks are no longer valid
                obj.taskStack.clear();
                %obj.robot.robotInterface.clearPendingTasks();
                currentSuperTask='';
                currentSubTask='';

                obj.robot.timeForInitial2DSceneEstimate=...
                    obj.robot.simulationTime;
                
                obj.taskStack.push('visuallyAugmentHazardScores');
                


            end
            
            
            
          
            
            
            
 
            
            
            if strcmp(currentSuperTask,...
                            'rescuePrioritizedEntity') && obj.taskStack.empty()
                   
                % the current target source has been rescued, re-assess the
                % situation and rescue the next prioritized source

                % all previous tasks are no longer valid
                obj.taskStack.clear();
                %obj.robot.robotInterface.clearPendingTasks();
                currentSuperTask='';
                currentSubTask='';

                % the successfully rescued source is evacuated (i.e.,
                % visually and acoustically removed from the scene)
                index=-1;
                label='';
                for i=1:size(auditoryObjectHyps,1)
                   hypothesis=auditoryObjectHyps{i,1};
                   
                   if hypothesis.rescueOrderNumber==1
                      % this is the currently prioritized source
                      % get the environmental proxy for this source
                      source=obj.robot.getSourceByName(hypothesis.label);
                      index=i;
                      label=hypothesis.label;
                      % block emulated acoustic emissions
                      source.block=true;
                      % remove from visual display
                      
                      str=sprintf('%s_emissionIndicator',source.name);
                      output=sprintf('setObjectDisplayStatus,%s,%s',str,'silent');
                      fwrite(obj.robot.controlBlender,output);
                      fscanf(obj.robot.controlBlender,'%s');
                      
                      
                      output=sprintf('setObjectDisplayStatus,%s,%s',source.name,'rescued');
                      fwrite(obj.robot.controlBlender,output);
                      fscanf(obj.robot.controlBlender,'%s');
                      
                      
                   end
                end
                % also. the corresponding source has to be deleted from the
                % array of audio visual source proxies
                auditoryObjectHyps(index)=[];
                
                index=-1;
                for i=1:size(obj.robot.audioVisualSources,1)
                    source=obj.robot.audioVisualSources{i,1};
                    
                    if strcmp(source.name,label)
                        index=i;
                    end
                end
                
                
                obj.robot.audioVisualSources(index)=[];
                
                % compute the next rescue plan
                obj.taskStack.push('setupRescuePlan');
                
            end
            
            
            
            if ~ obj.taskIsPending
                % get top task as current task
                
                if (~obj.taskStack.empty())
                    obj.currentTask=obj.taskStack.pop();
                    fprintf('TASK: %s\n',obj.currentTask);
                    
                    % analyze task
                    splitString = strsplit(obj.currentTask,':');
                    command=splitString{1};
                    currentSubTask=command;
                    try
                        param1=splitString{2};
                    catch
                        param1=[];
                    end
                    
                    try
                        param2=splitString{3};
                        param3=splitString{4};
                    catch
                    end
                    
                    
                    
                    % action part
                    
                    if strcmp(command,'standardExploration')

                        currentSuperTask=command;
                        if obj.robot.withTaskDisplay
                            % print to external logging window
                            str=sprintf('addTask,0,%s',obj.currentTask);
                            fwrite(obj.robot.taskDisplay,str);
                            fscanf(obj.robot.taskDisplay,'%s');
                        end
                        
                        
                        % note: tasks have to be inserted in inverse order!!!
                        obj.taskStack.push('navigate:surveillancePosition1');
                        obj.taskStack.push('navigate:surveillancePosition4');
                        obj.taskStack.push('navigate:surveillancePosition3');
                        obj.taskStack.push('navigate:surveillancePosition2');
                        
                    end
                    
                    
                    
                    
                    
                    
                    if strcmp(command,'visuallyAugmentHazardScores')
                        
                        currentSuperTask=command;
                        % note: tasks have to be inserted in inverse order!!!

                        if obj.robot.withTaskDisplay
                            % print to external logging window
                            str=sprintf('addTask,0,%s',obj.currentTask);
                            fwrite(obj.robot.taskDisplay,str);
                            fscanf(obj.robot.taskDisplay,'%s');
                        end

                        
                        
                        % compute the next rescue plan, keep in mind the
                        % task stack logic, this command will be run AFTER
                        % the below ones!
                        obj.taskStack.push('setupRescuePlan');
                
                        
                        % calculate the positions of each perceived victim,
                        % and turn the robot towards the corresponding
                        % azimuth
                       
                        
                        if obj.robot.withCameraDisplay
                            
                            
                            
                            
                            % switch on camera
                            output=sprintf('activateRobotCamera');
                            fwrite(obj.robot.cameraDisplay,output);
                            fscanf(obj.robot.cameraDisplay,'%s');

                            sources=obj.robot.audioVisualSources();
                            for i=1:size(sources,1)
                                source=sources{i,1};
                                str=sprintf('visuallyFocusSource:%s',...
                                    source.name);
                                obj.taskStack.push(str);
                                
                            end
                            
                            
                            
                            
                            
                        else
                            % no camera available, currently not handled!
                        end
                        
                    end
                    
                    if strcmp(command,'visuallyFocusSource')
                        
                        % reset the display string for the entities
                        output=sprintf('setEntityDisplayStatus,None');
                        fwrite(obj.robot.cameraDisplay,output);
                        fscanf(obj.robot.cameraDisplay,'%s');

                        
                        currentSuperTask=command;
                        % note: tasks have to be inserted in inverse order!!!

                        if obj.robot.withTaskDisplay
                            % print to external logging window
                            str=sprintf('addTask,0,%s',obj.currentTask);
                            fwrite(obj.robot.taskDisplay,str);
                            fscanf(obj.robot.taskDisplay,'%s');
                        end
                        
                        source=obj.robot.getSourceByName(param1);
                        
                        % get current head pose in world coordinates
                        headPose=obj.robot.referencePosition;
                        hX=headPose(1,1);
                        hY=headPose(1,2);
                        hYaw=headPose(1,3);
                        
                        position=source.position;
                        % compute the azimuthal difference between
                        % robot's heading and azimuth of source
                        sX=position(1,1);
                        sY=position(1,2);
                        dirSource=...
                            [sX-hX;sY-hY;0]/norm([sX-hX;sY-hY;0]);
                        dirHeading=...
                            [cos(hYaw/180*pi);sin(hYaw/180*pi);0];

                        azimuthH=atan2(dot(...
                            cross(dirHeading,dirSource),...
                            [0;0;1]),dot(dirHeading,dirSource))...
                            /pi*180;

                        
                        
                        obj.taskStack.push('wait');
                        
                        str=sprintf('visuallyUpdateSourceCharacteristics:%s',param1);
                        obj.taskStack.push(str);
                        
                        % some extra time for the person detector to settle
                        obj.taskStack.push('wait:35');
                        
                        str=sprintf('rotate:%f',azimuthH);
                        obj.taskStack.push(str);
                    end
                    
                    if strcmp(command,'visuallyUpdateSourceCharacteristics')
                    
                        output=sprintf('getPersonStatus');
                        fwrite(obj.robot.cameraDisplay,output);
                        status=fscanf(obj.robot.cameraDisplay,'%s');
                        if strcmp(status,'Standing')
                            % upright person detected
                            output=sprintf('setEntityDisplayStatus,Subject is probably healthy!');
                            fwrite(obj.robot.cameraDisplay,output);
                            fscanf(obj.robot.cameraDisplay,'%s');
                        else
                            % person is likely procumbent, i.e. unconscious
                            output=sprintf('setEntityDisplayStatus,Subject is probably injured!');
                            fwrite(obj.robot.cameraDisplay,output);
                            fscanf(obj.robot.cameraDisplay,'%s');
                            
                            % augment entity corresponding to the focused
                            % source with a boosted hazard score, via a
                            % low physical integrity
                            source=obj.robot.getSourceByName(param1);
                            source.visualIntegrity=0.0;
                        end
                    end
                    
                    
                    if strcmp(command,'setupRescuePlan')
                        
                        
                        % switch off camera
                        output=sprintf('inactivateRobotCamera');
                        fwrite(obj.robot.cameraDisplay,output);
                        fscanf(obj.robot.cameraDisplay,'%s');
                        
                        
                        % here, the robot plans the rescue order by which
                        % the endangered entities are evacuated from the
                        % scenario. The rescue plan puts entities with
                        % higher threat scores higher in the ranking, thus
                        % rescuing them first. Note that the generated plan
                        % is continuously refined during scenario processing.
                        
                        currentSuperTask=command;
                        
                        if obj.robot.withTaskDisplay
                            % print to external logging window
                            str=sprintf('addTask,0,%s',obj.currentTask);
                            fwrite(obj.robot.taskDisplay,str);
                            fscanf(obj.robot.taskDisplay,'%s');
                        end
                        
                        % note: tasks have to be inserted in inverse order!!!
                        
                        % run over all observed entities and sort them
                        % according to their individual
                        % threat levels
                        
                        hypScores=[];
                        hypLabels={};
                        for i=1:size(auditoryObjectHyps,1)
                            hypScore=auditoryObjectHyps{i,1}.smoothedHazardScore;
                            hypScores=[hypScores;hypScore];
                            hypLabels{end+1,1}=auditoryObjectHyps{i,1}.label;
                        end
                        
                        [scores,indices]=sort(hypScores,'descend');
                        
                        % now, tag all sources with their rescue order
                        % number and aproach the first entity to be
                        % rescued (this entity corresponds to the first
                        % entry in the sorted array)
                        sortedLabels=hypLabels(indices);
                        for i=1:size(auditoryObjectHyps,1)
                            hypothesis=auditoryObjectHyps{i,1};
                            for j=1:size(sortedLabels,1)
                                if strcmp(sortedLabels{j,1},hypothesis.label)
                                    % do the tagging
                                    hypothesis.rescueOrderNumber=j;
                                    
                                    
                                end
                            end
                        end
                       
                        obj.taskStack.push('rescuePrioritizedEntity');
                    end
                    
                    
                    if strcmp(command,'rescuePrioritizedEntity')
                    
                        % rescue the prioritized entity
                        currentSuperTask=command;
                        
                        if obj.robot.withTaskDisplay
                            % print to external logging window
                            str=sprintf('addTask,0,%s',obj.currentTask);
                            fwrite(obj.robot.taskDisplay,str);
                            fscanf(obj.robot.taskDisplay,'%s');
                        end
                        
                        for i=1:size(auditoryObjectHyps,1)
                            hypothesis=auditoryObjectHyps{i,1};
                            if (hypothesis.rescueOrderNumber==1)
                                
                                % issue the rescue command for top
                                % level rescue order number
                                % iff the hazard score is positive
                                if hypothesis.smoothedHazardScore>0
                                
%                                     str=sprintf('rescue:%s:%f:%f',hypothesis.label,...
%                                         hypothesis.currentLocationEstimate(1,1),...
%                                         hypothesis.currentLocationEstimate(2,1));
%                                     obj.taskStack.push(str);
%                                     
                                    
                                     % note: tasks have to be inserted in inverse order!!!
                                    % the entities' estimated position, angle is
                                    % irrelevant
                                    position=[hypothesis.currentLocationEstimate(1,1),...
                                              hypothesis.currentLocationEstimate(2,1),0];
                                    obj.wayPoints(hypothesis.label)=position;
                                    % set up the navigation string


                                    % delete all blocking entries in the obstacle plan
                                    % in order to achieve an acceptable approaching
                                    % behavior of the robot
                                    obj.robot.deleteObstacleForSource(hypothesis.label);

                                    % navigate towards entity
                                    str=sprintf('navigate:%s',hypothesis.label);
                                    obj.taskStack.push(str);
                                    obj.robot.rescuedVictims=...
                                        obj.robot.rescuedVictims+1;
                                    
                                    
                                else
                                    % no more victims to be rescued, go to
                                    % idle position
                                    obj.robot.allVictimsRescued=true;
                                    obj.taskStack.push('idleMode');
                                    obj.taskStack.push('goToIdlePosition');
                                end
                            end

                        end
                    end
                    
                    
                    
                    
                    
                    
                    
                    if strcmp(command,'navigate')

                        % note: tasks have to be inserted in inverse order!!!

                        if obj.robot.withTaskDisplay
                            % print to external logging window
                            str=sprintf('addTask,1,%s',obj.currentTask);
                            fwrite(obj.robot.taskDisplay,str);
                            fscanf(obj.robot.taskDisplay,'%s');
                        end
                        
                        target=obj.wayPoints(param1);
                        obj.robot.planPath(target);
                        path=obj.robot.wayPoints;
                        for i=size(path,1):-1:2
                            % place reverted path into the task stack
                            str=obj.robot.wayPoints{i,1};
                            obj.taskStack.push(str);
                        end
                    

                    end

                    if strcmp(command,'translate')
                        
                        if obj.robot.withTaskDisplay
                            % print to external logging window
                            str=sprintf('addTask,1,%s',obj.currentTask);
                            fwrite(obj.robot.taskDisplay,str);
                            fscanf(obj.robot.taskDisplay,'%s');
                        end
                        
                        obj.robot.robotInterface.translatePlatformRelative(str2double(param1),0.3);
                        obj.taskIsPending=true;
                    end

                    if strcmp(command,'rotate')
                        
                        if obj.robot.withTaskDisplay
                            % print to external logging window
                            str=sprintf('addTask,1,%s',obj.currentTask);
                            fwrite(obj.robot.taskDisplay,str);
                            fscanf(obj.robot.taskDisplay,'%s');
                        end
                        
                        obj.robot.robotInterface.rotatePlatformRelative(str2double(param1),30.0);
                        obj.taskIsPending=true;
                    end
                    
                    
                    
                    if strcmp(command,'observe')

                        % note: tasks have to be inserted in inverse order!!!
                        
                        if obj.robot.withTaskDisplay
                            % print to external logging window
                            str=sprintf('addTask,1,%s',obj.currentTask);
                            fwrite(obj.robot.taskDisplay,str);
                            fscanf(obj.robot.taskDisplay,'%s');
                        end
                        
                         
                         obj.taskStack.push('observe');
                    end

                    
                    if strcmp(command,'wait')

                        % note: tasks have to be inserted in inverse order!!!
                        
                        if ~obj.waitInitiated
                            obj.waitInitiated=true;
                            if ~isempty(param1)
                                obj.waitCounter=str2num(param1);
                            else
                                obj.waitCounter=50;
                            end
                        else
                            
                            
                        end
                        
%                         if obj.robot.withTaskDisplay
%                             % print to external logging window
%                             str=sprintf('addTask,1,%s',obj.currentTask);
%                             fwrite(obj.robot.taskDisplay,str);
%                             fscanf(obj.robot.taskDisplay,'%s');
%                         end
%                         
                         if obj.waitCounter>0
                            obj.taskStack.push('wait');
                            obj.waitCounter=obj.waitCounter-1;
                         else
                             obj.waitInitiated=false;
                             obj.waitCounter=0;
                         end
                    end
                    
                    
                else
                    disp('No more tasks to perform!');
                    
                    
                end
                
               
            else
                if ~obj.robot.robotInterface.isTaskPending()
                    obj.taskIsPending=false;
                end
                
            end
            
            
            
            
            
            
            
            % push current supertask onto blackboard, always at time
            % zero, in order to save memory
            obj.blackboard.addData( ...
                'currentSuperTask',currentSuperTask,false,0);
            
            
            % push current subtask onto blackboard, always at time
            % zero, in order to save memory
            obj.blackboard.addData( ...
                'currentSubTask',currentSubTask,false,0);
            
            
            % push auditory object hypotheses back onto blackboard,
            % always at time zero, in order to save memory
            obj.blackboard.addData( ...
                'auditoryObjectHypotheses',auditoryObjectHyps,false,0);
            
            
            
            
            notify(obj, 'KsFiredEvent');            
        end
    end
end


