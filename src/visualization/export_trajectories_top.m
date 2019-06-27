opts = get_opts();

% Load ground truth trajectories (or your own)
load(fullfile(opts.dataset_path, 'ground_truth', 'trainval.mat'));
trajectories = trainData;

% Load map
map = imread('src/visualization/data/map.jpg');

% Create folder
folder = 'export-results';
mkdir([opts.experiment_root, filesep, opts.experiment_name, filesep, folder]);
csv_name = fullfile(opts.experiment_root, opts.experiment_name, folder, 'export_top.csv');

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

export_matrix = [];

%% Top View

frame_count = 0;

tic

for frame = startFrame:fps:endFrame
    percent = (frame-startFrame)/(endFrame-startFrame)*100;
    duration_taken = duration(0,0,toc);
    est_total = duration(0,0,(toc/percent*100));
    est_remaining = est_total - duration_taken;
    
    fprintf('Frame %d/%d - %06.2f%% - time taken %s - remaining: %s \n', frame, endFrame, percent, duration_taken, est_remaining );
    
    data = trajectories(trajectories(:,3) == frame,:);
    ids = unique(data(:,2));
    
    for k = 1:length(ids)
        
        id = ids(k);
        mask = logical((trajectories(:,2) == id) .* (trajectories(:,3) >= frame - tail_size) .* (trajectories(:,3) < frame));
        mapped = world2map(trajectories(mask, [8 9]));
    
        if(~isempty(mapped)) % weird case wheere mapped is blank...
            % fprintf('%06d: %05d - %07.2f, %07.2f \n' ,frame, id, mapped(1, 1), mapped(1, 2));
            
            export_matrix = [export_matrix; [frame, id, mapped(1, 1), mapped(1, 2)]];
        end
        
    end
    
    frame_count = frame_count + 1;
    
%     if(mod(frame_count, 5) == 0 && ~isempty(export_matrix))
%         disp('write file!');
%         csvwrite(csv_name, export_matrix);
%         % writematrix(export_matrix,csv_name);
%     end
    
end

disp('exporting file...');
csvwrite(csv_name, export_matrix);
disp('exported.');
% writematrix(export_matrix,csv_name);
