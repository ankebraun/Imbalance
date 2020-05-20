function [correct, response, rt_choice, timing] = one_trial(setup, window, windowRect, screen_number, correct_location, ringtex, pahandle, trigger_enc, beeps, ppd, variable_arguments)
%% function [correct, response, confidence, rt_choice, rt_conf] = one_trial(window, windowRect, screen_number, correct_location, gabortex, gaborDimPix, pahandle, variable_arguments)
%
% Presents two circular contracting/expanding grating with changing contrast. Ask for which grating has stronger contrast.
%
% Parameters
% ----------
%
% window : window handle to draw into
% windowRect : dimension of the window
% screen_number : which screen to use
% correct_location : 1 if correct is right, -1 if left
% ringtex : the ring texture to draw
% pahandle : audio handle
%
% Variable Arguments
% ------------------
%
% ringwidth : spatial frequency of the grating
% contrast_left : array of contrast values for the left grating
% contrast_right : array of contrast values for the right grating
% driftspeed : how fast the gratings drift (units not clear yet)
% ppd : pixels per degree to convert to visual angles
% duration : how long each contrast level is shown in seconds
% baseline_delay : delay between trial start and stimulus onset.
% feedback_delay : delay between confidence response and feedback onset
% rest_delay : delay between feedback onset and trial end



%% Process variable input stuff
radius = default_arguments(variable_arguments, 'radius', 150);
inner_annulus = default_arguments(variable_arguments, 'inner_annulus', 5);
ringwidth = default_arguments(variable_arguments, 'ringwidth', 25);
sigma = default_arguments(variable_arguments, 'sigma', 2*ppd);
cutoff = default_arguments(variable_arguments, 'cutoff', 2*ppd);

contrast_left = default_arguments(variable_arguments, 'contrast_left', [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]/10.);
contrast_right = default_arguments(variable_arguments, 'contrast_right', [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]/10.);
xpos = default_arguments(variable_arguments, 'xpos', [-15, 15]);
ypos = default_arguments(variable_arguments, 'ypos', [0, 0]);

driftspeed = default_arguments(variable_arguments, 'driftspeed', 1);
duration = default_arguments(variable_arguments, 'duration', .5);
baseline_delay = default_arguments(variable_arguments, 'baseline_delay', 0.75);
post_response_delay = default_arguments(variable_arguments, 'post_response_delay', 0.75);
feedback_delay = default_arguments(variable_arguments, 'feedback_delay', 0.5);
rest_delay = default_arguments(variable_arguments, 'rest_delay', 1.5);
expand = default_arguments(variable_arguments, 'expand', 1);
kbqdev = default_arguments(variable_arguments, 'kbqdev', []);


%% Setting the stage
timing = struct();

% keys for response
left = 'z';
right = 'm';
quit = 'ESCAPE';

black = BlackIndex(screen_number);

xpos = xpos*ppd;
ypos = ypos*ppd;
[xCenter, yCenter] = RectCenter(windowRect);
xpos = xpos + xCenter;
ypos = ypos + yCenter;

rgb2ntsc_matrix = [0.299 0.587 0.114; 0.596 -0.274 -0.322; 0.211 -0.523 0.312];

red = [1; 0; 0];
blue = [0; 0; 1];
green = [0; 1; 0];

red2 = rgb2ntsc_matrix*red;
blue2 = rgb2ntsc_matrix*blue;
green2 = rgb2ntsc_matrix*green;

r1 = red2(1);
r2 = red2(2);
r3 = red2(3);

b1 = blue2(1);
b2 = blue2(2);
b3 = blue2(3);

g1 = green2(1);
g2 = green2(2);
g3 = green2(3);

red = inv(rgb2ntsc_matrix)*[r1; r2; r3];
blue = inv(rgb2ntsc_matrix)*[r1; b2; b3];
green = inv(rgb2ntsc_matrix)*[r1; g2; g3];



ifi = Screen('GetFlipInterval', window);

%% Baseline Delay period

% Draw the fixation point
fix.color = red; % get ready
window      = drawFixation(window, windowRect, fix); % fixation
Screen('DrawingFinished', window); % helps with managing the flip performance
vbl = Screen('Flip', window);

% Screen('DrawDots', window, [xCenter; yCenter], 10, green, [], 1);
% vbl = Screen('Flip', window);
timing.TrialOnset = vbl;

trigger(trigger_enc.trial_start);
WaitSecs(0.005);
if correct_location == 1
    trigger(trigger_enc.stim_strong_right); % Right correct
elseif correct_location == -1
    trigger(trigger_enc.stim_strong_left); % Left correct
end
WaitSecs(0.005);
%trigger(trigger_enc.noise_sigma);% + ns);
%WaitSecs(0.001);
waitframes = (baseline_delay-0.01)/ifi;

flush_kbqueues(kbqdev);

%% Animation loop
start = nan;
cnt = 1;
framenum = 1;
dynamic = [];
stimulus_onset = nan;
[low_left, high_left] = contrast_colors(contrast_left(cnt), 0.5);
[low_right, high_right] = contrast_colors(contrast_right(cnt), 0.5);
%cnt = cnt+1;
shiftvalue = 0;


eff_radius = radius + cutoff * sigma;
while ~((GetSecs - stimulus_onset) >= (length(contrast_left))*duration-2*ifi) 
    % Set the right blend function for drawing the gabors
    Screen('BlendFunction', window, 'GL_ONE', 'GL_ZERO');
%    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

    Screen('DrawTexture', window, ringtex, [], [], [], [], [], low_left, [], [],...
       [high_left(1), high_left(2), high_left(3), high_left(4), shiftvalue, ringwidth, radius, inner_annulus, sigma, cutoff, xpos(1), yCenter]);

    Screen('DrawTexture', window, ringtex, [], [], [], [], [], low_right, [], [],...
       [high_right(1), high_right(2), high_right(3), high_right(4), shiftvalue, ringwidth, radius, inner_annulus, sigma, cutoff, xpos(2), yCenter]);    
    
    shiftvalue = shiftvalue+expand*driftspeed;
    % Change the blend function to draw an antialiased fixation point
    % in the centre of the array
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
    % Draw the fixation point
    fix.color = red; % get ready
    window      = drawFixation(window, windowRect, fix); % fixation
    Screen('DrawingFinished', window); % helps with managing the flip performance
    
%     imageArray = Screen('GetImage', window);
%     % imwrite is a Matlab function, not a PTB-3 function
%     imwrite(imageArray, 'FullCircles.jpg')

    % Flip our drawing to the screen
    vbl = Screen('Flip', window, vbl + (waitframes-.5) * ifi);
    flush_kbqueues(kbqdev);
    
    if framenum == 1
        if setup.Eye
            Eyelink('message', 'SYNCTIME');
            Eyelink('message', 'stim_onset 1');           
        end
        trigger(trigger_enc.stim_onset);
        WaitSecs(0.001);
    end
    framenum = framenum +1;
    waitframes = 1;
    dynamic = [dynamic vbl];
    
    % Change contrast every 100ms
    elapsed = GetSecs;
    if isnan(start)
        stimulus_onset = GetSecs;
        if setup.Eye
            Eyelink('message', sprintf('conrast left %f, contrast right %f',contrast_left(cnt), contrast_right(cnt)));
        end
        trigger(trigger_enc.con_change);
        start = GetSecs;
    end
    if (elapsed-start) > (duration-.5*ifi)
        start = GetSecs;        
        cnt = cnt+1;
        [low_left, high_left] = contrast_colors(contrast_left(cnt), 0.5);
        [low_right, high_right] = contrast_colors(contrast_right(cnt), 0.5);
        trigger(trigger_enc.con_change);
        if setup.Eye
            Eyelink('message', sprintf('conrast left %f, contrast right %f',contrast_left(cnt), contrast_right(cnt)));
        end
    end
    
end

target = (waitframes - 0.5) * ifi;
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
timing.animation = dynamic;

%%% Get choice
% Draw the fixation point
fix.color = red; % get ready
window      = drawFixation(window, windowRect, fix); % fixation
Screen('DrawingFinished', window); % helps with managing the flip performance
vbl = Screen('Flip', window, vbl + target );

trigger(trigger_enc.decision_start);
if setup.Eye
    Eyelink('message', 'decision_start 1');
end
timing.response_cue = vbl;
start = GetSecs;
rt_choice = nan;
key_pressed = false;
error = false;
response = nan;
RT = nan;
while (GetSecs-start) < 3
    [keyIsDown, firstPress] = check_kbqueues(kbqdev);
    if keyIsDown
        RT = GetSecs();
        keys = KbName(firstPress);
        if iscell(keys)
            error = true;
            break
        end
        switch keys
            case quit
                throw(MException('EXP:Quit', 'User request quit'));
            case {left, 'y'}
                if setup.Eye
                    Eyelink('message', sprintf('decision %i', trigger_enc.left_resp))
                end
                trigger(trigger_enc.left_resp);
                response = -1;
            case {right, 'm'}
                if setup.Eye
                    Eyelink('message', sprintf('decision %i', trigger_enc.right_resp));
                end
                trigger(trigger_enc.right_resp);
                response = 1;          
        end
        if ~isnan(response)
            if correct_location == response
                correct = 1;
                if setup.Eye
                    Eyelink('message', sprintf('decision %i', trigger_enc.correct_resp))
                end
                trigger(trigger_enc.correct_resp);
                fprintf('Choice Correct\n')
            else
                correct = 0;
                if setup.Eye
                    Eyelink('message', sprintf('decision %i', trigger_enc.error_resp))
                end
                trigger(trigger_enc.error_resp);                  
                fprintf('Choice Wrong\n')
            end
            rt_choice = RT-start;
            key_pressed = true;
            break;
        end
    end
end
timing.RT = RT;


if ~key_pressed || error
    trigger(trigger_enc.no_decisions);
    if setup.Eye
        Eyelink('message', 'decision 88');
    end
    fprintf('Error in answer\n')
%    wait_period = 1 + feedback_delay + rest_delay;
%    WaitSecs(wait_period);
    correct = nan;
    response = nan;
    rt_choice = nan;
    trigger(trigger_enc.trial_end);
%    return
end



%% Provide Feedback
if ~isnan(correct)
    beep = beeps{correct+1};
else
    beep = beeps{3};
end

PsychPortAudio('FillBuffer', pahandle.h, beep);
timing.post_response_delay_start = vbl;
fix.color = red; 
window      = drawFixation(window, windowRect, fix); % fixation
Screen('DrawingFinished', window); % helps with managing the flip performance
waitframes = (post_response_delay/ifi) - 1;
%startCue = vbl + post_response_delay;
vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
t1 = PsychPortAudio('Start', pahandle.h, 1, 0, 1);
if ~isnan(correct)
    if correct
        trigger(trigger_enc.feedback_correct);
        if setup.Eye
            Eyelink('message', 'feedback 1');
        end
    else
        trigger(trigger_enc.feedback_incorrect);
        if setup.Eye
            Eyelink('message', 'feedback -1');
        end
    end
else
    trigger(trigger_enc.feedback_late);
    if setup.Eye
        Eyelink('message', 'feedback 2');
    end
end
timing.feedback_start = t1;

% Wait for the beep to end. Here we use an improved timing method suggested
% by Mario.
% See: https://groups.yahoo.com/neo/groups/psychtoolbox/conversations/messages/20863
% For more details.
%%%%%
[actualStartTime, ~, ~, estStopTime] = PsychPortAudio('Stop', pahandle.h, 1, 1);
timing.feedback_delay_stop = estStopTime;
fix.color = red; % get ready
window      = drawFixation(window, windowRect, fix); % fixation
Screen('DrawingFinished', window); % helps with managing the flip performance
waitframes = (feedback_delay/ifi) - 1;
vbl = Screen('Flip', window, estStopTime + (waitframes - 0.5) * ifi);

fix.color = blue; % get ready
window      = drawFixation(window, windowRect, fix); % fixation
Screen('DrawingFinished', window); % helps with managing the flip performance
vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
waitframes = (rest_delay/ifi);
fix.color = red; % get ready
window      = drawFixation(window, windowRect, fix); % fixation
Screen('DrawingFinished', window); % helps with managing the flip performance
vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
timing.trial_end = vbl;
trigger(trigger_enc.trial_end );