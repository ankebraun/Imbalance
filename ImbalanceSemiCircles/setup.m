% Setup various options

options.num_trials = 56; % How many trials?
options.datadir = 'data/';
window = false;

options.dist = 75; % viewing distance in cm 
options.width = 52; %38; % physical width of the screen in cm
options.height = 29.5; %29; % physical height of the screen in cm
options.width = 52; %38; % Size of the not-cropped image
options.theight = 29.5; %29; % Size of the not-cropped image

% If I set the projector to zoom and use a 1920x1080 resolution on the
% stimulus PC I get a nice display -> The image is ten roughly 1450x1080
options.resolution = [1450, 1080];
% options.wdiff = (1920-options.resolution(1)) /2; this variable is not
% used


options.ppd = estimate_pixels_per_degree(options);
% Parameters for sampling the contrast + contrast noise
options.baseline_contrast = 0.5;
options.noise_sigmas = .1; %[.05 .1 .15];
%options.nsreverse = containers.Map(options.noise_sigmas, [1,2,3]);

options.ringwidth = options.ppd*3/4;
options.inner_annulus = 0; %1.5*options.ppd;
options.radius = 4*options.ppd; %4*options.ppd;
options.sigma = 75;
options.cutoff = 5.5;
%options.radius = deg2pix(options, 4);

% Should we repeat contrast levels? 1 = yes, 0 = no
options.repeat_contrast_levels = 1;


% QUEST Parameters
quest.pThreshold = .75; % Performance level and other QUEST parameters
quest.beta = 3.5;
quest.delta = 0.5/128;
quest.gamma = 0.15;
quest.threshold_guess = 0.025;
quest.threshold_guess_sigma = 0.25;

%options.beeps = {repmat(audioread('low_mrk_150Hz.wav'), 1,2)', repmat(audioread('high_mrk_350Hz.wav'), 1,2)', repmat(audioread('low_mrk_150Hz.wav'), 1,2)'}; %repmat(audioread('whitenoise250.wav'), 1,2)'};

beepIncorrect= MakeBeep(200,.150,44100);
beepCorrect= MakeBeep(1100,.150,44100);
beepLate = MakeBeep(150,.50,44100);
options.beeps = {repmat(beepIncorrect, 2, 1), repmat(beepCorrect, 2, 1), repmat(beepLate, 2,1)}; %repmat(audioread('whitenoise250.wav'), 1,2)'};


