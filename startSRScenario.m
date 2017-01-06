



% This example demonstrates the capabilities of the S&R-rescue methods set up
% in WP4. To that end, a baseline visualizer (LVTE) shows the current scenario status in
% 2 dimensions from a bird's view. The robot is indicated as a blue star with
% a short line sketching the heading direction of the robotic device. Sound sources
% are displayed as red crosses, when they become active, they are enveloped with
% a blue circle. The current task of the robot is displayed in the figure's
% header, along with the current system time. Note: no actual audio processing
% is done in this example, this is left to the more powerful BEFT.
% The robot behaves as reported in D4.3, chapter 5, section 4 
% (please refer to this chapter for more information on
% the given scenario). While moving, the robot hypothesizes the positions of each
% accessible sound source, marking them with green asterisks. Once all sources
% have been locked, and the situation turns into a catastrophe setting, the robot
% starts to rescue all animate entities from the scene, as described in D4.3, section 5.4.
% The knowledge sources used in this S&R setting are the
% BindingKS, AuditoryObjectFormationKS, AuditoryMetaTaggingKS, HazardAssessmentKS, PlanningKS,
% which are described in detail in D4.3, sections 5.2 and 5.3. A more
% technical overview of these KSs can also be found in D6.1.3, section
% 3.4.4.
% Please note that the UpdateEnvironmentKS also used here was already described
% in D4.2, section. 2.2.1. Especially the PlanningKS can be modified to
% alter the robots behavior in the given scenario.



% Usage instructions:
% Just start the example by typing 'startSRScenario'. From here on,
% everything is automated: the scene is loaded from the given environment
% descriptor, the appropriate sound source activation schedule is loaded,
% and the simulation is started. You will then see the virtual robot from a
% bird's view perspective, performing the search-and-rescue task described
% in D4.3, section 5.4.  Note that the given scene is actually a
% proof of concept, following strictly the discussions in D4.3. To
% set up new scenarios and/or employ baseline sound processing with the SSR
% auralizer, please contact thomas.walther@rub.de for potential use of the
% more powerful BEFT, which, however, requires a non-trivial installation
% procedure.



% initialize the Two!Ears system
startFeedbackAndAttention();
startTwoEars();


% start the simulator with a JIDO simulation example
environment=VirtualEnvironment();
environment.startSession('environmentalData/scenarioA/envDescriptor.mat');
environment.loadSourceSchedules('environmentalData/scenarioA/scheduledSourcesA.mat');






environment.scenarioDuration=400;
% block the siren prior to robot triggering the alert
for i=1:size(environment.audioVisualSources,1)
    source=environment.audioVisualSources{i,1};
    name=source.name;
    if strcmp(name,'Source005')
        environment.audioVisualSources{i,1}.block=true;
    end
end
                     
                     
 % build blackboard
disp( 'Building blackboard system...' );
% no verbosity
bbs = BlackboardSystem(false);


% connect blackboard to the robot simulator
bbs.setRobotConnect(environment);
                             
% set up the knowledge sources
updateEnvironmentKS=bbs.createKS('UpdateEnvironmentKS',{bbs.robotConnect});
bindingKS=bbs.createKS('BindingKS',{bbs.robotConnect});
auditoryObjectFormationKS=bbs.createKS('AuditoryObjectFormationKS',{bbs.robotConnect});
auditoryMetaTaggingKS=bbs.createKS('AuditoryMetaTaggingKS',{bbs.robotConnect});
hazardAssessmentKS=bbs.createKS('HazardAssessmentKS',{bbs.robotConnect});
planningKS=bbs.createKS('PlanningKS',{bbs.robotConnect});



% set up the connectivity pattern for the blackboard schedule
bbs.blackboardMonitor.bind({bbs.scheduler},{updateEnvironmentKS},'replaceOld','AgendaEmpty');
bbs.blackboardMonitor.bind({updateEnvironmentKS},{bindingKS},'replaceOld');
bbs.blackboardMonitor.bind({bindingKS},{auditoryObjectFormationKS},'replaceOld');
bbs.blackboardMonitor.bind({auditoryObjectFormationKS},{auditoryMetaTaggingKS},'replaceOld');
bbs.blackboardMonitor.bind({auditoryMetaTaggingKS},{hazardAssessmentKS},'replaceOld');
bbs.blackboardMonitor.bind({hazardAssessmentKS},{planningKS},'replaceOld');


% start the blackboard system
bbs.run();

