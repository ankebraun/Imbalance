%% Imbalance experiment
%
% Runs one block of the imbalance experiment.
%
clearvars; 
close all; 
dbstop if error;
sca
% Close audio device, shutdown driver:
PsychPortAudio('Close');

%% Global parameters.
rng('shuffle')

setup; % load setup parameters
setup.do_trigger = false;% set to true if scanning in the EEG lab to send triggers
setup.Eye = false; % set to true if using Eyelink
if setup.do_trigger
    addpath matlabtrigger/
else
   addpath faketrigger/
end

%% Setup the ParPort
trigger_enc = setup_trigger;
%setup_parport;

%% Ask for some subject details
%-------------
% Ask for subject number, default = 100
%-------------
setup.participant       = input('Participant number? ');
if isempty(setup.participant)
    setup.participant   = 100; %test
end
%-------------
% Ask for session number, default = 0
%-------------
setup.session           = input('Session? ');
if isempty(setup.session)
    setup.session       = 0; %test
end
%-------------
% Ask for run number, default = 1
%-------------
setup.run               = input('Run? ');
if isempty(setup.run)
    setup.run           = 1; 
end    

setup.nblocks = 6;
% on half of the blocks the side with the stronger contrast will be chosen at random on the other half it will be repeated with 80% probability (i.e. alternated with 20% probability)
if exist(sprintf('trans_prob_counter_P%d_s%d.mat', setup.participant, setup.session), 'file') == 2,
    load(sprintf('trans_prob_counter_P%d_s%d.mat', setup.participant, setup.session));
    setup.transition_probability = trans_probs_counter(setup.run); 
else 
    trans_probs_counter = [0.2 0.5 0.2 0.5 0.2 0.5];
    trans_probs_counter = trans_probs_counter(:, randperm(size(trans_probs_counter,2)));
    filename_prob_counter = sprintf('trans_prob_counter_P%d_s%d.mat', setup.participant, setup.session);
    save(filename_prob_counter, '-mat', 'trans_probs_counter');
    setup.transition_probability = trans_probs_counter(setup.run); 
end    
% create matrix with repetition probabilities 
% diagonal elements: repetition of side with stronger contrast 
% off-diagonal elements: alternation of side with stronger contrast
if setup.transition_probability == 0.2,
    setup.transition_probabilities = [0.8 0.2; 0.2 0.8];
elseif setup.transition_probability == 0.5,
    setup.transition_probabilities = [0.5 0.5; 0.5 0.5];
end

side = NaN(setup.nblocks, options.num_trials);
% for the first trial of each block, randomly choose side with the stronger contrast 
starting_value(setup.run) = randi(2,1);
side(setup.run,1) = starting_value(setup.run);
% for all other trials, choose the side with the stronger contrast depending on the transition probability of the current run via a Markov process
for trial = 2:options.num_trials
    setup.this_step_distribution = setup.transition_probabilities(side(setup.run,trial-1),:);
    setup.cumulative_distribution = cumsum(setup.this_step_distribution);
    r = rand(1);
    side(setup.run,trial) = find(setup.cumulative_distribution>r, 1);
end

for trial = 1:options.num_trials
    if side(setup.run,trial) == 1,
        side(setup.run,trial)=-1;
    elseif side(setup.run,trial) == 2,
        side(setup.run,trial) = 1;
    end
end
    


try    
    options.datadir = fullfile(options.datadir, num2str(setup.participant));
    [~, ~, ~] = mkdir(options.datadir);
    quest_file = fullfile(options.datadir, 'quest_results.mat');
    session_struct = struct('q', [], 'results', [], 'date', datestr(clock));
    results_struct = session_struct;
    session_identifier =  datestr(now, 30);
    
    % load quest parameters
    append_data = false;
    if exist(quest_file, 'file') == 2
        if strcmp(input('There is previous data for this subject. Load last QUEST parameters? [y/n] ', 's'), 'y')
            [~, results_struct, quest.threshold_guess, quest.threshold_guess_sigma] = load_subject(quest_file);
            append_data = true;
        end
    end
    
    fprintf('QUEST Parameters\n----------------\nThreshold Guess: %1.4f\nSigma Guess: %1.4f\n',...
        quest.threshold_guess, quest.threshold_guess_sigma)

    if ~strcmp(input('OK? [y/n] ', 's'), 'y')
        throw(MException('EXP:Quit', 'User request quit'));
    end
    
    setup_ptb;
    [tw, th] = Screen('WindowSize', window); %Get width and height of screen

    opts = {'duration', .1,... %duration of each contrast sample in s
        'ppd', options.ppd,... %pixels per degree
        'xpos', [-(tw/options.ppd)/6 (tw/options.ppd)/6],... %[-(tw/options.ppd)/24 (tw/options.ppd)/24],... %horizontal postion of the two gratings from center of the screen
        'ypos', [0, 0]}; %vertical postion from center
    
    %-------------
    % Present instructions on the screen
    %-------------
    white = WhiteIndex(screenNumber);
    line1 = 'Schauen Sie immer auf das Fixierungskreuz! \n  \n';
    line2 = 'Antworten Sie erst nachdem die beiden Gitter vom Bildschirm verschwunden sind. \n  \n';
    line3 = 'Drücken Sie y, falls der Kontrast des linken Gitters stärker ist. \n  \n';
    line4 = 'Drücken Sie m, falls der Kontrast des rechten Gitters stärker ist. \n  \n';
    line5 = 'Falls Sie richtig geantwortet haben, hören Sie einen kurzen, hohen Ton. \n \n';
    line6 = 'Falls Sie falsch geantwortet haben, hören Sie einen kurzen, tiefen Ton. \n \n';
    line7 = 'Falls Sie zu früh oder zu spät geantwortet haben, hören Sie einen langen, tiefen Ton. \n \n';
    line8 = 'Versuchen Sie nicht zu blinzeln solange das Kreuz ROT ist. \n  \n';
    line9 = 'Wenn das Kreuz BLAU ist, dürfen Sie blinzeln. \n \n';
    line10 = 'Drücken Sie eine Taste, um zu beginnen.';
    DrawFormattedText(window, [line1 line2 line3 line4 line5 line6 line7 line8 line9 line10],...
        'center', 'center', white);
    Screen('Flip', window);
    % Wait for key press
    WaitSecs(.1); KbWait(); WaitSecs(.1);

    %% Configure Psychtoolbox
    % start recording eye position
    if setup.Eye,
        Eyelink('StartRecording');
        % record a few samples before we actually start displaying
        WaitSecs(0.1);
        % mark zero-plot time in data file
        Eyelink('message', 'Start recording Eyelink');
    end
    %% Set up QUEST
    q = QuestCreate(quest.threshold_guess, quest.threshold_guess_sigma, quest.pThreshold, quest.beta, quest.delta, quest.gamma);
    q.updatePdf = 1;
    
    % A structure to save results.
    results = struct('response', [], 'side', [], 'choice_rt', [], 'correct', [],...
        'contrast', [], 'contrast_left', [], 'contrast_right', [],...
        'repeat', [], 'repeated_stim', [], 'session', [], 'run', [], 'noise_sigma', [], 'expand', [], 'transition_probability', []);

    % Sometimes we want to repeat the same contrast fluctuations, load them
    % here. You also need to set the repeat interval manually. The repeat
    % interval specifies the interval between repeated contrast levels.
    % If you want to show each of, e.g. 5 repeats twice and you have 100
    % trials, set it to 10.
    options.repeat_contrast_levels = 0;
    if options.repeat_contrast_levels
        contrast_file_name = fullfile(options.datadir, 'repeat_contrast_levels.mat');
        repeat_levels = load(contrast_file_name, 'levels');
        repeat_levels = repeat_levels.levels;
        % I assume that repeat_contrast_levels contains a struct array with
        % fields contrast_a and contrast_b.
        assert(options.num_trials > length(repeat_levels));
        repeat_interval = 2; %'Replace with a sane value'; % <-- Set me!
        repeat_counter = 1;
    end
    %% Do Experiment
    for trial = 1:options.num_trials
        try
            if setup.Eye,
                % This supplies the title at the bottom of the eyetracker display
                Eyelink('command', 'record_status_message "TRIAL %d/%d"', trial, options.num_trials);
                Eyelink('message', 'TRIALID %d', trial);
            end
            repeat_trial = false;
            repeated_stim = nan;
            
            % Sample contrasts.
            high_coh_trials = [randi([1 options.num_trials], [1,round(options.num_trials*0.15)])]; % 15% high coherence trials chosen at random
            if ismember(trial, high_coh_trials)
                contrast = 0.5;
            else    
                contrast = min(1, max(0, (QuestQuantile(q, 0.5))));
            end
            noise_sigma = options.noise_sigmas; % standard deviation of the normal distribution of contrast levels
            [contrast_small, contrast_large] = sample_contrast(contrast, noise_sigma, options.baseline_contrast);  
            if side(setup.run,trial) == -1
                contrast_left = contrast_large;
                contrast_right = contrast_small;
            else
                contrast_left = contrast_small;
                contrast_right = contrast_large;
            end

            expand = randsample([-1, 1], 1); %randomly choose whether circular gratings are expanding or contracting
            fprintf('Correct is: %i, mean contrast is %f\n', side(setup.run, trial), mean(contrast))
            % Set options that are valid only for this trial.
            trial_options = [opts, {...
                'contrast_left', contrast_left,...
                'contrast_right', contrast_right,...
                'baseline_delay', 0.75 + 0.75*rand,... 
                'post_response_delay', 0.75 + 0.75*rand,...
                'feedback_delay', 0.75 + 0.75*rand,...                
                'rest_delay', 3.5 + 1*rand,...
                'ringwidth', options.ringwidth,...
                'radius', options.radius,...
                'inner_annulus', options.inner_annulus,...
                'sigma', options.sigma,...
                'cutoff', options.cutoff,...
                'expand', expand,...
                'kbqdev', options.kbqdev}];
            
            % Encode trial number in triggers.
            bstr = dec2bin(trial, 8);
            pins = find(str2num(reshape(bstr',[],1))');
            WaitSecs(0.005);
            for pin = pins
                trigger(pin);
                WaitSecs(0.005);
            end
            [correct, response, rt_choice, timing] = one_trial(setup, window, options.window_rect,...
                screenNumber, side(setup.run,trial), ringtex, audio, trigger_enc, options.beeps, options.ppd, trial_options);
            
            timings{trial} = timing;
            if ~isnan(correct) && ~repeat_trial
              %   q = QuestUpdate(q, contrast + mean(noise_sigma), correct);
                 q = QuestUpdate(q, contrast, correct);                 
            end
             
             results(trial) = struct('response', response, 'side', side(setup.run,trial), 'choice_rt', rt_choice, 'correct', correct,...
                'contrast', contrast, 'contrast_left', contrast_left, 'contrast_right', contrast_right,...
                'repeat', repeat_trial, 'repeated_stim', repeated_stim,...
                'session', setup.session, 'run', setup.run, 'noise_sigma', noise_sigma, 'expand', expand, 'transition_probability', setup.transition_probability);
           
            if setup.Eye,
                Eyelink('message', 'TRIALEND %d', trial);
            end
        catch ME
            if (strcmp(ME.identifier,'EXP:Quit'))
                break
            else
                rethrow(ME);
            end
        end
    end
 catch ME
    if (strcmp(ME.identifier,'EXP:Quit'))
        return
    else
        disp(getReport(ME,'extended'));
        if setup.Eye,
            Eyelink('StopRecording');    
        end
        Screen('LoadNormalizedGammaTable', window, old_gamma_table);

        rethrow(ME);
    end
end
if setup.Eye,
    Eyelink('StopRecording');        
end
LoadIdentityClut(window);
PsychPortAudio('Close');
sca
fprintf('Saving data to %s\n', options.datadir)
if setup.Eye
    eyefilename   = fullfile(options.datadir, sprintf('%s_%s.edf', setup.participant, session_identifier));
    Eyelink('CloseFile');
    Eyelink('WaitForModeReady', 500);
    try
        status = Eyelink('ReceiveFile', options.edfFile, eyefilename);
        disp(['File ' eyefilename ' saved to disk']);
    catch
        warning(['File ' eyefilename ' not saved to disk']);
    end

    Eyelink('StopRecording');
end
session_struct.q = q;
session_struct.results = struct2table(results);
%session_struct.results = results;

save( fullfile(options.datadir, sprintf('P%s_s%s_r%s_%s_results.mat', num2str(setup.participant), num2str(setup.session), num2str(setup.run), datestr(clock))), 'session_struct')
if ~append_data
    results_struct = session_struct;
else
    disp('Trying to append')
    results_struct(length(results_struct)+1) = session_struct;
end
save(fullfile(options.datadir, 'quest_results.mat'), 'results_struct')
%writetable(session_struct.results, fullfile(datadir, sprintf('%s_%s_results.csv', initials, datestr(clock))));
