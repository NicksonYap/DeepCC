function compute_L3_identities(opts)
% Computes multi-camera trajectories from single-camera trajectories


filename = sprintf('%s/%s/L3-identities/L2trajectories_%s.mat',opts.experiment_root, opts.experiment_name, opts.sequence_names{opts.sequence});
    
if isfile(filename)
    disp("Using previously computed trajectories");
    load(filename,'trajectories');
else
    trajectories = loadL2trajectories(opts);
    trajectories = getTrajectoryFeatures(opts, trajectories);
    save(filename,'trajectories');
end

identities = trajectories;


filename = sprintf('%s/%s/L3-identities/identities_%s.mat',opts.experiment_root, opts.experiment_name, opts.sequence_names{opts.sequence});

if isfile(filename)
    disp("Using previously computed identities");
    load(filename,'identities');
else
    for k = 1:length(identities)
        identities(k).trajectories(1).data(:,end+1) = local2global(opts.start_frames(identities(k).trajectories(1).camera) ,identities(k).trajectories(1).data(:,1));
        identities(k).trajectories(1).startFrame = identities(k).trajectories(1).data(1,9);
        identities(k).startFrame = identities(k).trajectories(1).startFrame;
        identities(k).trajectories(1).endFrame = identities(k).trajectories(1).data(end,9);
        identities(k).endFrame   = identities(k).trajectories(1).endFrame;
    end
    identities = sortStruct(identities,'startFrame');

    global_interval = opts.sequence_intervals{opts.sequence};
    startFrame = global_interval(1);
    endFrame = global_interval(1) + opts.identities.window_width - 1;

    while startFrame <= global_interval(end)
        clc; fprintf('Window %d...%d\n', startFrame, endFrame);

        identities = linkIdentities(opts, identities, startFrame, endFrame);

        % advance sliding temporal window
        startFrame = endFrame   - opts.identities.window_width/2;
        endFrame   = startFrame + opts.identities.window_width;
    end

    save(filename,'identities');
end


%%
fprintf('Saving identity-trajectory pairs\n');

id_traj_name = sprintf('%s/%s/L3-identities/id_traj_%s.txt', opts.experiment_root, opts.experiment_name, opts.sequence_names{opts.sequence});

id_traj_file = fopen(id_traj_name,'wt');

for id = 1:length(identities)
    identity = identities(id);
    trajectory_ids = [identity.trajectories(1:end).mcid];

    % ref: https://uk.mathworks.com/matlabcentral/answers/21-how-do-i-convert-a-numerical-vector-into-a-comma-delimited-string#answer_23
    traj_str = sprintf('%d ' , trajectory_ids);
    traj_str = traj_str(1:end-1);% strip final comma
    
    fprintf(id_traj_file, '%d %s\n' , id, traj_str);
end

fclose(id_traj_file);

%%
fprintf('Saving results\n');
trackerOutputL3 = identities2mat(identities);
for iCam = 1:opts.num_cam
    cam_data = trackerOutputL3(trackerOutputL3(:,1) == iCam,2:end);
    dlmwrite(sprintf('%s/%s/L3-identities/cam%d_%s.txt', ...
        opts.experiment_root, ...
        opts.experiment_name, ...
        iCam, ...
        opts.sequence_names{opts.sequence}), ...
        cam_data, 'delimiter', ' ', 'precision', 6);
end