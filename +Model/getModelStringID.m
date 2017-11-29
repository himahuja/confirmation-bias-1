function name = getModelStringID(params, ideal_observer)
if nargin < 2, ideal_observer = false; end
if ~ideal_observer
    name = sprintf('%dx%d_cinfo%.3f_sinfo%.3f_ve%.2f_vx%.2f_pm%.2f_pC%.2f_gam%.2f_ns%d_b%d', ...
        params.trials, params.frames, params.category_info, ...
        params.sensory_info, params.var_e, params.var_x, params.p_match, ...
        params.prior_C, params.gamma, params.samples, params.batch);
else
    norm_str = '';
    if params.importance_norm
        norm_str = '_is_norm';
    end
    name = sprintf('%dx%d_cinfo%.3f_sinfo%.3f_ve%.2f_pm%.2f_pC%.2f%s', ...
        params.trials, params.frames, params.category_info, ...
        params.sensory_info, params.var_e, params.p_match, params.prior_C, ...
        norm_str);
end
end