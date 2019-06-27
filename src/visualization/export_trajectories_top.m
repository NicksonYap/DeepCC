opts = get_opts();

% Load ground truth trajectories (or your own)
load(fullfile(opts.dataset_path, 'ground_truth', 'trainval.mat'));
trajectories = trainData;

% Load map
map = imread('src/visualization/data/map.jpg');

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

% Delineate the regions of interest
roimask = ones(size(map,1),size(map,2));
for k = 1:8
    roi = rois{k};
    mapped = world2map(image2world(roi,k));
    map = cv.polylines(map, mapped, 'Thickness',1.5);
    roimask = cv.fillPoly(roimask, mapped);
end
roimask = 1-roimask/13;
map = double(map);
map(:,:,1) = map(:,:,1) .* roimask;
map(:,:,2) = map(:,:,2) .* roimask;
map(:,:,3) = map(:,:,3) .* roimask;
map = uint8(map);

%% Top View
for frame = startFrame:fps:endFrame
    % fprintf('Frame %d/%d\n', frame, endFrame);
    
    data = trajectories(trajectories(:,3) == frame,:);
    ids = unique(data(:,2));
    
    for k = 1:length(ids)
        
        id = ids(k);
        mask = logical((trajectories(:,2) == id) .* (trajectories(:,3) >= frame - tail_size) .* (trajectories(:,3) < frame));
        mapped = world2map(trajectories(mask, [8 9]));
    
        if(mapped) % weird case wheere mapped is blank...
            fprintf('%06d: %05d - %07.2f, %07.2f \n' ,frame, k, mapped(1, 1), mapped(1, 2));
        end
        
    end
    
end
