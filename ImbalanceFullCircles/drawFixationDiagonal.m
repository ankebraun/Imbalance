function [ display ] = drawFixationDiagonal( display, windowRect, fix )
% Fixation

%X = display.center(1);
%Y = display.center(2);
[X, Y] = RectCenter(windowRect);

%%%% ASK: How do we account for changes in color of fixation cross? Does
%%%% that change the luminance?

% Here we set the size of the arms of our fixation cross
fixCrossDimPix = sqrt(25/2);
% Now we set the coordinates (these are all relative to zero we will let
% the drawing routine center the cross in the center of our monitor for us)
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];

%xCoords = [-fixCrossDimPix fixCrossDimPix fixCrossDimPix -fixCrossDimPix];
%yCoords = [fixCrossDimPix -fixCrossDimPix fixCrossDimPix -fixCrossDimPix];
allCoords = [xCoords];% yCoords];

% Set the line width for our fixation cross
lineWidthPix = 2;
% Draw the fixation cross in white, set it to the center of our screen and
% set good quality antialiasing
Screen('DrawLines', display, allCoords,...
    lineWidthPix, fix.color, [X Y]);

end