

% 'AuditoryMetaTaggingKS' class
% This knowledge source emulates results of an auditory-based category
% classifier.

% Author: Thomas Walther
% Date: 21.10.15
% Rev. 1.0

classdef VisualizeDNNResultsKS < AuditoryFrontEndDepKS
    

    properties (SetAccess = public)
        robot;                        % Reference to the robot environment
                                      % of auditory objects
        debugFigure;
        debugTime;
        firstRun;               % true iff this source has not been started
                                % before
        azimuthAccumulator;     % Collects information on the observed
                                % azimuths
        azimuthSamples;         % how many azimuth evidences have been
                                % integrated in the accumulator?
        azimuthDistribution;    % the accumulated azimuth distribution
        precision;              % the angular precision
        setClean;               % tells the KS to clean the accumulator
                                % array (azimuthDistribution)
    end

    methods
        % the constructor
        function obj = VisualizeDNNResultsKS(robot)
            
            % prepare AFE, standard parameters
            param = genParStruct(...
                'fb_type', 'gammatone', ...
                'fb_lowFreqHz', 80, ...
                'fb_highFreqHz', 8000, ...
                'fb_nChannels', 32, ...
                'rm_decaySec', 0, ...
                'ild_wSizeSec', 20E-3, ...
                'ild_hSizeSec', 10E-3, ...
                'rm_wSizeSec', 20E-3, ...
                'rm_hSizeSec', 10E-3, ...
                'cc_wSizeSec', 20E-3, ...
                'cc_hSizeSec', 10E-3);
            requests{1}.name = 'ild';
            requests{1}.params = param;
            requests{2}.name = 'itd';
            requests{2}.params = param;
            requests{3}.name = 'time';
            requests{3}.params = param;
            requests{4}.name = 'ic';
            requests{4}.params = param;
            obj = obj@AuditoryFrontEndDepKS(requests);
            
            % call each frame
            obj.invocationMaxFrequency_Hz = inf;
            % set member variables
            obj.robot = robot; 
            obj.debugFigure=figure('Name','DNNLocation');
            obj.azimuthAccumulator=zeros(1,360);
            obj.azimuthSamples=0;
            obj.firstRun=true;
            obj.precision=1;
            obj.setClean=false;
        end

        function [b, wait] = canExecute(obj)
            % self-explanatory
            b = true;
            wait = false;            
        end

        
        function energy=getSignalLevel(obj)
            afeData = obj.getAFEdata();
            signal = afeData(3);
            % extract the current signal block
            sig=signal{1,1}.getSignalBlock(0.05,obj.timeSinceTrigger);
            % return the signal variance, which can be seen as the
            % mean-free signal power
            % cf. http://www.dsprelated.com/freebooks/mdft/
            % Signal_Metrics.html
            
            energy = var(sig);            
        end
        
        
        function execute(obj)
            
            sourceLocationHypotheses=[];
            try
                sourceLocationHypotheses=...
                    obj.blackboard.getLastData(...
                            'sourcesAzimuthsDistributionHypotheses');
                azimuths=sourceLocationHypotheses.data. ...
                                            azimuths;
                distribution=sourceLocationHypotheses.data. ...
                                            sourcesDistribution;
                headOrientation=sourceLocationHypotheses.data. ...
                                            headOrientation;
                
            catch
            end
                
            if ~isempty(sourceLocationHypotheses)
                afeData = obj.getAFEdata();
                 
                signal=afeData(3);
                
                distributionWorld=zeros(1,360);
                for i=1:size(azimuths,2)
                    azimuthW=azimuths(1,i)+headOrientation;
                    azimuthW=mod(azimuthW,360);
                    index=round(azimuthW);
                    if index<1
                        index=1;
                    end
                    if index>360
                        index=360;
                    end
                    distributionWorld(index)=distribution(i);
                end
                if obj.getSignalLevel()>0
                    
                    distributionWorld=sgolayfilt(distributionWorld,3,11);
                    distributionWorld(distributionWorld<0)=0;
                    obj.azimuthSamples=obj.azimuthSamples+1;
                    obj.azimuthAccumulator=obj.azimuthAccumulator+distributionWorld;

                end                
                
                
                % get current head pose in world coordinates
                headPose=obj.robot.referencePosition;
                hX=headPose(1,1);
                hY=headPose(1,2);
                hYaw=headPose(1,3);

                domain=0:1:359;
                values=zeros(1,360);
                

                % run over all available sound sources
                sources=obj.robot.audioVisualSources;
                for i=1:size(sources,1)
                    % only for active sources
                    %if sources{i,1}.emitting
                        position=sources{i,1}.position;
                        sX=position(1,1);
                        sY=position(1,2);
                        % find the acoustic source's azimuth in world
                        % coordinates
                        azimuthW=mod(atan2(sY-hY,sX-hX)/pi*180,360);

                        % transform azimuth to head-centric KS
                        azimuthH=mod(azimuthW-hYaw,360);
%                         if (azimuthH>180)
%                             azimuthH=azimuthH-360;
%                         end

                        values(1,floor(azimuthW))=100.0*max(obj.azimuthAccumulator/obj.azimuthSamples);
                   % end
                end
                
                set(0,'currentfigure',obj.debugFigure);
                stem(domain,values,'r','Marker','None','LineWidth',1.5);
                hold on;
                plot(domain,obj.azimuthAccumulator/obj.azimuthSamples);
                %plot(locs,pksNew,'*');
                %plot([0 360],[m m]);
                ylim([0,0.07]);
                hold off;
                
                drawnow;
            
            end
            
                                
               
            
            notify(obj, 'KsFiredEvent');   
          
        end
    end
end
