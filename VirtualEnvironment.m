
%--------------------------------------------------------------------------
% Class:                VisualizationCore
% Version:              1.0
% Last modification:    14.12.15
% Author:               T. Walther
%
% Description:
%   This class handles communication between the 
%   baseline visual simulator and the MATLAB(R) environment
%--------------------------------------------------------------------------


classdef VirtualEnvironment < handle
   
    
    properties (Access = public)
       
        % for compatibility with the blackboard
        
        % the blocksize of incoming signals
        BlockSize=2048; 
        % the sampling rate at which incoming signals are sampled
        SampleRate=44100; 

                
        simulationTime=0.0;         % The current system time
        
                                    
        audioVisualSources;         % the array ofAV sources found in a
                                    % processed scenario
        
        actionList;                 % list of all AV source-related
                                    % actions
                                     
        robotInterface;             % an interface to the simulated robot
        
        visualizerInterface;        % an interface to the baseline 2D
                                    % visualizer 
        
        auralizerInterface;         % an interface to the ssr auralizer
                                    
        referencePosition;          % position of the audio reference,
                                    
        referenceHeadingVector;     % the reference's heading vector
        
        robotPosition;              % the platform's position
        robotHeadingVector;         % the platform's heading vector
        
        finished;                   % is the simulation finished?
        
        
        centroids;
        centroidsOriginal;          % centroids withoud sources
        
        % several dimension parameters
        xofs;
        yofs;
        dx;
        dy;
        DimX;
        DimY;
        
        % baseline path planning variables
        wayPoints;
        
        
        % the scenario duration
        scenarioDuration=1000.0;
        
        
        
        
        % the following encodes the available meta tags, this information
        % is part of the environment, and has to be stored in this class!
        availableCategories;
        availableRoles;
        availableGenders;
        availableScalarParameters;
        
        
        allVictimsRescued;          % indicates whether all victims
                                    % have been evacuated
        rescuedVictims;             % the number of rescued victims
        timeForInitial2DSceneEstimate; % time used to construct the initial
                                       % estimate of the 2D scene layout
    end
    
    
    
    
    methods (Access = public)
        
        % The constructor
        function h = VirtualEnvironment()
           
            h.visualizerInterface=BaselineVisualizer(h);
            
            % set up categories and do some 'bookkeeping'
            h.availableCategories={'human','animal','threat','alert'};
            h.availableRoles={'employee','rescuer','victim','fire','siren','dog'};
            h.availableGenders={'male','female','NA'};
            h.availableScalarParameters={'stress','loudness','age'};
            
            h.centroids=cell(32,32);
            h.finished=false;
            h.xofs=1000;
            h.yofs=1000;
            h.dx=0.0;
            h.dy=0.0;
            h.wayPoints={};
            
            % create the robot interface
            h.robotInterface=RobotInterface(h);
                
        end
        
        
        
        
        
        
        
        % Blackboard communication start
        % Note: all of the below is highly uncomfortable and should be
        % eliminated in a newer system version with an altered blackboard!
        
        % Is the simulation finished? This function is required for
        % communication with the blackboard system.
        %
        % inputs:   none
        function ret=isFinished(h)
            fprintf('%f\n',h.simulationTime);
            ret=false;
        end
        

		% Is the simulation active? This function is required for
		% communication with the blackboard system.
		%
		% inputs:   none
		function ret=isActive(h)
			 ret=true;
		end
        
        
        % Enforce head rotation? This function is required for
        % communication with the blackboard system. Note that currently,
        % this function is meaningless, as all control commands come from
        % knowledge sources, using specific control variables
        %
        % inputs:   
        %           angle:  the angle to turn to
        %           mode:   the rotation mode           
        function rotateHead(h,angle,mode)
            % ...
        end
        
        % Get the robot head's current orientation in global coordinates
        % This function is required for communication with the blackboard.
        function orientation=getCurrentHeadOrientation(obj)
            orientation=atan2(sin(obj.referencePosition(1,3)/180*pi),...
                              cos(obj.referencePosition(1,3)/180*pi))*180/pi;
        end
        
        
        % Get the auralized signal as perceived by the Kemar head. this
        % function is required for communication with the blackboard, to
        % feed the AFE.
        
        % inputs:
        %       dT:             the interval for which a signal chunk has
        %                       to be acquired from the SSR
        %       signal:         the acquired signal
        %       trueIncrement:  returned by the SSR (s. SSR documentation)
        function [signal,trueIncrement]=getSignal(h,dT)
            % iff the SSR simulation has not finished
            if ~h.auralizerInterface.isFinished()

                % retrieve the signal
                [signal,trueIncrement] =...
                    h.auralizerInterface.getSignal(dT);
           end
        end
        
       
       
       % Blackboard communication stop  
        
        
        
            
        % retrieves the ID of the source closest to input position
        %
        % inputs:
        %       pos: the input position
        function ret=getSourceIDFromPosition(h,x,y)
            
            name='';
            minimum=100000.0;
            for i=1:size(h.audioVisualSources,1)
               
                goal=[x,y,0];
                pos=h.audioVisualSources{i,1}.position;
                
                dist=norm(goal-pos);
                if dist<minimum
                    minimum=dist;
                    name=h.audioVisualSources{i,1}.name;
                end
            
            end
            
            ret=name;
            
        end
        
        
        
        
        
         
        
        
        
        
        % Retrieves a source by name from the sources' list
        %
        % input:
        %           name: the name of the source to be retrieved
        function ret=getSourceByName(h,name)
            for i=1:size(h.audioVisualSources,1)
                
                if (strcmp(name,h.audioVisualSources{i,1}.name))
                    ret=h.audioVisualSources{i,1};
                    break;
                end                
            end
        end
        
        
        
        % This function plans a path from start to target position
        % positions are indicated as [x,y,theta]
        % On successful finish, the function has filled this object's wayPoint
        % structure
        function planPath(h,targetPos)
           
            startPos=h.visualizerInterface.robotPose;
            start=startPos(1,1:2);
            target=targetPos(1,1:2);
           
            
            startAngle=startPos(1,3);
            targetAngle=targetPos(1,3);
            % start path planning
            path=Astar(start,target,h.centroids,h.xofs,h.yofs,...
                h.dx,h.dy,startAngle,targetAngle);

            
            cpath=start; % the coordinate path
            for i=size(path,1):-1:1
                indX=path(i,1);
                indY=path(i,2);
                
                x=h.centroids{indX,indY}{1,1};
                y=h.centroids{indX,indY}{1,2};
                cpath=[cpath;[x,y]];
            end
            cpath(end,:)=target;
            
            
            



            % transform index path into coordinate path 

            % find navigation waypoints


            navStr=sprintf('rotate:%f',startAngle);
            h.wayPoints={};
            h.wayPoints{1,1}=navStr;
            arrayIndex=2;
            pathIndex=1;
            lastDirV=[cos(startAngle/180*pi),sin(startAngle/180*pi)];
            lastDirV=lastDirV/norm(lastDirV);
            lastX=start(1,1);
            lastY=start(1,2);

            while pathIndex<size(cpath,1)-1
                lookAhead=1;

                while lookAhead>-1
                    xa=cpath(pathIndex+lookAhead-1,1);
                    ya=cpath(pathIndex+lookAhead-1,2);

                   
                    xb=cpath(pathIndex+lookAhead,1);
                    yb=cpath(pathIndex+lookAhead,2);

                   
                    dirV=[xb-xa,yb-ya];
                    dirV=dirV/norm(dirV);

                    if dot(lastDirV,dirV)>0.99999 &&...
                            pathIndex+lookAhead+1<=size(cpath,1)
                        lookAhead=lookAhead+1;
                    else
                        pathIndex=pathIndex+lookAhead;
                        lookAhead=-1;

                        % translate from latest waypoint to recent
                        navDist=norm([xa-lastX,ya-lastY]);
                        navStr=sprintf('translate:%f',navDist);
                        h.wayPoints{arrayIndex,1}=navStr;
                        arrayIndex=arrayIndex+1;
                        % set rotation for recent waypoint
                        lastAngle=mod(atan2(lastDirV(1,2),lastDirV(1,1))/pi*180,360);
                        curAngle=mod(atan2(dirV(1,2),dirV(1,1))/pi*180,360);

                        navAngle=curAngle-lastAngle;
                        if navAngle>180
                            navAngle=navAngle-360;
                        end
                        navStr=sprintf('rotate:%f',navAngle);
                        h.wayPoints{arrayIndex,1}=navStr;
                        arrayIndex=arrayIndex+1;
                        lastX=xa;
                        lastY=ya;
                    end
                    lastDirV=dirV;
                end

            end
                
                % translate from latest waypoint to recent
                navDist=norm([target(1,1)-lastX,target(1,2)-lastY]);
                navStr=sprintf('translate:%f',navDist);
                h.wayPoints{arrayIndex,1}=navStr;
                arrayIndex=arrayIndex+1;

                % set rotation for recent waypoint
                lastAngle=mod(atan2(lastDirV(1,2),lastDirV(1,1))/pi*180,360);
                curAngle=mod(targetAngle,360);
                navAngle=curAngle-lastAngle;
                if navAngle>180
                    navAngle=navAngle-360;
                end
                navStr=sprintf('rotate:%f',navAngle);
                h.wayPoints{arrayIndex,1}=navStr;
            
        end
        
        
        
        function deleteObstacleForSource(h,name)
        
            for i=1:size(h.centroids,1)
                for j=1:size(h.centroids,2)
                    status=h.centroids{i,j}{1,3};
                    if strcmp(status,name)
                        h.centroids{i,j}{1,3}='None';
                    end
                end
            end
        
            
        end
        
        
        % Call this function to start a new session for a scene
        
        function startSession(h,scene)

            % reset statistics
            h.allVictimsRescued=false;
            h.rescuedVictims=0;
            h.timeForInitial2DSceneEstimate=0.0;
           

            

            % after the folowing command, the environmental descriptor 'eD'
            % is available for further initialization
            load(scene);

            
           
            
            h.DimX=eD.DimX;
            h.DimY=eD.DimY;
            
            % for compatibility
            dimx=h.DimX;
            dimy=h.DimY;
            
            h.dx=eD.dx;
            h.dy=eD.dy;
            h.xofs=eD.ofsX;
            h.yofs=eD.ofsY;
            
            h.audioVisualSources=eD.AVSources;

            h.centroids=eD.ObstaclePlan;
            
            h.centroidsOriginal=h.centroids;
            
            h.visualizerInterface.robotPose=eD.robotPose;
            
            % currently, head and platform poses always coincide
            h.visualizerInterface.headPose=h.visualizerInterface.robotPose;
            


           
           


              
            % surround all source positions with obstacle indices


            for i=1:size(h.audioVisualSources,1)
                source=h.audioVisualSources{i,1};
                position=source.position;

                position=position(1,1:2)-[h.xofs,h.yofs];
                position(1,1)=position(1,1)/dimx;
                position(1,2)=position(1,2)/dimy;
                position=position*32;
                position=round(position);
                position=position-1;

                for u=-2:1:2
                   for v=-2:1:2
                        indX=position(1,1)+u;
                        indY=position(1,2)+v;
                        if indX>31
                            indX=31;
                        end

                        if indX<0
                            indX=0;
                        end

                        if indY>31
                            indY=31;
                        end

                        if indY<0
                            indY=0;
                        end

                        h.centroids{indX+1,indY+1}={h.centroids{indX+1,indY+1}{1,1},h.centroids{indX+1,indY+1}{1,2},source.name};

                   end
                end




            end



        


            h.simulationTime=0.0;
            h.visualizerInterface.resetTime();
        end

        
        % The following function is called on destruction of the class
        function stopSession(h)
            disp('Current session stopped!');
        end
        
        
        

   
        
        
        
        
       
        
        
        
        % This is the central function of the VisualizationCore. It keeps
        % up with sound extraction, image generation, and data management.
        function time=stepSimulation(h)
            % send stepping order to environment
            h.visualizerInterface.stepSimulation();
            % read back current simulation time/reference position
            simString=h.visualizerInterface.getEnvironmentalData();
            strSplit=strsplit(simString,',');  
            h.simulationTime=str2double(strSplit{1});
            h.robotPosition=[str2double(strSplit{2}),...
                                str2double(strSplit{3}),...
                                str2double(strSplit{4})/pi*180.0];
                            
            h.referencePosition=[str2double(strSplit{5}),...
                                str2double(strSplit{6}),...
                                str2double(strSplit{7})/pi*180.0];
            
            time=h.simulationTime;             
            
            % run through action list and trigger actions according to the
            % current system time             
            
            
            for i=1:size(h.audioVisualSources,1)
                source=h.audioVisualSources{i,1};
                while (~isempty(source.schedule)) && ...
                        (source.schedule{1,1}.time<=time)
                    action=source.schedule{1,1};
                    if ~source.block
                        if (strcmp(action.type,'emit'))
                            % the affected source begins an emission of sound
                            fprintf('time: %f -> action: source "%s" emits stimulus: "%s"\n',...
                                    time,action.source,action.value);

                            % activate audio output
                            source=h.getSourceByName(action.source);
                            % set the source's emission status
                            source.emitting=true;

                        end

                        if (strcmp(action.type,'mute'))
                            % the affected source is muted
                            fprintf('time: %f -> action: source "%s" is muted\n',...
                                    time,action.source);


                            % deactivate audio output
                            source=h.getSourceByName(action.source);
                            % reset the source's emission status
                            source.emitting=false;

                        end


                        if (strcmp(action.type,'modify'))
                            % the affected source begins an emission of sound
                            fprintf('action: source "%s" is modified; set parameter "%s" to value %s...\n',...
                                    action.source,action.parameter,action.value);
                            source=h.getSourceByName(action.source);
                            if (strcmp(action.parameter,'role'))
                                source.role=action.value;
                                source.adaptRoleMetaInformation();
                            end

                            if (strcmp(action.parameter,'stress'))
                                source.stress=(action.value);
                                source.adaptStressMetaInformation();
                            end

                            if (strcmp(action.parameter,'loudness'))
                                source.loudness=(action.value);
                                source.adaptLoudnessMetaInformation();
                            end

                            if (strcmp(action.parameter,'displayStatus'))
                                source.displayStatus=action.value;
                            end


                        end

                    end

                    % removes first element from the actionList
                    source.schedule(1,:)=[];
                end
            end
            if h.simulationTime>=h.scenarioDuration
                h.finished=true;
            end
        end     
        
        
        
        
        
        
        
        
        
        % This function reads a schedule file and generates
        % a corresponding action pattern from the file's contents
        %
        % input:
        %           scheduleFile:   the file from which the schedule is
        %                           read, name without 'home' of the
        %                           current user
        function loadSourceSchedules(h,scheduleFile)
            % the name of the schedule for all sources is always:
            % 'scheduledSources'
            load(scheduleFile);
            % generate a list of AV sources from the schedule information
            for i=1:size(scheduledSources,1)
                source=scheduledSources{i,1};
                for j=1:size(h.audioVisualSources,1)
                    avSource=h.audioVisualSources{j,1};
                    
                    if (strcmp(avSource.name,source.name))
                    
                        avSource.category=source.category;
                        avSource.role=source.preEventRole;
                        avSource.gender=source.gender;
                        if strcmp(source.age,'NA')
                            avSource.age=-1000.0;
                        else
                            avSource.age=source.age;
                        end
                        
                        if strcmp(source.stress,'NA')
                            avSource.stress=-1000.0;
                        else
                            avSource.stress=source.stress;
                        end
                        
                        if strcmp(source.loudness,'NA')
                            avSource.loudness=-1000.0;
                        else
                            avSource.loudness=source.loudness;
                        end
                        
                        avSource.schedule=source.schedule;
                        
                    end
                end
            end
            
            for i=1:size(h.audioVisualSources,1)
                h.audioVisualSources{i,1}.adaptCategoryMetaInformation();
                h.audioVisualSources{i,1}.adaptRoleMetaInformation();
                h.audioVisualSources{i,1}.adaptGenderMetaInformation();
                h.audioVisualSources{i,1}.adaptGenderMetaInformation();
                h.audioVisualSources{i,1}.adaptStressMetaInformation();
                h.audioVisualSources{i,1}.adaptLoudnessMetaInformation();
                h.audioVisualSources{i,1}.adaptAgeMetaInformation();
                
                
            end
            
        end
        
        
        
        
        % This is the class destructor. Clean up here if necessary.
        function delete(h)
           h.stopSession();
        end       
    end
    
    methods (Access = protected)
        
    end    
end


