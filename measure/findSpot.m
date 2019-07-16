function [x, y, radius] = findSpot(img, mn, mx)
%FINDSPOT Summary of this function goes here
%   Detailed explanation goes here

if ~exist('mn', 'var')
    mn = 4;
end
if ~exist('mx', 'var')
    mx = 64;
end

% filter
img = medfilt2(img, [3 3]);

% binarize
img_bin = imbinarize(img);

% get properties
properties = regionprops(img_bin, 'Centroid', 'MajorAxisLength', 'MinorAxisLength');

% get centroids and radii
centroids = cat(1, properties(:).Centroid);
radii = mean([cat(1, properties(:).MajorAxisLength) cat(1, properties(:).MinorAxisLength)], 2) ./ 2;

% find matches
idx = radii >= mn & radii <= mx;
cnt = nnz(idx);

if cnt < 1
    error('Unable to find illumination spot.');
elseif cnt > 1
    error('Found multiple illumination spots.');
    
    % TODO: potentiall re-enable by converting above to warning
    % show user interface to select correct spot?
    fe = FiberEditor(img, centroids(idx, :), radii(idx));
    title('Identify illumination spot');
    [centroids, radii] = fe.waitForAnnotations();
    
    if ~isscalar(radii)
        error('Unable to find illumination spot.');
    end
end

x = centroids(idx, 1);
y = centroids(idx, 2);
radius = radii(idx);

end
