classdef envDescriptor
   %    This class is a description of the complete data used for setting
   %    up the virtual environment. It can be used to store a complete
   %    description of the enviornment for later use in simplified
   %    emulators, e.g., the LVTE
   
    properties (Access = public)
        AVSources;      % all audio visual sources
        ObstaclePlan;   % all obstacles, free tiles, etc.
        DimX;           % the scenario's x dimension
        DimY;           % the scenario's y dimension
        dx;             % the x-size of each floor tile
        dy;             % the y-size of each floor tile
        ofsX;           % the x offset of the ground plane
        ofsY;           % the y offset of the ground plane
        robotPose;      % the robot's initial pose
    end
    
    methods
    end
    
end

