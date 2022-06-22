%% --------------------------------Hello-------------------------------- %%
% This code details the selection of training scenarios in our paper:
% Feature-driven Economic Improvement for Network-Constrained
% Unit Commitment: A Closed-Loop
% Predict-and-Optimize Framework.
%
% Please let me know if you have concerns about this code.
% It is my pleasure to discuss/explain with you.
%
% My academic email: xchen130@stevens.edu
% My personal email: chenxianbang@hotmail.com
%
% Please cite our paper if you use this code in your research:
%
% Xianbang Chen, Yafei Yang, Yikui Liu, and Lei Wu. "Feature-driven Economic
% Improvement for Network-Constrained Unit Commitment: A Closed-Loop
% Predict-and-Optimize Framework," IEEE Transaction on Power Systems,
% vol. 37, no. 4, pp. 3104-3118, July 2022, doi: 10.1109/TPWRS.2021.3128485.
%% --------------------------------Hello-------------------------------- %%
%
function[Picked_TRA_intuition,...
         Picked_TRA_feature,...
         Picked_TRA_load_city,...
         Picked_TRA_reserve_load_req,...
         Picked_TRA_reserve_RES_req,...
         Picked_TRA_cost_perfect]...
= Step_00_Select_train_day(Dispatch_day_1st,...
                           Dispatch_day_end,...
                           Number_training_day,...
                           Number_dispatch_day,...
                           Scaler_load,...
                           Scaler_SPG,...
                           Scaler_WPG,...
                           R_for_load,...
                           R_for_RES,...
                           Number_historic_day)
%% -------------------------------Loading------------------------------- %%
clear('yalmip');
[~,...
 ~,...
 ~,...
 Number_city,...
 ~,...
 Number_hour,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 Data_load_city,...
 Data_RES_DAF,...
 ~,...
 Data_feature_OPO,...
 ~,...
 ~,...
 ~,...
 ~] = CPO_Database_Belgium_bus24(1,...
                                 1,...
                                 Scaler_load,...
                                 Scaler_SPG,...
                                 Scaler_WPG,...
                                 'OPO');
[~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 Data_feature_PPO,...
 ~,...
 ~,...
 ~,...
 ~] = CPO_Database_Belgium_bus24(1,...
                                 1,...
                                 Scaler_load,...
                                 Scaler_SPG,...
                                 Scaler_WPG,...
                                 'PPO');
                          
[~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 ~,...
 Data_feature_CPO,...
 ~,...
 ~,...
 ~,...
 ~] = CPO_Database_Belgium_bus24(1,...
                                 1,...
                                 Scaler_load,...
                                 Scaler_SPG,...
                                 Scaler_WPG,...
                                 'CPO');
                          
                               
load('CPO_Data_Cost_perfect_UC');
Cost_perfect = Cost_perfect_UC;
CAP_RES  = 100;
How_long = Number_historic_day;
%% -----------------------------Search type----------------------------- %%
Dispatch_day_1st_intuition    = Dispatch_day_1st;
Dispatch_day_end_intuition    = Dispatch_day_end;
Dispatch_day_1st_iteration    = (Dispatch_day_1st_intuition-1)*4+1;
Dispatch_day_end_iteration    =  Dispatch_day_end_intuition*4;
Number_training_day_intuition = Number_training_day;
Number_dispatch_day_intuition = Number_dispatch_day;
Historic_day_1st_intuition    = Dispatch_day_1st_intuition - How_long;
Historic_day_end_intuition    = Dispatch_day_1st_intuition - 1;
Number_historic_day_intuition = Historic_day_end_intuition - Historic_day_1st_intuition + 1;
Number_training_day_iteration = Number_training_day_intuition*4;
Historic_day_1st_iteration    = (Historic_day_1st_intuition - 1)*4 + 1;
Historic_day_end_iteration    = Historic_day_end_intuition*4;
%% -----------------------------Prepare box----------------------------- %%   
% Training days
Picked_TRA_intuition        = zeros(Number_training_day_intuition, 1);
Picked_TRA_feature          = zeros(size(Data_feature_OPO, 1), Number_training_day_iteration);
Picked_TRA_load_city        = zeros(Number_city*Number_hour,   Number_training_day_iteration); 
Picked_TRA_reserve_load_req = zeros(Number_hour, Number_training_day_iteration);
Picked_TRA_reserve_RES_req  = zeros(Number_hour, Number_training_day_iteration);
Picked_TRA_cost_perfect     = zeros(Number_training_day_iteration, 1);
%% --------------------Get historic day's information------------------- %%
% DAF
Historic_DAF_SPG_FR = Data_feature_OPO(289:312, Historic_day_1st_iteration:Historic_day_end_iteration);
Historic_DAF_SPG_WR = Data_feature_OPO(313:336, Historic_day_1st_iteration:Historic_day_end_iteration);
Historic_DAF_WPG_OF = Data_feature_OPO(337:360, Historic_day_1st_iteration:Historic_day_end_iteration);
Historic_DAF_WPG_FR = Data_feature_OPO(457:480, Historic_day_1st_iteration:Historic_day_end_iteration);
Historic_DAF_WPG_WR = Data_feature_OPO(481:504, Historic_day_1st_iteration:Historic_day_end_iteration);
Historic_DAF_RES    = Historic_DAF_SPG_FR...
                    + Historic_DAF_SPG_WR...
                    + Historic_DAF_WPG_OF...
                    + Historic_DAF_WPG_FR...
                    + Historic_DAF_WPG_WR;
for i_hisday = 1:Number_historic_day_intuition
    Historic_DAF(:, i_hisday) = sum(Historic_DAF_RES(:, (i_hisday-1)*4+1:i_hisday*4), 2)/4;
end
% RUM
Historic_RUM_SPG_FR = Data_feature_PPO(289:312, Historic_day_1st_iteration:Historic_day_end_iteration);
Historic_RUM_SPG_WR = Data_feature_PPO(313:336, Historic_day_1st_iteration:Historic_day_end_iteration);
Historic_RUM_WPG_OF = Data_feature_PPO(337:360, Historic_day_1st_iteration:Historic_day_end_iteration);
Historic_RUM_WPG_FR = Data_feature_PPO(457:480, Historic_day_1st_iteration:Historic_day_end_iteration);
Historic_RUM_WPG_WR = Data_feature_PPO(481:504, Historic_day_1st_iteration:Historic_day_end_iteration);
Historic_RUM_RES    = Historic_RUM_SPG_FR...
                    + Historic_RUM_SPG_WR...
                    + Historic_RUM_WPG_OF...
                    + Historic_RUM_WPG_FR...
                    + Historic_RUM_WPG_WR;
for i_hisday = 1:Number_historic_day_intuition
    Historic_RUM(:, i_hisday) = sum(Historic_RUM_RES(:, (i_hisday-1)*4+1:i_hisday*4), 2)/4;
end
%% ---------------------------Normalize curve--------------------------- %%
Historic_DAF_curve = Historic_DAF/CAP_RES;
Historic_RUM_curve = Historic_RUM/CAP_RES;
%
%% -------------------Compute history day's distance-------------------- %%
for i_hisday = 1:Number_historic_day_intuition
    Picked_HIS_PE_CUS_dis(i_hisday) = ws_distance(Historic_DAF_curve(:,i_hisday),...
                                                  Historic_RUM_curve(:,i_hisday));
end
%
%% ---------------------Sort historic day's distance-------------------- %%
% Recent case
[~, Place_sorted] = sort(Picked_HIS_PE_CUS_dis, 'descend');
Place_sorted = Place_sorted(floor(Number_historic_day/2):floor(Number_historic_day/2)+1);
Picked_TRA_intuition = (Historic_day_1st_intuition - 1) + Place_sorted(1:Number_training_day_intuition);
Picked_TRA_1st_iteration  = (Picked_TRA_intuition-1)*4 + 1;
Picked_TRA_end_iteration  = Picked_TRA_intuition*4;
%% --------------------Get training day's information------------------- %%
for i_NPD = 1:Number_training_day_intuition
    % Locate the picked day
    Location = Place_sorted(i_NPD);
    % Feature (Problem exists)
    Picked_TRA_feature(:, (i_NPD-1)*4+1:i_NPD*4) =...
    Data_feature_CPO(:, Picked_TRA_1st_iteration(i_NPD):Picked_TRA_end_iteration(i_NPD));
    % Load
    for sub_i_NPD = Picked_TRA_1st_iteration(i_NPD):Picked_TRA_end_iteration(i_NPD)
        Index_NPD = (i_NPD-1)*4 + sub_i_NPD - Picked_TRA_1st_iteration(i_NPD) + 1;
        % Find the RES and load
        Picked_load_city_temp = Data_load_city{(sub_i_NPD-1)*Number_hour+1:sub_i_NPD*Number_hour, :};
        Picked_RES_temp       = Data_RES_DAF{  (sub_i_NPD-1)*Number_hour+1:sub_i_NPD*Number_hour, :};
        Country_Load = sum(Picked_load_city_temp,2);
        Country_RES  = sum(Picked_RES_temp,2);
        % Get the reserve requirement vector
        Picked_TRA_reserve_load_req(:, Index_NPD) = R_for_load*Country_Load;
        Picked_TRA_reserve_RES_req(:, Index_NPD)  = R_for_RES*Country_RES;
        % Get the completed load vector
        Picked_TRA_load_city(:, Index_NPD) = Picked_load_city_temp(:);
    end
    % Cost perfect
    Picked_TRA_cost_perfect((i_NPD-1)*4+1:i_NPD*4) =...
    Cost_perfect(Picked_TRA_1st_iteration(i_NPD):Picked_TRA_end_iteration(i_NPD));
end
end
