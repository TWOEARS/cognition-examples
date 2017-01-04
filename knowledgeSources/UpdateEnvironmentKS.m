

% 'updateEnvironmentKS' class
% This knowledge source communicates with the LVTE, and triggers
% basic environmental updates, including variable updates, robot movements,
% 3D plotting

% Author: Thomas Walther
% Date: 21.10.15
% Rev. 1.0

classdef UpdateEnvironmentKS < AbstractKS
    

    properties (SetAccess = private)
        robot;                        % Reference to the robot environment
        firstRun;                     % is this the first cycle?
        timeValues;
    end

    methods
        % the constructor
        function obj = UpdateEnvironmentKS(robot)
            obj = obj@AbstractKS();
            % call each frame
            obj.invocationMaxFrequency_Hz = inf;
            % set member variables
            obj.robot = robot; 
            obj.firstRun=true;
            obj.timeValues=[];
        end

        function [b, wait] = canExecute(obj)
            % self-explanatory
            b = true;
            wait = false;            
        end

        
        function execute(obj)
            % initiate an environmental update
            if obj.firstRun
                % ...
            end
            obj.robot.stepSimulation();
            timeStep=obj.blackboardSystem.robotConnect.BlockSize/...
                                obj.blackboardSystem.robotConnect.SampleRate;
            obj.blackboard.advanceSoundTimeIdx(timeStep);
            
            
          
            
            
           
            
            
            
            
            
            notify(obj, 'KsFiredEvent');            
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
