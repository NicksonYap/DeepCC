%% Options
opts = get_opts();
create_experiment_dir(opts);

%% Setup Gurobi
if ~exist('setup_done','var')
    setup;
    setup_done = true;
end

%% Run Tracker

% opts.visualize_all = false;
opts.sequence = 2; % trainval-mini


%% L1 - Tracklets

% opts.visualize_L1_window_detections = true;
% opts.visualize_L1_spatial_grouping_and_correlations = true;
% opts.visualize_L1_clustered_detections = true;
% opts.visualize_L1_generated_tracklets_in_window = true;

opts.optimization = 'KL';
compute_L1_tracklets(opts);

%% L2 - Single-camera trajectories

% opts.visualize_L2_all_tracklets = true;
% opts.visualize_L2_merged_tracklets_in_window = true;
% opts.visualize_L2_appearance_group_tracklets = true;

opts.optimization = 'BIPCC';
opts.trajectories.appearance_groups = 1;
compute_L2_trajectories(opts);
opts.eval_dir = 'L2-trajectories';
evaluate(opts);

%% L3 - Multi-camera identities
opts.identities.appearance_groups = 0;
compute_L3_identities(opts);
opts.eval_dir = 'L3-identities';
evaluate(opts);

