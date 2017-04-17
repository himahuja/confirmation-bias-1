function [image_properties, eye_tracker_points, broke_fixation, quit] = trialStimuliGabor(Data, image_array, wPtr, tracker_info, settings)
% trialStimuli displays the animation of several gabor patches in quick
% succession to the subject, or runs through a single trial of the
% experiment.

image_properties = [];
frame_duration = 1 / Data.stimulus_fps;
quit = false;
eye_tracker_points = [];
broke_fixation = false;


%% Make sure to have left/right patch to match the orientations used
res = Data.screen_resolution;

% Create images to be displayed as left or right options
left_patch = squeeze(makeImages(Data.stim_size, 1, Data.left_category, Data.right_category, 1, 1)) * 10.0 + 127.0;
right_patch = squeeze(makeImages(Data.stim_size, 0, Data.left_category, Data.right_category, 1, 1)) * 10.0 + 127.0;

xc = settings.screenSize(3)/2; % Get the middle of the horizontal axis
yc = settings.screenSize(4)/2; % Get the middle of the vertical axis

black = [0 0 0];
gray = [127 127 127];

% Set up variables for keyboard functions
KbName('UnifyKeyNames');
exitKey = KbName(settings.keyExit);
leftKey = KbName(settings.keyLeft);
rightKey = KbName(settings.keyRight);

total_frames = Data.number_of_images + 1;

image_texture = zeros(1, total_frames);
for i = 1:Data.number_of_images
    large_image = imresize(squeeze(image_array(i, :, :)), Data.screen_resolution, 'nearest');
    image_texture(i) = Screen('MakeTexture', wPtr, large_image);
end
[~, h, w] = size(image_array);
noise_mask = 127 + randn(h * Data.screen_resolution, w * Data.screen_resolution) * Data.contrast(Data.current_trial);
image_texture(end) = Screen('MakeTexture', wPtr, noise_mask);

stimulus_bbox = ptbCenteredRect([xc, settings.screenSize(4)-3*size(large_image,1)], size(large_image));

Screen('FillRect', wPtr, gray);        % Make the background gray
[~, stimOnsetTime] = Screen('Flip', wPtr);

% Get fixation (takes a variable amount of time).
[is_fixating, tracker_info, eye_tracker_points] = EyeTracker.getFixation(tracker_info, wPtr, gray);

% If the subject never fixated, end the trial.
if ~is_fixating
    broke_fixation = true;
    return;
end

% Draw frame around where stimulus will appear as a timing cue (note:
% leaving fixation cue on the screen).
Screen('FillRect', wPtr, gray);
drawTrialNo();
EyeTracker.drawFixationSymbol(tracker_info, wPtr);
drawStimulusFrame(wPtr, black, stimulus_bbox, 20, 2);
[~, cueOnsetTime] = Screen('Flip', wPtr);

% Prep for first stimulus frame by clearing the drawStimulusFrame.
Screen('FillRect', wPtr, gray);
nextStimTime = cueOnsetTime + Data.cue_duration;

% Present each image for 'frame_duration' seconds.
% TODO - track eyes at full temporal resolution rather than once per frame.
for i = 1:total_frames
    EyeTracker.drawFixationSymbol(tracker_info, wPtr);
    gaze_point = EyeTracker.getGazePoint(tracker_info, 'pixels');
    % If fixation is broken at any time, end the trial.
    if ~EyeTracker.isFixation(tracker_info, gaze_point)
        broke_fixation = true;
        return;
    end
    % Get next eye tracker point.
    eye_tracker_points = vertcat(eye_tracker_points, [GetSecs()-stimOnsetTime gaze_point]);
    
    % Show stimulus.
    Screen('DrawTexture', wPtr, image_texture(i), [], stimulus_bbox); %Fill the buffer with the first texture
    [~, stimOnsetTime] = Screen('Flip', wPtr, nextStimTime);
    nextStimTime = stimOnsetTime + frame_duration;

    % (Maybe) end stimulus frame with some blank frames.
    if Data.blank_duration > 0
        EyeTracker.drawFixationSymbol(tracker_info, wPtr);
        Screen('FillRect', wPtr, gray, stimulus_bbox);
        Screen('Flip', wPtr, stimOnsetTime + frame_duration - Data.blank_duration);
    end
end

% Close textures to avoid memory problems.
for i = 1:total_frames
    Screen('Close', image_texture(i));
end

show_left_patch = Screen('MakeTexture', wPtr, imresize(left_patch, Data.screen_resolution, 'nearest'));
Screen('DrawTexture', wPtr, show_left_patch, [], [xc-res*4-200 yc-res*4 xc+res*4-200 yc+res*4]);   % xc, yc indicates the coordinates of the middle of the screen
show_right_patch = Screen('MakeTexture', wPtr, imresize(right_patch, Data.screen_resolution, 'nearest'));
Screen('DrawTexture', wPtr, show_right_patch, [], [xc-res*4+200 yc-res*4 xc+res*4+200 yc+res*4]);
Screen('DrawText', wPtr, sprintf('Current Trial - #%d', Data.current_trial), xc-600, yc+250, 0);   % Unobtrusive output to screen of the current trial number
Screen('Flip', wPtr);

[key, rt, timeout] = ptbWaitKey([leftKey, rightKey, exitKey], 1);

if key == exitKey
    quit = true;
    image_properties.choice = nan;
end

if timeout
    image_properties.choice = nan;
else
    image_properties.reaction = rt * 1000;
    if key == leftKey
        image_properties.choice = 1;
    elseif key == rightKey
        image_properties.choice = 0;
    end
end

function drawTrialNo()
    Screen('DrawText', wPtr, sprintf('Current Trial - #%d', Data.current_trial), xc-900, yc+550, 0);
end
end

function drawStimulusFrame(wPtr, color, bbox, length, lineWidth)
Screen('DrawLine', wPtr, color, bbox(1), bbox(2), bbox(1)+length, bbox(2), lineWidth);
Screen('DrawLine', wPtr, color, bbox(1), bbox(2), bbox(1), bbox(2)+length, lineWidth);
Screen('DrawLine', wPtr, color, bbox(1), bbox(4), bbox(1)+length, bbox(4), lineWidth);
Screen('DrawLine', wPtr, color, bbox(1), bbox(4), bbox(1), bbox(4)-length, lineWidth);
Screen('DrawLine', wPtr, color, bbox(3), bbox(2), bbox(3)-length, bbox(2), lineWidth);
Screen('DrawLine', wPtr, color, bbox(3), bbox(2), bbox(3), bbox(2)+length, lineWidth);
Screen('DrawLine', wPtr, color, bbox(3), bbox(4), bbox(3)-length, bbox(4), lineWidth);
Screen('DrawLine', wPtr, color, bbox(3), bbox(4), bbox(3), bbox(4)-length, lineWidth);
end