function mean_error = User_Localization_Grid(activated_subpanels_position, Pn)

%Guilherme Araujo
%IT Coimbra - Portugal
%29-01-2024

%Iterates over the User_Localization function to find the mean error of a
%grid of users, considering a fixed subpanel disposition and noise power.

%The function accepts as parameters the subpanel positions (in meters) as a
% 3xN_c matrix and a noise power in W. It also uses as input an pre-defined
% grid of possible user positions, which can also be configured.

%It returns the mean estimation error of the system for all defined user
%positions in the desired noise power.

txpos = load("txpos_tot.mat"); 
txpos = txpos.txpos_tot; %Change txpos_tot for the name your variable is registered when using load

%Defines the grid of possible values for the user position
%Can be exchanged for any 3xN matrix with user positions contained within
%the defined room

N = size(txpos, 2); %Number of user positions in the grid


error = zeros(1, N); %Error vector with N elements

for i = 1:N
    [~,error(i)] = User_Localization(txpos(:,i), activated_subpanels_position, Pn);
    %Set condition for recalculating the user's position here based on 
    %the first estimate, if wanted
end

%Iterates over User_Localization N times to find the error of each position

mean_error = mean(error); %Calculates the mean across all N iterations

end