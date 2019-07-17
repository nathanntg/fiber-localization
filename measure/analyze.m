load('/Users/nathan/Documents/School/BU/Boas Lab/Fiber/Microscope/Localization/output2-1.mat');

%% rec0003
load('/Users/nathan/Documents/School/BU/Boas Lab/Fiber/Microscope/Localization/rec00004-trace.mat');

% separate phases
phases = logical([]);
phases(1, 1:50) = true;
phases(2, 51:100) = true;

%% rec0004
load('/Users/nathan/Documents/School/BU/Boas Lab/Fiber/Microscope/Localization/rec00004-trace.mat');

% separate phases
phases = logical([]);
phases(1, 1:132) = true;
phases(2, 133:252) = true;

%% actual distances
distances_actual = ones(size(traces, 1), size(traces, 1));

for i = 1:size(phases, 1)
    cur_trace = traces(:, phases(i, :));
    for j = 1:size(traces, 1)
        cp = sum(bsxfun(@times, cur_trace(j, :), cur_trace), 2);
        cp = cp ./ max(cp);
        distances_actual(:, j) = distances_actual(:, j) .* cp;
    end
end


%% actual distances
distances_actual = ones(size(traces, 1), size(traces, 1));

for i = 1:size(phases, 1)
    distances_actual = distances_actual .* corrcoef(traces(:, phases(i, :))' .^ 2);
end

figure; imagesc(distances_actual, [0 1]);


%% compare sort

[d, idx] = sort(mean(distances(1, :, :), 3), 'descend');
[d2, idx2] = sort(distances_actual(1, :), 'descend');

figure; plot(d);
figure; plot(d2);

figure; plot(1:size(traces, 2), traces(1, :), 1:size(traces, 2), traces(idx2(2), :));

