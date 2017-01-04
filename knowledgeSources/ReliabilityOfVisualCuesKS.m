




classdef ReliabilityOfVisualCuesKS < AbstractKS
    

    properties (SetAccess = public)
        robot;                        % Reference to the robot environment
        taskStack;                    % stack for all provided tasks and subtasks
        visualCueWeights;             % the timecourse of the visual cue weights
        debugFigure;                  % graphical output for cue reliabilites' timecourse
        domain;                       % the temporal domain for the timecourse plot
        counter;                      % the counter for filling the timecourse
    end

    methods
        % the constructor
        function obj = ReliabilityOfVisualCuesKS(robot)
            obj = obj@AbstractKS();
            % call each frame
            obj.invocationMaxFrequency_Hz = inf;
            % set member variables
            obj.robot = robot; 
            obj.debugFigure=figure('Name','Reliability of visual cues');
            obj.domain=0:(2048/44100):130;
            obj.visualCueWeights=zeros(1,size(obj.domain,2));
            obj.counter=1;
        end

        function [b, wait] = canExecute(obj)
            % self-explanatory
            b = true;
            wait = false;            
        end

        
         
        function execute(obj)
            
            
            
            % assess overall image brightness value
            output=sprintf('getImageBrightness');
            fwrite(obj.robot.cameraDisplay,output);
            brightnessStr=fscanf(obj.robot.cameraDisplay,'%s');
            brightness=str2double(brightnessStr);
            a1=0.15;
            a2=0.85;
            b=100;
            x=brightness;
            weight=1/...
                        (...
                            1+exp(-b*(x-a1))...
                        )*...
                    1/...
                        (...
                            1+exp(b*(x-a2))...
                        );
            
            
            if obj.counter<=size(obj.visualCueWeights,2)
                obj.visualCueWeights(1,obj.counter)=weight;
                obj.counter=obj.counter+1;
            end
            set(0,'currentfigure',obj.debugFigure);
            
            plot(obj.domain,obj.visualCueWeights,'r','LineWidth',1.0);
            
            xlim([0,130]);
            ylim([0,1]);
            

            drawnow;
            
            
            notify(obj, 'KsFiredEvent');            
        end
    end
end


