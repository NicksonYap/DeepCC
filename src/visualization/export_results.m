function export_results(opts)
% Creates a movie for each camera view to help visualize errors
% Requires that single-camera results exists in experiment folder L2-trajectories

% IDTP - Green
% IDFP - Blue
% IDFN - Black
tail_colors = [0 0 1; 0 1 0; 0 0 0];
%tail_size = 100;
tail_size = 1;

colors = distinguishable_colors(1000);

folder = 'export-results';
mkdir([opts.experiment_root, filesep, opts.experiment_name, filesep, folder]);

% Load ground truth
load(fullfile(opts.dataset_path, 'ground_truth', 'trainval.mat'));

% Create one export per camera
for iCam = 1:opts.num_cam
    
    % Create csv
    filename = sprintf('%s/%s/%s/cam%d_%s.csv',opts.experiment_root, opts.experiment_name, folder, iCam, opts.sequence_names{opts.sequence});
    
    % Load result
    predMat = dlmread(sprintf('%s/%s/L2-trajectories/cam%d_%s.txt',opts.experiment_root, opts.experiment_name, iCam,opts.sequence_names{opts.sequence}));
    
    sequence_interval = opts.sequence_intervals{opts.sequence};
    
    % Load relevant ground truth
    gtdata = trainData;
    filter = gtdata(:,1) == iCam & ismember(gtdata(:,3) + opts.start_frames(iCam) - 1, sequence_interval);
    gtdata = gtdata(filter,:);
    gtdata = gtdata(:,2:end);
    gtdata(:,[1 2]) = gtdata(:,[2 1]);
    gtdata = sortrows(gtdata,[1 2]);
    gtMat = gtdata;

    % Compute error types
    [gtMatViz, predMatViz] = error_types(gtMat,predMat,0.5,0);
    gtMatViz = sortrows(gtMatViz, [1 2]);
    predMatViz = sortrows(predMatViz, [1 2]);

    for iFrame = global2local(opts.start_frames(iCam), sequence_interval(1)):1:global2local(opts.start_frames(iCam),sequence_interval(end))
        % fprintf('Cam %d:  %d/%d\n', iCam, iFrame, global2local(opts.start_frames(iCam),sequence_interval(end)));
        if mod(iFrame,5) >0
            continue;
        end
        
        % Tail Pred (IDTP & IDFP)
        
        rows        = find(predMatViz(:, 1) == iFrame);
        identities  = predMatViz(rows, 2);
        positions   = predMatViz(rows,3:6);
        is_TP       = predMatViz(rows,end);
        
        [num_of_id, dontcare] = size(identities);
        [num_of_pos, dontcare] = size(positions);
            
        if ~isempty(positions) && num_of_id == num_of_pos
            for index = 1:num_of_pos
                identity = identities(index);
                position = positions(index,:);
                
                is_true_postive = "IDFP";
                
                if is_TP(index) == 1
                    is_true_postive = "IDTP";
                end
                
                fprintf('%06d-%02d: %05d - %04.0f, %04.0f - %04.0f, %04.0f - %s \n' ,iFrame, iCam, identity, position(:,1), position(:,2), position(:,3), position(:,4), is_true_postive );
            end
        end
        
        
        % IDFN (missed trajectories)
        
        rows        = find(gtMatViz(:, 1) == iFrame);
        identities  = gtMatViz(rows, 2); % gt idendities are not the same as pred's
        positions   = gtMatViz(rows,3:6);
        is_TP = gtMatViz(rows,end);
        
        [num_of_pos, dontcare] = size(positions);
        
        if ~isempty(positions) 
            for index = 1:num_of_pos
                identity = identities(index);
                position = positions(index,:);
                
                if is_TP(index) == 0
                    fprintf('%06d-%02d: %05d - %04.0f, %04.0f - %04.0f, %04.0f - %s \n' ,iFrame, iCam, identity, position(:,1), position(:,2), position(:,3), position(:,4), 'IDFN' );
                end
            end
        end
        
        
    end
    
end

