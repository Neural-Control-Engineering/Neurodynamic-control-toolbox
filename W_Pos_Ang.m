function [processed_whisker] = W_Pos_Ang(filePath)

UD = readtable(filePath,'ReadVariableNames',false);  %#ok<SAGROW> %Read File from path


UD.Properties.VariableNames = ["Frame","Nose_X","Nose_Y","Nose_L","RightMidFaceContour_X","RightMidFaceContour_Y","RightMidFaceContour_L","RightUpperFaceContour_X", ... 
    "RightUpperFaceContour_Y","RightUpperFaceContour_L","WhiskerBase_X","WhiskerBase_Y","WhiskerBase_L","WhiskerMiddle_X","WhiskerMiddle_Y","WhiskerMiddle_L","WhiskerTip_X", ... 
    "WhiskerTip_Y","WhiskerTip_L","WhiskerMid1_X","WhiskerMid1_Y","WhiskerMid1_L","WhiskerMid2_X","WhiskerMid2_Y","WhiskerMid2_L"];

Angle = zeros(1,height(UD));
L = zeros(1,height(UD));

% Use pre-determined average to see if the full video should be processed,
% if not skip it for now to save time with processing
mean_likelihood = mean([mean(UD.Nose_L),mean(UD.RightMidFaceContour_L),mean(UD.RightUpperFaceContour_L),mean(UD.WhiskerBase_L),mean(UD.WhiskerMiddle_L),mean(UD.WhiskerTip_L), ...
    mean(UD.WhiskerMid1_L),mean(UD.WhiskerMid2_L)]);

if mean_likelihood > 0.90
    parfor i=1:height(UD)    
        X_fit = [UD.WhiskerMid1_X(i);UD.WhiskerMiddle_X(i);UD.WhiskerBase_X(i);UD.WhiskerMid2_X(i);UD.WhiskerTip_X(i)];
        Y_fit = [UD.WhiskerMid1_Y(i);UD.WhiskerMiddle_Y(i);UD.WhiskerBase_Y(i);UD.WhiskerMid2_Y(i);UD.WhiskerTip_Y(i)];
        X_NoseH = [UD.Nose_X(i) UD.RightUpperFaceContour_X(i)];
        Y_NoseH = [UD.Nose_Y(i) UD.RightUpperFaceContour_Y(i)];
        likelihood = [UD.Nose_L(i);UD.RightMidFaceContour_L(i);UD.RightUpperFaceContour_L(i);UD.WhiskerBase_L(i);UD.WhiskerMiddle_L(i);...
            UD.WhiskerTip_L;UD.WhiskerMid1_L;UD.WhiskerMid2_L];
    
    
        [xi,yi] = polyxpoly(X_fit,Y_fit,X_NoseH',Y_NoseH');
    
        if isempty(xi) || isempty(yi) == 1
            xi = 0;
            yi = 0;
        end
        
        %Angle
        V1 = [UD.Nose_X(i),UD.Nose_Y(i),0] -[xi(1),yi(1),0];
    
        V2 = [UD.WhiskerBase_X(i),UD.WhiskerBase_Y(i),0]-[xi(1),yi(1),0];
        Angle(i) = rad2deg(atan2(norm(cross(V1,V2)),dot(V1,V2)));
    
        L(i) = mean(likelihood);
    end

else
    Angle = nan(length(UD.(1)),1)';
    L = ones(length(UD.(1)),1) * mean_likelihood;
end
processed_whisker(:,1) = UD.(1)(:);
processed_whisker(:,2) = Angle';
processed_whisker(:,3) = L;

end