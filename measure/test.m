%% test find laser spot
img = rgb2gray(imread('spot.png'));
[x, y, radius] = findSpot(img);

figure;
imagesc(img);
viscircles([x y], radius);

%% test fiber editor
img = rgb2gray(imread('spot.png'));

img = img(1:1024, 1:512);

fe = FiberEditor(img);
[a, b] = fe.waitForAnnotations();

%% test find fibers
img = rgb2gray(imread('spot.png'));

img = img(1:1024, 1:512);

ff = Fibers();
ff.findFibersViaImage(img);
