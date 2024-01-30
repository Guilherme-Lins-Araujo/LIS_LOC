function error_vector = User_Localization_Noise(activated_subpanels_position, Pn_vector) 

%Guilherme Araujo
%IT Coimbra - Portugal
%29-01-2024

%Shows the evolution of the mean localization error over noise power 
%for users in a grid by iterating over the User_Localization_Grid function.

%The function accepts as parameters the subpanel positions (in meters) as a
% 3xN_c matrix, and a vector 1xN_Pn containing an arbitrary number of 
% levels of noise power, in W. 

%It returns a 1xN_Pn vector containing the mean estimation error of the 
%system for all defined user positions for each level of noise power.

N_Pn = length(Pn_vector);
error_vector = NaN(1, N_Pn);

parfor i = 1:N_Pn
    error_vector(i) = User_Localization_Grid(activated_subpanels_position, Pn_vector(i));
end

%This loop utilizes a parfor (from the Parallel Computing toolbox) in order
%to increase performance. If preferred, a regular for loop can also be used
