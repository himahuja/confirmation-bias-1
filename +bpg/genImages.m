function [im, imF] = genImages(frames, width, spFreqCPP, spFreqStdCPP, oriDEG, oriStdDEG, annulusPix)
%BPG.GENIMAGES Create a sequence band-pass grating (bpg) stimuli.
%
%[im, imF] = BPG.GENIMAGES(frames, width, spFreqCPP, spFreqStdCPP, oriDEG, oriStdDEG)
% creates [frames x width x width] array of images. spFreqCPP sets the mean
% spatial frequency in cycles per pixel. spFreqStdCPP sets the range of
% spatial frequencies present. oriDEG sets the mean rotation, oriStdDeg
% sets the range of orientation energy present.
%
% oriDEG may be a vector of orientations of length 'frames'.

noise = randn(frames, width, width);
noiseF = framefun(@(f) fftshift(fft2(f)), noise);

x = linspace(-1, 1, width);
[xx, yy] = meshgrid(x, x);
% Get polar coordinates: rr is radius, tt is angle.
rr = sqrt(xx.^2 + yy.^2);
tt = -atan2(yy, xx);

if length(oriDEG) == 1, oriDEG = oriDEG * ones(1, frames); end

im = zeros(frames, width, width);
imF = zeros(frames, width, width);

%% Create spatial frequency filter
spFreqFilter = pdf('rician', rr / 2, spFreqCPP, spFreqStdCPP);

%% Create gaussian aperture
aperture = exp(-4 * rr.^2);

if nargin >= 7 && annulusPix > 0
    % Cut out annulus hole.
    aperture = aperture .* (1 + erf(10 * (rr - annulusPix / width)));
end

%% Generate each frame.

for f=1:frames
    % Create orientation filters for each frame.
    oriFilter = bpg.vmpdf(2 * tt, deg2rad(oriDEG(f)), 1 / deg2rad(oriStdDEG));
    
    % Get full, normalized foureir-domain filter.
    filterF = spFreqFilter .* oriFilter;
    filterF = filterF / sum(filterF(:));
    
    % Apply fourier-domain filters on each frame.
    imF(f, :, :) = squeeze(noiseF(f, :, :)) .* filterF;
    im(f, :, :) = aperture .* real(ifft2(ifftshift(squeeze(imF(f, :, :)))));
end

%% Normalize range in pixel space to +/- 1
im = im / max(abs(im(:)));
end

function frames = framefun(fn ,frames)
%Helper to apply fn to each frame in frames.
for f=1:size(frames, 1)
    frames(f, :, :) = fn(squeeze(frames(f, :, :)));
end
end