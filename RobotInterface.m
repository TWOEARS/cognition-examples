%--------------------------------------------------------------------------
% Class:                RobotInterface
% Version:              1.0
% Last modification:    17.12.15
% Author:               T. Walther
%
% Description:
%   This class handles communication between the Blender/Blender-based
%   virtual robot and the MATLAB(R) environment. The robot commands are
%   currently restricted to minimal movements (base, head), yet an
%   extension to this minimum set is intended in later expansion stages.
%--------------------------------------------------------------------------


classdef RobotInterface < handle
    properties (Access=private)
        parent;             % the robot's parent class (VisualizationCore)
        HATSArmature;       % the robot's HATS armature, controls torso and
                            % head
        supportPlatform;    % the robots supporting platform, carrying the
                            % HATS
        motionController;   % the robot's motion controller; controls
                            % platform motion
        taskTimer;          % is a timer that indicates the progress of
                            % a given task (translation,rotation)
        taskPending;        % indicates whether a task is pending (in
                            % progress)
        taskName;           % the name of the pending task
        taskGoal;           % the pending task's goal, in case of rotation
                            % this is the new azimuth, in case of
                            % translation, this is the goal position
        taskLimitVelocity;  % the maximum velocity that has to be used for
                            % the motion to be performed; in case of linear
                            % motion, this is the intended linear velocity,
                            % in case of rotation, this is the angular
                            % velocity. Note: THIS IS ALWAYS > 0!
        taskPreviousOmega;  % the angular velocity in the previous timestep
        taskPreviousVel;    % the linear velocity in the previous timestep
        dPhi=1e-3;          % when a platform/head rotation approaches its
                            % goal and the corresponding angular difference
                            % falls below this value, the goal is assumed
                            % sufficiently close, and the rotation is
                            % stopped. This value is in degrees!
        dPos=1e-3;          % same as dPhi for translatory motion
        
       
    end
    
    
    methods (Access=public)
        
        % The constructor
        function obj=RobotInterface(parent)
           obj.parent=parent;
           obj.taskPending=false;
           obj.taskTimer=0;
           
        end
        
        
        % is a task pending
        function ret=isTaskPending(obj)
            ret=obj.parent.visualizerInterface.isTaskPending();
        end
        
       
        
        
        
        % Translates the robot's support platform into the current heading
        % direction.
        %
        % input:
        %           d: the translation distance [m]
        %           v:  the robot's linear velocity [m/s], always>0!!!
        function translatePlatformRelative(obj,d,v)
            output=sprintf('%s,%f,%f','translateRelative',...
                                        d,v);
            obj.parent.visualizerInterface.issueTask(output);           
        end
        
        % Sets the robot platform's relative heading in degree.
        %
        % input:
        %           h:  the goal heading (relative, [deg], h=[-180,180])
        %           w:  the robot's angular velocity [deg/s], always>0!!!
        function rotatePlatformRelative(obj,h,w)
            output=sprintf('%s,%f,%f','rotateRelative',...
                                        h,w);
            obj.parent.visualizerInterface.issueTask(output);           
        end
       
        
    end
    
end

