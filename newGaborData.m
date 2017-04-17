function GaborData = newGaborData(varargin)

    function value = get_arg(name, default)
        % Helper function to get named arguments with a default
        idx = strcmpi(name, varargin);
        if any(idx)
            val_idx = find(idx)+1;
            value = varargin{val_idx};
            varargin(find(idx):val_idx) = [];
        else
            value = default;
        end
    end

%% User-settable params
GaborData.trials_per_block = get_arg('trials_per_block', 100);
GaborData.blocks = get_arg('blocks', 4);
GaborData.stair_fn = get_arg('stair_fn', @Staircase.contrast);
GaborData.reversals_per_epoch = get_arg('reversals_per_epoch', 6);

total_trials = GaborData.trials_per_block * GaborData.blocks;

% Initial values of staircase-able parameters
GaborData.contrast = zeros(1, total_trials);
GaborData.contrast(1) = get_arg('contrast', 32);
GaborData.ratio = zeros(1, total_trials);
GaborData.ratio(1) = get_arg('ratio', 0.8);
GaborData.noise = zeros(1, total_trials);
GaborData.noise(1) = get_arg('noise', 70); % stdev of bpg orientation band
GaborData.step_size = zeros(1, total_trials);

% Staircase bounds and step size, with defaults set depending on stair_fn
GaborData.model_observer = get_arg('model_observer', '');
if isequal(GaborData.stair_fn, @Staircase.contrast)
    GaborData.stair_bounds = get_arg('stair_bounds', [0 64]);
    GaborData.step_size(1) = get_arg('step_size', 2); % multiplicative (in the "easier" direction)
    GaborData.min_step_size = get_arg('min_step_size', 1+(GaborData.step_size(1) - 1)/4); % Default to two 'halvings' of the step size
elseif isequal(GaborData.stair_fn, @Staircase.ratio)
    GaborData.stair_bounds = get_arg('stair_bounds', [0.5 1.0]);
    GaborData.step_size(1) = get_arg('step_size', .1); % additive (in the "easier" direction)
    GaborData.min_step_size = get_arg('min_step_size', GaborData.step_size(1)/4); % Default to two 'halvings' of the step size
elseif isequal(GaborData.stair_fn, @Staircase.noise)
    GaborData.stair_bounds = get_arg('stair_bounds', [0 360]);
    GaborData.step_size(1) = get_arg('step_size', -20); % additive (in the "easier" direction)
    GaborData.min_step_size = get_arg('min_step_size', GaborData.step_size(1)/4); % Default to two 'halvings' of the step size
end

% Other misc. user-definable parameters relating to stimulus/rig.
GaborData.number_of_images = get_arg('number_of_images', 10);
GaborData.stimulus_fps = get_arg('stimulus_fps', 12);  % frame rate of stimuli
GaborData.blank_frames = get_arg('blank_frames', 2);  % number of blank screen frames per stimulus frame
GaborData.cue_duration = get_arg('cue_duration', 0.2);  % Fixed duration, seconds to display cue after getting fixation.
GaborData.left_category = get_arg('left_category', +45);
GaborData.right_category = get_arg('right_category', -45);
% BPG Stimulus parameters
GaborData.stim_size = get_arg('stim_size', 300);  % Size of the image along x-axis
GaborData.stim_std_ori_deg = get_arg('stim_std_ori_deg', 70);  % standard-deviation of orientations present in image (analogous to pixel noise)
GaborData.stim_sp_freq_cycles = get_arg('stim_sp_freq_cycles', 6);  % Mean spatial frequency of images in cycles.
GaborData.stim_std_sp_freq_cycles = get_arg('stim_std_sp_freq_cycles', 10);  % Std deviation of spatial frequency in cycles.

GaborData.stim_sp_freq_cpp = GaborData.stim_sp_freq_cycles / GaborData.stim_size;
GaborData.stim_std_sp_freq_cpp = GaborData.stim_std_sp_freq_cycles / GaborData.stim_size;

% Preallocate fields that will be populated with data by running the
% experiment.
GaborData.seed = zeros(1, total_trials);
GaborData.streak = zeros(1, total_trials);
GaborData.reversal_counter = zeros(1, total_trials);
GaborData.correct_answer = zeros(1, total_trials);
GaborData.ideal_answer = zeros(1, total_trials);
GaborData.reaction_time = zeros(1, total_trials);
GaborData.choice = zeros(1, total_trials);
GaborData.accuracy = zeros(1, total_trials);
GaborData.frame_categories = zeros(total_trials, GaborData.number_of_images);
GaborData.ideal_frame_signals = zeros(total_trials, GaborData.number_of_images);

GaborData.current_trial = 0;

GaborData.eye_tracker_points = {};

if ~isempty(varargin)
    warning('Unkown arguments given to newGaborParams');
end

% Sanity checks for common "gotchas"
if ~isempty(GaborData.model_observer) && ~isempty(GaborData.stair_fn)
    warning('Model observer with a staircase?');
end

if isequal(GaborData.stair_fn, @Staircase.ratio)
    if GaborData.step_size(1) < 0
        warning('Changing sign of ratio step_size from %d to %d', GaborData.step_size(1), -GaborData.step_size(1));
        GaborData.step_size = -GaborData.step_size;
    end
end

if isequal(GaborData.stair_fn, @Staircase.noise)
    if GaborData.step_size(1) > 0
        warning('Changing sign of noise step_size from %d to %d', GaborData.step_size(1), -GaborData.step_size(1));
        GaborData.step_size = -GaborData.step_size;
    end
end

if isequal(GaborData.stair_fn, @Staircase.contrast)
    if GaborData.step_size(1) < 0
        error('Contrast staircase is multiplicative; step size of %f doesn''t make sense', GaborData.step_size(1));
    elseif GaborData.step_size(1) < 1
        warning('Chaning contrast step_size < 1 to 1/step_size');
        GaborData.step_size(1) = 1 / GaborData.step_size(1);
    end
end

if GaborData.ratio(1) > 1 || GaborData.ratio(1) < 0
    error('Ratio should be between 0 and 1');
end

if ~isempty(GaborData.model_observer) && ~any(strcmpi(GaborData.model_observer), {'ideal'})
    warning('%s is not a known model observer', GaborData.model_observer);
end

disp(GaborData);

end