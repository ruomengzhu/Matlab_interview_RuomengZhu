%% Create new variables 

% read data
dt= readtable("spiral_CE_data.csv");
whos dt;

% Create disparity & type
dt.Disparity_Start = dt.RIGHT_FIX_START_X - dt.LEFT_FIX_START_X; 
dt.Disparity_End = dt.RIGHT_FIX_END_X - dt.LEFT_FIX_END_X;

dt.DisparityType_Start= repmat("uncrossed",height(dt),1);
dt.DisparityType_End= repmat("uncrossed",height(dt),1);

dt.DisparityType_Start(dt.Disparity_Start <0)="crossed";
dt.DisparityType_End(dt.Disparity_End <0)="crossed";

% create variable for convergence

dt.convergence = repmat("diverge",height(dt),1);
dt.convergence(dt.DisparityType_Start == "crossed"&dt.DisparityType_End == "crossed"&...
    abs(dt.Disparity_Start) <  abs(dt.Disparity_End)) = "converge";

dt.convergence(dt.DisparityType_Start == "uncrossed"&dt.DisparityType_End == "uncrossed"&...
    abs(dt.Disparity_Start) >  abs(dt.Disparity_End)) = "converge";

dt.convergence(dt.DisparityType_Start == "uncrossed"&dt.DisparityType_End == "crossed"&...
    abs(dt.Disparity_Start) <  abs(dt.Disparity_End)) = "converge";

% define XY position
dt.X_position = repmat("center-Left",height(dt),1);
dt.X_position(dt.RIGHT_FIX_END_X>840) = "center-Right";

dt.Y_position = repmat("center-down",height(dt),1);
dt.Y_position(dt.RIGHT_FIX_END_Y>525) = "center-up";

dt.XY_position = repmat("Right_Up",height(dt),1);
dt.XY_position(dt.X_position == "center-Right" &dt.Y_position =="center-down")="Right_Down";
dt.XY_position(dt.X_position == "center-Left" &dt.Y_position =="center-down")="Left_Down";
dt.XY_position(dt.X_position == "center-Right" &dt.Y_position =="center-up")="Right_Up";
dt.XY_position(dt.X_position == "center-Left" &dt.Y_position =="center-up")="Left_Up";


% Define start and end fixation groups based on the type of beginning and end of fixation 
dt.DisparityType_StartEnd = repmat("C-C",height(dt),1);
dt.DisparityType_StartEnd(dt.DisparityType_Start == "crossed"&dt.DisparityType_End=="uncrossed")="C-U";
dt.DisparityType_StartEnd(dt.DisparityType_Start == "uncrossed"&dt.DisparityType_End=="crossed")="U-C";
dt.DisparityType_StartEnd(dt.DisparityType_Start == "uncrossed"&dt.DisparityType_End=="uncrossed")="U-U";

%%

%% Plot for the frequency distribution and spatial distribution

% frequency distribution
[perDisparitySpiral,DisparityNames,SpiralNames] = findgroups(dt.DisparityType_StartEnd,dt.spiral_type);
dt.count = ones(height(dt),1);
percentcount = splitapply(@sum,dt.count,perDisparitySpiral)/height(dt);
bar(categorical(unique(SpiralNames)),reshape(percentcount,[],length(unique(DisparityNames))));
ax=gca;
ylabel('percent');
legend(unique(DisparityNames))
% C-C and U-U and the dominant patterns

% % heatmap spatial distribution (crossed and uncrossed separately)
dt2=  dt(dt.DisparityType_StartEnd == "U-U",:);
dt3=  dt(dt.DisparityType_StartEnd == "C-C",:);

% % crossed plot (crossed line = center of the spiral)

gridx1=750:10:950;
gridx2=450:10:600;
[x1,x2]=meshgrid(gridx1,gridx2);
x1=x1(:);
x2=x2(:);
xi=[x1 x2];
x=[dt3.LEFT_FIX_END_X dt3.RIGHT_FIX_START_Y];
figure
ksdensity(x,xi)
yline(525,Color='red',LineWidth=2)
xline(840,Color='red',LineWidth=2)

% % uncrossed plot (crossed line = center of the spiral)

gridx1=750:10:950;
gridx2=450:10:600;
[x1,x2]=meshgrid(gridx1,gridx2);
x1=x1(:);
x2=x2(:);
xi=[x1 x2];
x=[dt2.LEFT_FIX_END_X dt2.RIGHT_FIX_START_Y];
figure
ksdensity(x,xi)
yline(525,Color='red',LineWidth=2)
xline(840,Color='red',LineWidth=2)

%%

%% GLMER model for crossed and uncrossed data (three way interaction)

 
dt4=dt(dt.DisparityType_StartEnd == "U-U" | dt.DisparityType_StartEnd == "C-C",:);
[perVariable,DisNames,SpiNames,XNames,YNames,IDNames] = findgroups(dt4.DisparityType_StartEnd,dt4.spiral_type,dt4.X_position,dt4.Y_position,dt4.ID);
dt4.count = ones(height(dt4),1);
Variablecount = splitapply(@sum,dt4.count,perVariable);
TableVariable=table(DisNames,SpiNames,XNames,YNames,IDNames,Variablecount);


dt_XY_1= fitglme(TableVariable,'Variablecount~DisNames+XNames+YNames+(1|SpiNames)+(1|IDNames)')
dt_XY_2= fitglme(TableVariable,'Variablecount~DisNames*XNames*YNames+(1|SpiNames)+(1|IDNames)')


%%
