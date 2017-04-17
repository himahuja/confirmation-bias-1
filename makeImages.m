function image_array = makeImages(sz, frame_categories, left_category, right_category, contrast, noise)
%MAKEIMAGES creates noisy image frames for a single trial of the 'Gabor'
%experiment.

background = 127.0;
image_array = zeros(length(frame_categories), sz, sz);
for i = 1:frames
    if frame_categories(i) == 1
        image = left_category * contrast + background;
    else
        image = right_category * contrast + background;
    end
    
    % Add white pixel noise.
    image = image + noise * randn(sz, sz);
   
    % Clip pixel values to within the proper range.
    image(image > 255) = 255;
    image(image < 0) = 0;
    
    image_array(i,:,:) = image;
end
end