function [correct] = plotCategorySensorySpace(category_infos, sensory_infos, params, ideal_observer, optimize, optim_grid_size)
%PLOTCATEGORYSENSORYSPACE make category_info vs sensory_info plots for the
%given params.

savedir = fullfile('+SamplingModel', 'figures');
if ~exist(savedir, 'dir'), mkdir(savedir); end

if nargin < 4, ideal_observer = false; end
if nargin < 5, optimize = []; end
if nargin < 6, optim_grid_size = 11; end

if ideal_observer && ~isempty(optimize)
    error('nothing to optimize for the ideal observer');
end

[ss, cc] = meshgrid(sensory_infos, category_infos);

% Preallocate return values.
correct = nan(size(ss));
optim_results = cell(numel(ss), 1);

optim_prefix = SamplingModel.getOptimPrefix(optimize, optim_grid_size);

parfor i=1:numel(ss)
    params_copy = params;
    % Set data-generating parameters.
    params_copy.sensory_info = ss(i);
    params_copy.category_info = cc(i);
    % Set variances for this pair of category- & sensory-info values. (That is, assume that the
    % model 'knows' the environment statistics)
    params_copy.var_s = SamplingModel.getEvidenceVariance(ss(i));
    params_copy.p_match = cc(i);
    
    % TODO - smarter setting of seed?
    params_copy.seed = randi(1000000000);
    
    % Run the model
    results_uid = SamplingModel.getModelStringID(params_copy, ideal_observer);
    if isempty(optimize)
        if ~ideal_observer
            results = LoadOrRun(@SamplingModel.runSamplingModelFast, {params_copy}, ...
                fullfile(params.save_dir, results_uid));
        else
            results = SamplingModel.runIdealObserver(params_copy);
        end
    else
        % Find optimal param settings.
        [optim_params, ~] = LoadOrRun(@SamplingModel.optimizeParams, ...
            {params_copy, optimize, optim_grid_size}, ...
            fullfile(params.save_dir, [optim_prefix '_' results_uid]));
        % Record optimal value of each optimized parameter.
        optim_results{i} = cellfun(@(v) optim_params.(v), optimize);
        % Get model results at the optimal param settings.
        best_results_uid = SamplingModel.getModelStringID(optim_params);
        results = LoadOrRun(@SamplingModel.runSamplingModelFast, {optim_params}, ...
            fullfile(params.save_dir, best_results_uid));
    end
    correct(i) = sum(results.choices == +1) / params.trials;
end

% Un-flatten optim_results
if ~isempty(optim_results)
    optim_results = reshape(vertcat(optim_results{:}), [size(ss) length(optimize)]);
end

% Plot percent correct
figure();
imagesc(correct, [0.5 1.0]); axis image; colorbar;
% Add contour line at threshold
hold on; contour(imfilter(correct, smoothkernel(9), 'replicate'), [0.7 0.7], '-w', 'LineWidth', 2);
category_tick_indices = round(linspace(1, length(category_infos), min(length(category_infos), 5)));
sensory_tick_indices = round(linspace(1, length(sensory_infos), min(length(sensory_infos), 5)));
set(gca, 'YTick', category_tick_indices);
set(gca, 'XTick', sensory_tick_indices);
set(gca, 'YTickLabel', arrayfun(@num2str, category_infos(category_tick_indices), 'UniformOutput', false));
set(gca, 'XTickLabel', arrayfun(@num2str, sensory_infos(sensory_tick_indices), 'UniformOutput', false));
set(gca, 'YDir', 'Normal');
xlabel('SI');
ylabel('CI');
title('Percent Correct');
if ~ideal_observer
    figname = sprintf('CSSpace_%dx%d_%s_vx%.2f_pC%.2f_gam%.2f_ns%d_nb%d_%d_%.2e.fig', ...
        params.trials, params.frames, optim_prefix, params.var_x, params.prior_C, ...
        params.gamma, params.samples, params.batch, params.importance_norm, params.noise);
else
    figname = sprintf('CSSpace_%dx%d_vx%.2f_ideal.fig', params.trials, params.frames, params.var_x);
end

saveas(gcf, fullfile(savedir, figname));

% Plot value of optimized parameters.
for i=1:length(optimize)
    figure();
    imagesc(optim_results); axis image; colorbar;
    category_tick_indices = round(linspace(1, length(category_infos), min(length(category_infos), 5)));
    sensory_tick_indices = round(linspace(1, length(sensory_infos), min(length(sensory_infos), 5)));
    set(gca, 'YTick', category_tick_indices);
    set(gca, 'XTick', sensory_tick_indices);
    set(gca, 'YTickLabel', arrayfun(@num2str, category_infos(category_tick_indices), 'UniformOutput', false));
    set(gca, 'XTickLabel', arrayfun(@num2str, sensory_infos(sensory_tick_indices), 'UniformOutput', false));
    set(gca, 'YDir', 'Normal');
    xlabel('SI');
    ylabel('CI');
    title(['Optimized value of ' optimize{i}]);
    figname = sprintf('CSSpace_optim_%s_%dx%d_vx%.2f_pC%.2f_gam%.2f_ns%d_nb%d_%d_%.2e.fig', ...
        optimize{i}, params.trials, params.frames, params.var_x, params.prior_C, ...
        params.gamma, params.samples, params.batch, params.importance_norm, params.noise);
    saveas(gcf, fullfile(savedir, figname));
end
end

function kernel = smoothkernel(n)
x = linspace(-2,2,n);
[xx,yy] = meshgrid(x,x);
kernel = exp(-(xx.^2 + yy.^2));
kernel = kernel / sum(kernel(:));
end