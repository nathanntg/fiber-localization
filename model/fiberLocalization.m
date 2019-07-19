%% generate fibers

% number of fibers
nFibers = 25;

% FWHM of gaussian distribution
dx = 100;
dy = 100;

% get random positions
pos = bsxfun(@times, randn(nFibers, 2), [dx dy]);

% get separate matrix and signal matrix
Mrho = squareform(pdist(pos, 'euclidean'));
Msig = exp(-Mrho ./ 100);

%% plot the distribution
figure(1);

subplot(1, 3, 1);
plot(pos(:, 1), pos(:, 2), 'o');
xlim(3 * [-dx dx]);
ylim(3 * [-dy dy]);

subplot(1, 3, 2);
imagesc(Mrho);
colorbar;

subplot(1, 3, 3);
imagesc(log10(Msig), [-1 0]);
colorbar;

%% calculate

% distance matrix (just reconstruction of Mrho)
Mdis = -100. * log(Msig);

% convert to M format
% https://math.stackexchange.com/a/423898
Mm = (Mdis(1, :) .^ 2 + Mdis(:, 1) .^ 2 - Mdis .^ 2) ./ 2;

% eigen decomposition
[U,S] = eig(Mm);

% approximate position
pos_hat = U * S .^ 0.5;
pos_hat = pos_hat(:, [end - 1 end]);

% bar
figure(3);
bar(abs(squareform(Mdis) - pdist(pos_hat, 'euclidean')));
%[Mdis; pdist(pos_hat, 'euclidean')]

%% fit to original distribution

tform = fitgeotrans(pos_hat, pos, 'Similarity');
pos_hat_t = transformPointsForward(tform, pos_hat);

%% plot the distribution
figure(4);

c = [lines(7); zeros(nFibers - 7, 3)];

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
