function [weights, errors, pk_id] = loadOrRunModelPK(stringID, data, ...
    results, pk_hprs, recompute)

if nargin < 5, recompute = false; end

hpr_ridge = pk_hprs(1);
hpr_ar1 = pk_hprs(2);
hpr_curvature = pk_hprs(3);

datadir = fullfile('+Model', 'saved results');
if ~exist(datadir, 'dir'), mkdir(datadir); end

pk_id = ['PK_' sprintf('r%.2f_ar1%.2f_c%.2f', hpr_ridge, hpr_ar1, hpr_curvature) '__' stringID];
savename = [pk_id '.mat'];
savefile = fullfile(datadir, savename);

if exist(savefile, 'file') && ~recompute
    disp(['Loading precomputed results from ' savename]);
    contents = load(savefile);
    weights = contents.weights;
    errors = contents.errors;
else
    disp(['Computing new results for ' savename]);
    [weights, ~, errors] = CustomRegression.PsychophysicalKernel(data, ...
        results.choices == +1, hpr_ridge, hpr_ar1, hpr_curvature);
    save(savefile, 'weights', 'errors');
end
end