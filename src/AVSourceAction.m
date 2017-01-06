
%--------------------------------------------------------------------------
% Class:                AVSourceAction
% Version:              1.0
% Last modification:    16.12.15
% Author:               T. Walther
%
% Description:
%   This class represents any action an audio-visual source can perform.
%--------------------------------------------------------------------------


classdef AVSourceAction < handle
    properties (Access=public)
        time;           % the trigger time for this action
        
        source;         % the action affects this source
        
        type;           % the type of this action, can currently be:
                        %   EMIT:   allow AV source to emit a sound
                        %   MUTE:   mutes the AV source
        
       
        parameter;      % the parameter to be modified
        value;          % the value for the modified parameter
    end
    
    methods
        % The constructor.
        % Inputs:
        %           time:           the time for the given action
        %           source:         action is for this source
        %           type:           the action's type, see above
        %           stimulusFile:   this stimulus will be played in case
        %                           of type=='EMIT'
        function obj=AVSourceAction(time,source,type,parameter,value)
            obj.time=time;
            obj.source=source;
            obj.type=type;
            obj.parameter=parameter;
            obj.value=value;
        end
    end
    
end

