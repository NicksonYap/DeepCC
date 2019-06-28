opts = get_opts();

% Load ground truth trajectories (or your own)
load(fullfile(opts.dataset_path, 'ground_truth', 'trainval.mat'));
trajectories = trainData;

% Create folder
folder = 'export-results';
mkdir([opts.experiment_root, filesep, opts.experiment_name, filesep, folder]);

% Params
colors     = distinguishable_colors(1000);
% tail_size  = 300;
tail_size  = 1;
fps        = 120;
rois       = opts.ROIs;
ids        = unique(trajectories(:,2));
interval   = opts.sequence_intervals{opts.sequence};
startFrame = interval(1);
endFrame   = interval(end);

% Convert frames to global clock
for iCam = 1:8
    inds = find(trajectories(:,1) == iCam);
    trajectories(inds,3) = local2global(opts.start_frames(iCam),trajectories(inds,3));
end


%% Render side view

% Placeholders for tags
inds = [271,1; 271, 481; 271, 961; 271,1441;  1,961; 1,1441; 1,481; 1,1];


for frame = startFrame:fps:endFrame
    % fprintf('Frame %d/%d\n', frame, endFrame);
    
    data = trajectories(trajectories(:,3) == frame,:);
    ids = unique(data(:,2));
    
    % Will read through each camera separately (slow)
    % TODO: Render each camera separately, then combine into mosaic (fast)
    for iCam = 1:opts.num_cam
        % fprintf('Camera %d/%d\n', iCam, opts.num_cam);
        
        % Shade ROI with blue
        % roi = rois{iCam}; 
        % disp(roi);
        
        % Draw all tails for current camera frame
        for k = 1:length(ids)
        
            id = ids(k);
            mask = logical((trajectories(:,1) == iCam) .* (trajectories(:,2) == id) .* (trajectories(:,3) >= frame - tail_size) .* (trajectories(:,3) < frame));
            bb = trajectories(mask, [4 5 6 7]);
            
            if ~isempty(bb)
                % feet = feetPosition(bb);
                % fprintf('origin: %d, %d, width: %d height: %d \n' , bb(:,1), bb(:,2), bb(:,3) , bb(:,4));
                % fprintf('%06d-%02d: %05d - %04.1f, %04.1f \n' ,frame, iCam, id, feet(1,1), feet(1,2) );
                fprintf('%06d-%02d: %05d - %04d, %04d - %04d, %04d \n' ,frame, iCam, id, bb(:,1), bb(:,2), bb(:,3), bb(:,4));
            end
            
        end
    end
    
end