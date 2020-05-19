function [small, large] = sample_contrast(contrast, sigma, baseline_contrast)
large = [0,0];
small = [0, 1];
while mean(large) < mean(small)
    large = randn(1,10)*sigma + contrast/2 + baseline_contrast ;
    small = randn(1,10)*sigma - contrast/2 + baseline_contrast;
end
end

% function [up, bl_contrast, large] = sample_contrast(up, effective_contrast, sigma, baseline_contrast)
% %function [up, large, eff_noise] = sample_contrast(up, effective_contrast, sigma, baseline_contrast)
% 
% %% 
% % up =  1 = larger than baseline contrast -> Stim correct
% % up = -1 = smaller than baseline contrast -> Ref correct
% stim_contrast = (up*effective_contrast) + baseline_contrast;
% large =  randn(1,10)*sigma + stim_contrast;
% bl_contrast = randn(1,10)*sigma + baseline_contrast;
% if mean(large) > mean(bl_contrast) 
%     up = 1;
% else
%     up = -1;
% end
% 
% end

