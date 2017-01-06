

%--------------------------------------------------------------------------
% Class:                AudioVisualSource
% Version:              1.0
% Last modification:    15.12.15
% Author:               T. Walther
%
% Description:
%   This class handles repreesents an audio-visual source as to be used by
%   the VisualizationCore class. AV sources can be fully scheduled.
%   Schedules can be set manually (not recommended) or automatically using
%   the scripts in the 'Tools/Scripts/ScheduleGenerators' directory.
%   Note that sources are currently assuemd spherical.
%--------------------------------------------------------------------------


classdef AudioVisualSource < handle
    
    properties (Access = public)
        parent;             % the parenting VisualizationCore object
        name;               % the source's name        
        position;           % the sources 3D position
        currentStimulus;    % the source's current stimulus
        emitting;           % is the source emitting its stimulus? 
        continuous;         % is this source playing continuously?
        
        category;           % this source's category
        role;               % this source's role
        gender;             % the source's gender
        age;                % the source's age
        stress;             % the source#s stress level
        loudness;           % the source's loudness
        
        schedule;           % the source's schedule
        
        trueReliabilitiesSet;
        wrongReliabilitiesSet;
        stressLevels;
        loudnessLevels;
        ageDistribution;
        
        categories;
        trueCategoryIndex;

        roles;
        trueRoleIndex;
        
        genders;
        trueGenderIndex;
        
        emotions;
        displayStatus;
        block;
        
        visualIntegrity;
        
    end
    
    methods (Access = public)
    
        % The constructor.
        % Inputs:
        %           parent: the source's parenting VisualizationCore object
        %           name:   the source's name
        %           pos:    the source's position (3D)
        function obj=AudioVisualSource(parent,name,pos)
            obj.parent=parent;
            obj.name=name;
            obj.position=pos;
            obj.emitting=false; % source is initially muted
            obj.continuous=true; %  all sources are currently playing
                                 %  continuously
            
            
            obj.trueReliabilitiesSet=max(min(nrnd(0.9,0.01,10000),1.0),0.0);
            obj.wrongReliabilitiesSet=max(min(nrnd(0.1,0.05,10000),1.0),0.0);

           
            obj.stressLevels=-ones(1,10000)*1000;
            obj.loudnessLevels=-ones(1,10000)*1000;
            obj.ageDistribution=-ones(1,10000)*1000;
            
            obj.categories=obj.parent.availableCategories;
            obj.roles=obj.parent.availableRoles;
            obj.genders=obj.parent.availableGenders;
            obj.emotions=obj.parent.availableScalarParameters;
            obj.stress=0.0;
            obj.loudness=0.0;
            obj.age=0.0;
            obj.displayStatus='normal';
            
            obj.block=false; % prevent emission unless explicitly allowed,
                            % necessary for the alert source
            
            obj.visualIntegrity=1.0; % entity is initially healthy
            
        end
        
        
        % below: some helper functions to compute reliabilities for a
        % certain source
        function reliabilities=getCategoryEstimates(obj)
            
            
            reliabilityIndices=randi(10000,1,size(obj.categories,2));
            reliabilities=obj.wrongReliabilitiesSet(reliabilityIndices);
            reliabilities(obj.trueCategoryIndex)=obj.trueReliabilitiesSet(randi(10000));

            
        end
        
        
        function reliabilities=getRoleEstimates(obj)
            
            
            reliabilityIndices=randi(10000,1,size(obj.roles,2));
            reliabilities=obj.wrongReliabilitiesSet(reliabilityIndices);
            reliabilities(obj.trueRoleIndex)=obj.trueReliabilitiesSet(randi(10000));

            
        end
        
        
        
        function reliabilities=getGenderEstimates(obj)
            
            reliabilityIndices=randi(10000,1,size(obj.genders,2));
            reliabilities=obj.wrongReliabilitiesSet(reliabilityIndices);
            reliabilities(obj.trueGenderIndex)=obj.trueReliabilitiesSet(randi(10000));

            
        end
        
        
        
        function reliabilities=getEmotionEstimates(obj)
            
            reliabilities=zeros(1,size(obj.emotions,2));
            reliabilities(1,1)=obj.stressLevels(randi(10000));
            reliabilities(1,2)=obj.loudnessLevels(randi(10000));
            reliabilities(1,3)=obj.ageDistribution(randi(10000));
        end
        
        
        
        function adaptCategoryMetaInformation(obj)
            [~,index]=ismember(obj.category,obj.categories);
            obj.trueCategoryIndex=index;
        end
         
        function adaptRoleMetaInformation(obj)
            [~,index]=ismember(obj.role,obj.roles);
            obj.trueRoleIndex=index;
        end
        
        
        function adaptGenderMetaInformation(obj)
            [~,index]=ismember(obj.gender,obj.genders);
            obj.trueGenderIndex=index;
        end
        
        
        function adaptStressMetaInformation(obj)
            if obj.stress>0
                obj.stressLevels=max(min(nrnd(obj.stress,0.025,10000),1.0),0.0);
            end
        end
        
        function adaptLoudnessMetaInformation(obj)
            if obj.loudness>0
                obj.loudnessLevels=max(min(nrnd(obj.loudness,0.025,10000),1.0),0.0);
            else
                
            end
        end
        
        function adaptAgeMetaInformation(obj)
            if obj.age>0
                obj.ageDistribution=max(min(nrnd(obj.age,2,10000),100),0.0);
            else
               
            end
            
                
        end
        
        
        
    end
    
end

