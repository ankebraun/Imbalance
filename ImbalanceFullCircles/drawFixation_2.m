function [ display ] = drawFixation( display, fix, dots )
% Fixation
% shape of the ABC (figure 1) in:
% Thaler, L., Sch?tz, a C., Goodale, M. a, & Gegenfurtner, K. R. (2013). 
% What is the best fixation target? The effect of target shape on stability
% of fixational eye movements. Vision research, 76, 31?42.

% cover the inner space for any stray dots
Screen('FillOval', display.h, display.black, [display.center(1)-dots.innerspace, ...
    display.center(2)- dots.innerspace*.8, display.center(1)+dots.innerspace*.8, display.center(2)+dots.innerspace*.8], ...
    dots.innerspace*.8); 

Screen('FillOval', display.h, fix.color, [display.center(1)-fix.circlesize/2, display.center(2)- fix.circlesize/2, display.center(1)+fix.circlesize/2, display.center(2)+fix.circlesize/2], fix.circlesize); 
Screen('DrawLine', display.h, display.black, display.center(1)-fix.circlesize/2, display.center(2), display.center(1)+fix.circlesize/2, display.center(2), fix.dotsize/4); 
Screen('DrawLine', display.h, display.black, display.center(1), display.center(2)-fix.circlesize/2, display.center(1), display.center(2)+fix.circlesize/2, fix.dotsize/4); 
% only the central dot changes color with feedback
Screen('FillOval', display.h, fix.color, [display.center(1)-fix.dotsize/2, display.center(2)- fix.dotsize/2, display.center(1)+fix.dotsize/2, display.center(2)+fix.dotsize/2], fix.dotsize); 

end

