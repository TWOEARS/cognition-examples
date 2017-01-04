
% A helper class for source scheduling
classdef sourceProxy < handle
   
    properties (SetAccess = public)
        name;
        startTime;
        stopTime;
        preEventEmissionInterval;
        preEventSilenceInterval;
        postEventEmissionInterval;
        postEventSilenceInterval;
        preEventStressDistribution;
        preEventLoudnessDistribution;
        postEventStressDistribution;
        postEventLoudnessDistribution;
        gender;
        age;
        category;
        preEventRole;
        postEventRole;
        stress;
        loudness;
        timeOfEvent;
        schedule;
        dT;
        
    end
    
    methods
         function obj = sourceProxy(name,...
                                    gender,...
                                    age,...
                                    category,...
                                    preEventRole,...
                                    postEventRole,...
                                    startTime,...
                                    stopTime,...
                                    preEventEmissionInterval,...
                                    preEventSilenceInterval,...
                                    postEventEmissionInterval,...
                                    postEventSilenceInterval,...
                                    preEventStressDistribution,...
                                    preEventLoudnessDistribution,...
                                    postEventStressDistribution,...
                                    postEventLoudnessDistribution,...
                                    scheduleDuration,...
                                    timeOfEvent...
                                    )
            
            
            obj.name=name;
            obj.gender=gender;
            obj.category=category;
            obj.age=age;
            
            
            obj.preEventRole=preEventRole;
            obj.postEventRole=postEventRole;
            obj.startTime=startTime;
            obj.stopTime=stopTime;
            obj.preEventEmissionInterval=preEventEmissionInterval;
            obj.preEventSilenceInterval=preEventSilenceInterval;
            obj.postEventEmissionInterval=postEventEmissionInterval;
            obj.postEventSilenceInterval=postEventSilenceInterval;
            obj.preEventStressDistribution=preEventStressDistribution;
            obj.preEventLoudnessDistribution=preEventLoudnessDistribution;
            obj.postEventStressDistribution=postEventStressDistribution;
            obj.postEventLoudnessDistribution=postEventLoudnessDistribution;
            obj.timeOfEvent=timeOfEvent;
            obj.schedule=cell(0,0);
            obj.stress=obj.preEventStressDistribution(1,1);
            obj.loudness=obj.preEventLoudnessDistribution(1,1);
            
            obj.dT=0.1;
         end
         
         function generateSchedule(obj)
            t=obj.startTime;
            
            actionPreMute=AVSourceAction(0,obj.name,'mute','none',0);
            obj.schedule{end+1,1}=actionPreMute;
            
            roleChangeEmergencyActionScheduled=false;
            
            actionRoleChangeNormal=AVSourceAction(0,obj.name,'modify','role',obj.preEventRole);
            obj.schedule{end+1,1}=actionRoleChangeNormal;
            
            
            while t<obj.stopTime
                if t<obj.timeOfEvent
                    % this is pre event activation
                    
                    
                    
                    
                    % set emission period
                    emissionDuration=normrnd(...
                        obj.preEventEmissionInterval(1,1),...
                        obj.preEventEmissionInterval(1,2));
                    
                    div=emissionDuration/obj.dT;
                    div=round(div);
                    emissionDuration=div*obj.dT;
                    
                    emissionDuration=max(emissionDuration,obj.dT);
                    
                    if (t+emissionDuration>obj.timeOfEvent)
                        emissionDuration=obj.timeOfEvent-t;
                    end
                    
                    actionEmission=AVSourceAction(t,obj.name,'emit','none',0);
                    stress=min(max(normrnd(obj.preEventStressDistribution(1,1),...
                        obj.preEventStressDistribution(1,2)),0),1);
                    loudness=min(max(normrnd(obj.preEventLoudnessDistribution(1,1),...
                        obj.preEventLoudnessDistribution(1,2)),0),1);
                    
                    
                    actionStressLevel=AVSourceAction(t,obj.name,'modify','stress',stress);
                    actionLoudnessLevel=AVSourceAction(t,obj.name,'modify','loudness',loudness);
                    obj.schedule{end+1,1}=actionEmission;
                    obj.schedule{end+1,1}=actionStressLevel;
                    obj.schedule{end+1,1}=actionLoudnessLevel;
                    
                    % set silence period
                    silenceDuration=normrnd(...
                        obj.preEventSilenceInterval(1,1),...
                        obj.preEventSilenceInterval(1,2));
                    
                    
                    div=silenceDuration/obj.dT;
                    div=round(div);
                    silenceDuration=div*obj.dT;
                    silenceDuration=max(silenceDuration,obj.dT);
                    
                    if (t+silenceDuration>obj.timeOfEvent)
                        silenceDuration=obj.timeOfEvent-t;
                    end
                    
                    actionSilence=AVSourceAction(t+emissionDuration,obj.name,'mute','none',0);
                    obj.schedule{end+1,1}=actionSilence;
                    
                    
                    t=t+emissionDuration+silenceDuration;
                else
                    % this is post event activation
                    
                    if ~roleChangeEmergencyActionScheduled
                        actionRoleChangeEmergency=AVSourceAction(obj.timeOfEvent,obj.name,'modify','role',obj.postEventRole);
                        obj.schedule{end+1,1}=actionRoleChangeEmergency;
                     
                        actionAppearanceChangeEmergency=AVSourceAction(obj.timeOfEvent,obj.name,'modify','displayStatus','endangered');
                         obj.schedule{end+1,1}=actionAppearanceChangeEmergency;
                        roleChangeEmergencyActionScheduled=true;
                    end
                    
                    % set emission period
                    emissionDuration=normrnd(...
                        obj.postEventEmissionInterval(1,1),...
                        obj.postEventEmissionInterval(1,2));

                    div=emissionDuration/obj.dT;
                    div=round(div);
                    emissionDuration=div*obj.dT;
                    emissionDuration=max(emissionDuration,obj.dT);
                    
                    if (t+emissionDuration>obj.stopTime)
                        emissionDuration=obj.stopTime-t;
                    end
                    
                    actionEmission=AVSourceAction(t,obj.name,'emit','none',0);
                    
                    stress=min(max(normrnd(obj.postEventStressDistribution(1,1),...
                        obj.postEventStressDistribution(1,2)),0),1);
                    loudness=min(max(normrnd(obj.postEventLoudnessDistribution(1,1),...
                        obj.postEventLoudnessDistribution(1,2)),0),1);
                    
                    
                    actionStressLevel=AVSourceAction(t,obj.name,'modify','stress',stress);
                    actionLoudnessLevel=AVSourceAction(t,obj.name,'modify','loudness',loudness);
                    obj.schedule{end+1,1}=actionEmission;
                    obj.schedule{end+1,1}=actionStressLevel;
                    obj.schedule{end+1,1}=actionLoudnessLevel;
                    
                    
                    
                    
                    % set silence period
                    silenceDuration=normrnd(...
                        obj.postEventSilenceInterval(1,1),...
                        obj.postEventSilenceInterval(1,2));

                    
                    div=silenceDuration/obj.dT;
                    div=round(div);
                    silenceDuration=div*obj.dT;
                    silenceDuration=max(silenceDuration,obj.dT);
                    
                    if (t+silenceDuration>obj.stopTime)
                        silenceDuration=obj.stopTime-t;
                    end
                    
                    actionSilence=AVSourceAction(t+emissionDuration,obj.name,'mute','none',0);
                    obj.schedule{end+1,1}=actionSilence;
                    
                    t=t+emissionDuration+silenceDuration;
                end
                
            end
            
             
         end
         
         function plotSchedule(obj)
            
             str=sprintf('ID: %s (%s)',obj.name,obj.category);
             if ~(strcmp(obj.gender,'NA') && strcmp(obj.age,'NA'))
                str=sprintf('ID: %s (%s,%s,%d years)',obj.name,obj.category,obj.gender,obj.age);
             
             end
             title(str);
             hold on;
             t=0:obj.dT:obj.stopTime;
             activation=zeros(1,size(t,2));
             stressLevel=zeros(1,size(t,2));
             modSchedule={};
             for i=1:1:size(obj.schedule,1)
             
                if ~strcmp(obj.schedule{i,1}.parameter,'role') && ...
                   ~strcmp(obj.schedule{i,1}.parameter,'displayStatus') 
                   modSchedule{end+1,1}=obj.schedule{i,1}; 
                end
                
                
             end
             
             for i=2:4:size(modSchedule,1)
                 actionOn=modSchedule{i,1};
                 actionStress=modSchedule{i+1,1};
                 actionLoudness=modSchedule{i+2,1};
                 actionOff=modSchedule{i+3,1};
                 
                 activation(1,floor(actionOn.time/obj.dT):floor(actionOff.time/obj.dT))=actionLoudness.value;
                 stressLevel(1,floor(actionOn.time/obj.dT):floor(actionOff.time/obj.dT))=actionStress.value;
             end
             bar(t,activation,'FaceColor',[0.5,0.5,0.5],'EdgeColor',[0.5,0.5,0.5]);
             
             plot(t,stressLevel,'g','LineStyle',':','LineWidth',2);
             
             for i=1:1:size(obj.schedule,1)
             
                if strcmp(obj.schedule{i,1}.parameter,'role')
                    plot([obj.schedule{i,1}.time,obj.schedule{i,1}.time],[0,1.03],'LineWidth',3,'Color',[1,0,0]);
                    str=sprintf('role: %s',obj.schedule{i,1}.value);
                    text(obj.schedule{i,1}.time+0.01,1.2,str)
                end
             end
             
             
             hold off;
             xlim([0,400]);
             ylim([0,2]);
         end
    end
    
end

