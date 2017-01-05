
%--------------------------------------------------------------------------
% Class:                SSRInterface
% Version:              1.0
% Last modification:    18.12.15
% Author:               T. Walther
%
% Description:
%   This class handles communication between the SSR auralizer
%   and the MATLAB(R) environment. It also enables transfer of
%   the auralized signal to an external system (e.g., the blackboard
%   system). Currently, reverberation is not available.
%--------------------------------------------------------------------------



classdef SSRInterface < handle
    
    properties (Access=public)
        samplingRate;       % the simulator's sampling rate, currently set
                            % 44100 Hz
        parent;             % the auralizer's parenting VisualizationCore
        sim;                % the auralizer's simulation core
        hrir;               % the head-related impulse response used
        outputSignal;       % the auralizer's binaural output signal
                            % aggregated over the complete simulation
        leftEarSignal;      % the left ear's signal in a given frame, as
                            % computed by the auralizer
        rightEarSignal;     % the right ear's signal in a given frame, as
                            % computed by the auralizer
                            
        residualSignal;     % this is the memory used to store the remain-
                            % der of a signal chunk processed by the SSR.
                            % Due to the awkward 8-byte limitation of the
                            % SSR, this variable becomes mandatory!
        chunkNr;            % also necessary to handle the 8-byte limi-
                            % tation
        SSRMemory;          % the global memory for SSR-generated output.
                            % Due to the 8-byte alignment mentioned above,
                            % this memory becomes necessary
    end
    
    methods (Access=public)
        
        % The constructor
        %
        % input:
        %           parent:     the auralizer's parenting VisualizationCore
        %           hrir:       the used head-related impulse response
        function obj=SSRInterface(parent,hrir)
            % activate Two!Ears
            startTwoEars();
            obj.parent=parent;
%             fullyQualifiedName=sprintf('%s%s',...
%                 getDatabasePath(),hrir);
%             if ~exist(fullyQualifiedName,'file')
%                 error('HRIR filename is invalid!');
%             end
%             
            obj.hrir=hrir;
            % current sampling rate is 44100 Hz
            obj.samplingRate=44100;
            % propagate that to the parent class,necessary for the current
            % blackboard architecture
            obj.parent.SampleRate=obj.samplingRate;
            % delete variables
            obj.sim=[];
            obj.outputSignal=[];
            obj.leftEarSignal=[];
            obj.rightEarSignal=[];
            obj.residualSignal=[];
            obj.chunkNr=0;
            obj.SSRMemory=[];
            
        end
        
        
        % Plays the simulators binaural output signal as of the current
        % time step
        %
        function playbackOutputSignal(obj)
            soundsc(obj.outputSignal,obj.samplingRate);
        end
        
        
        
        % Retrieves a source by name from the sources' list
        %
        % input:
        %           name: the name of the source to be retrieved
        % outputs:
        %           source: the source from the simulators storage
        %           is:     the source's id in the storage list
        function [source,id]=getSourceByName(obj,sourceName)
            for i=1:size(obj.sim.Sources,1)                
                name=get(obj.sim.Sources{i,1},'Name');
                if (strcmp(sourceName,name))
                    source=obj.sim.Sources{i,1};
                    id=i;
                    break;
                end
            end
        end
        
        
        
        % This function reads all source data from the parent
        % VisualizationCore, and builds the SSR's internal world
        % representation by means of source positions, and reference
        % position.
        function instantiate(obj)
            
            BS=2048; % currently fix the block size
            
            
            obj.parent.BlockSize=BS;
                
            % propagate that to the parent class,necessary for the current
            % blackboard architecture
            
            
            
            
            % prepare the source container
            AVSources=obj.parent.audioVisualSources;
            sourcesContainer=cell(size(AVSources,1)+1,1); % +1 for silent
                                                          % source, see
                                                          %below
            for i=1:size(sourcesContainer,1)
               sourcesContainer{i}=simulator.source.Point();
            end

                

            % use a free field simulation, duration infinite
            obj.sim = simulator.SimulatorConvexRoom();
            set(obj.sim, ...
                  'BlockSize', BS, ...
                  'SampleRate', obj.samplingRate, ...                  
                  'LengthOfSimulation',1000, ...
                  'Renderer', @ssr_binaural, ...
                  'HRIRDataset', simulator.DirectionalIR(obj.hrir), ...
                  'Sources', sourcesContainer, ...
                  'Sinks',   simulator.AudioSink(2) ...
              );
          
            % set up all sources from the parent in the auralizer's
            % context
            
            for i=1:size(AVSources,1)
                set(...
                    obj.sim.Sources{i}, ...
                    'Name',AVSources{i,1}.name, ...
                    'Position', AVSources{i}.position', ...
                    'AudioBuffer', simulator.buffer.FIFO(1) ...                
                   );              

            end
            
            % add an additional, 'silent' source, necessary to keep SSR
            % running            
            set(...
                    obj.sim.Sources{size(AVSources,1)+1}, ...
                    'Name','silentSource', ...
                    'Position',[0 0 1e3]', ...
                    'AudioBuffer', simulator.buffer.FIFO(1), ...
                    'Volume',0.0...
                   );
            % activate the silent source
            silentSignal=zeros(44100*1000,1);
            obj.sim.Sources{...
                size(AVSources,1)+1,1}.AudioBuffer.removeData();
            obj.sim.Sources{...
                size(...
                    AVSources,1)+1,1}.AudioBuffer.appendData(silentSignal);
           % delete relevant variables
          obj.outputSignal=[];
          obj.leftEarSignal=[];
          obj.rightEarSignal=[];
          obj.sim.set('Init',true);
          
        end
        
        
        
        
        % This function shuts down the auralizer.
        function deinstantiate(obj)
            obj.sim.set('ShutDown',true);
            if ~isempty(obj.sim);
                delete (obj.sim);
                obj.sim=[];
            end
        end
        
        
        % Is the auralizer simulation finished?
        function ret=isFinished(obj)
            ret=false;%obj.sim.isFinished();
        end
        
        
        % This function steps the auralizer forward in time.
        %
        % input:
        %           dT: the time step from VisualizationCore
        function [sig, actualTime] = getSignal(obj,dT)
            if ~isempty(obj.sim)
                if ~obj.sim.isFinished()
                  
                  referencePosition=[obj.parent.referencePosition(1,1:2)';0];
                  referenceHeading=obj.parent.referencePosition(1,3)/180*pi;
                  referenceHeadingVector=...
                        [cos(referenceHeading);sin(referenceHeading);0];
                  set(obj.sim.Sinks, ...
                    'Position',referencePosition, ...
                    'UnitX',referenceHeadingVector,...
                    'UnitZ', [0; 0; 1]);
                    
                    
                    [sig, tForward] = obj.sim.getSignal(dT);
                    obj.outputSignal = [obj.outputSignal; sig];
                    
                    % resample for DNNLocationKS
                    sigResampled=(resample(double(sig),16000,44100));
                    %sig=sigResampled;
                    % the SSR retrieves a signal chunk which is generally
                    % not corresponding to the frame length of the
                    % VisualizationCore. Thus, the signal has to be
                    % post-processed in order to generate matching frame
                    % contents in the audio and visual domain.
                    
                    
                    % store the current signal chunk from SSR
                    obj.SSRMemory=[obj.SSRMemory;sig];
                    
%                     % now, compute the output signal for the system
%                     out_sig=obj.SSRMemory(  obj.chunkNr*...
%                                             obj.parent.BlockSize+1:...
%                                             (obj.chunkNr+1)*...
%                                             obj.parent.BlockSize,:);
%                     
                    actualTime=tForward;
                    obj.chunkNr=obj.chunkNr+1;
                    
                    obj.leftEarSignal=sig(:,1);
                    obj.rightEarSignal=sig(:,2);                
                end
            end
        end
        
        % This function repositions the reference.
        %
        % inputs:
        %           position:    the new 3D position of the reference
        %           heading:     the reference's new heading vector
        function repositionReference(obj,position,heading)
            
        end
        
        
        % This function enables a source to play its current stimulus.
        %
        % inputs:
        %           sourceName:   the affected source's name
        %           stimulus:   the stimulus this source should play
        function startSourceEmission(obj,sourceName,stimulus)
            [source,id]=obj.getSourceByName(sourceName);
            if ~isempty(stimulus)
                [signal, fs] = audioread(stimulus);
                obj.parent.getSourceByName(sourceName).currentStimulus=stimulus;
            
                % resample signal
                resampledSignal = resample(signal,...
                    obj.samplingRate,fs);
                signalPeak=max(abs(resampledSignal));
                % normalize signal
                normalizedSignal=resampledSignal(:,1);%./signalPeak(1);
                % clear source buffer
                obj.sim.Sources{id,1}.AudioBuffer.removeData();
                % set new signal
                obj.sim.Sources{id,1}.AudioBuffer.appendData(...
                                                        normalizedSignal);

            end            

        end
        
        
        % This function mutes an active source.
        %
        % inputs:
        %           sourceName:   the affected source's name
        function muteSource(obj,sourceName)
            [source,id]=obj.getSourceByName(sourceName);
            obj.sim.Sources{id,1}.AudioBuffer.removeData();
        end
        
        
        % This function allows sources to play continously, and is used to
        % update other elements required for auralization
        function update(obj)            
            sources=obj.parent.getAudioVisualSources();            
            for i=1:size(sources,1)
                % iff this source is continuous (auditory domain)
                if sources{i,1}.continuous && ...
                        sources{i,1}.emitting
                    % and its sample buffer is empty
                    if obj.sim.Sources{i,1}.AudioBuffer.isEmpty()
                        % restart the source (play its stimulus in a loop)
                        sourceName=sources{i,1}.name;
                        stimulus=sources{i,1}.currentStimulus;
                        obj.startSourceEmission(...
                            sourceName,stimulus);
                        
                    end
                end
            end
        end       
        
    end
    
end

