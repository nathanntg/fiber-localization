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
Mdis = squareform(-100. * log(Msig));

% setup lease squares
reshape_pos = @(x) [0 0; reshape(x, nFibers - 1, 2)];
F = @(x) pdist(reshape_pos(x), 'euclidean') - Mdis;

% run least squares
pos_hat = rand(2 * (nFibers - 1), 1);
pos_hat = lsqnonlin(F, pos_hat);
pos_hat = reshape_pos(pos_hat);

% bar
figure(3);
bar(abs(Mdis - pdist(pos_hat, 'euclidean')));
%[Mdis; pdist(pos_hat, 'euclidean')]

%% plot the distribution
figure(4);

c = [lines(7); zeros(nFibers - 7, 3)];

subplot(1, 2, 1);
scatter(pos(:, 1), pos(:, 2), 25, c);
xlim(3 * [-dx dx]);
ylim(3 * [-dy dy]);
%axis equal;

subplot(1, 2, 2);
scatter(pos_hat(:, 1), pos_hat(:, 2), 25, c);
xlim(3 * [-dx dx]);
ylim(3 * [-dy dy]);
%axis equal;
