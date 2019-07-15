%% test find laser spot
img = rgb2gray(imread('spot.png'));
[x, y, radius] = findSpot(img);

figure;
imagesc(img);
viscircles([x y], radius);

%% test find fibers
img = rgb2gray(imread('spot.png'));
fe = FiberEditor(img);
[a, b] = fe.waitForAnnotations();
