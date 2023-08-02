function [yo,R,p_n] = Whisker_Radius(Filepath)
UD = readtable(Filepath);
UD.Properties.VariableNames = ["Frame","HeadR_X","HeadR_Y","HeadR_L","HeadL_X","HeadL_Y","HeadL_L","Nose_X", ... 
    "Nose_Y","Nose_L","WhiskerB_X","WhiskerB_Y","WhiskerB_L","WhiskerM_X","WhiskerM_Y","WhiskerM_L","WhiskerT_X", ... 
    "WhiskerT_Y","WhiskerT_L","WhiskerM1_X","WhiskerM1_Y","WhiskerM1_L","WhiskerM2_X","WhiskerM2_Y","WhiskerM2_L"];

%R = zeros(1,height(UD));
for i = 1:height(UD)
    X_fit = [UD.WhiskerM1_X(i);UD.WhiskerM_X(i);UD.WhiskerB_X(i);UD.WhiskerM2_X(i);UD.WhiskerT_X(i)];
    Y_fit = [UD.WhiskerM1_Y(i);UD.WhiskerM_Y(i);UD.WhiskerB_Y(i);UD.WhiskerM2_Y(i);UD.WhiskerT_Y(i)];

    
    a = [X_fit Y_fit ones(size(X_fit))]\(-(X_fit.^2+Y_fit.^2));
    xo(i) = -.5*a(1);
    yo(i) = -.5*a(2);
    R(i) = sqrt((a(1)^2+a(2)^2)/4-a(3));
    for j=1:5
    if yo(i)>Y_fit(j)
        p_n(i)=1;
        break
    elseif yo(i)<Y_fit(j)
        p_n(i)=-1;
        break
    else
        p_n(i)=0;
    end
    end
    
    
end

end