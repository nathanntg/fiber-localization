%% distance matrix
load('output2-1.mat');

%% ground truth: rec0003
load('rec00003-trace.mat');

% separate phases
phases = logical([]);
phases(1, 1:50) = true;
phases(2, 51:100) = true;

%% ground truth: rec0004
load('rec00004-trace.mat');

% separate phases
phases = logical([]);
phases(1, 1:132) = true;
phases(2, 133:252) = true;

%% actual distances by correlation between sweeps
distances_actual = ones(size(traces, 1), size(traces, 1));

for i = 1:size(phases, 1)
    distances_actual = distances_actual .* corrcoef(traces(:, phases(i, :))');
end

figure; imagesc(distances_actual, [0 1]);

%% actual coordinates by measuring center of mass during sweeps

coordinates_actual = zeros(size(traces, 1), size(phases, 1));

for i = 1:size(phases, 1)
    cur_trace = traces(:, phases(i, :));
    
    % potentially threshold above median
    %cur_trace = bsxfun(@minus, cur_trace, median(cur_trace, 2));
    %cur_trace(cur_trace < 0) = 0;
    
    index = 1:size(cur_trace, 2);
    coordinates_actual(:, i) = mean(bsxfun(@times, index, cur_trace), 2);
end

coordinates_actual = bsxfun(@minus, coordinates_actual, min(coordinates_actual, [], 1));
coordinates_actual = bsxfun(@rdivide, coordinates_actual, max(coordinates_actual, [], 1));

figure;
scatter(coordinates_actual(:, 1), coordinates_actual(:, 2));

%% compare sort

[d, idx] = sort(mean(distances(1, :, :), 3), 'descend');
[d2, idx2] = sort(distances_actual(1, :), 'descend');

figure; plot(d);
figure; plot(d2);

figure; plot(1:size(traces, 2), traces(1, :), 1:size(traces, 2), traces(idx2(2), :));

%% calculate

% exclude nan rows (inaccessible for excitation)
idx = ~all(isnan(distances(:, :, 1)), 2);
distances_subset = mean(distances(idx, idx, :), 3);

% normalize so that diagonal is 1
distances_subset = bsxfun(@rdivide, distances_subset, distances_subset(logical(eye(size(distances_subset)))));

% assume log dropoff in signal
Mdis = -100 .* log(distances_subset);
Mdis(distances_subset < 0) = 0;

% convert to M format
% https://math.stackexchange.com/a/423898
Mm = (Mdis(1, :) .^ 2 + Mdis(:, 1) .^ 2 - Mdis .^ 2) ./ 2;

% eigen decomposition
[U,S] = eig(Mm);

% approximate position
pos_hat = U * S .^ 0.5;
pos_hat = pos_hat(:, [1 2]);

%% fit to original distribution

pos = coordinates_actual(idx, :);
tform = fitgeotrans(pos_hat, pos, 'Similarity');
pos_hat_t = transformPointsForward(tform, pos_hat);

%% plot the distribution
figure(4);

c = [lines(7); zeros(size(pos, 1) - 7, 3)];

subplot(1, 2, 1);
scatter(pos(:, 1), pos(:, 2), 25, c);
xlim(3 * [-dx dx]);
ylim(3 * [-dy dy]);
%axis equal;

subplot(1, 2, 2);
scatter(pos_hat_t(:, 1), pos_hat_t(:, 2), 25, c);
xlim(3 * [-dx dx]);
ylim(3 * [-dy dy]);
%axis equal;

%% make video

% exclude nan rows (inaccessible for excitation)
idx = find(~all(isnan(distances(:, :, 1)), 2));

% make a mesh grid based on the frame dimensions
[x, y] = meshgrid(1:size(frames, 2), 1:size(frames, 1));

% open video handle
vh = VideoWriter('localize.mp4', 'MPEG-4');
vh.FrameRate = 5;

% open
open(vh);

for i = 1:size(frames, 3)
    if isa(frames, 'uint16') || isa(frames, 'single')
        frame = im2uint8(frames(:, :, i));
    end

    % turn to color
    if ismatrix(frame)
        frame = repmat(frame, 1, 1, 3);
    end
    
    % make fiber blue
    mask = find(((x - fiber_centers(idx(i), 1)) .^ 2 + (y - fiber_centers(idx(i), 2)) .^ 2) < (fiber_radii(idx(i)) .^ 2));
    
    r = frame(:, :, 1);
    r(mask) = 0;
    frame(:, :, 1) = r;
    
    g = frame(:, :, 2);
    r(mask) = 0;
    frame(:, :, 2) = g;

    writeVideo(vh, im2frame(frame));
end

% close
close(vh);