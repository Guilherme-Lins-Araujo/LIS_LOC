%.main example

%Guilherme Araujo
%IT Coimbra - Portugal
%29-01-2024

%Define number and position of subpanels
activated_subpanels_position = zeros(3, 5);

activated_subpanels_position(:,1) = [0, 0, 1.5]; %Center of the LIS
activated_subpanels_position(:,2) = [0, -5, 0]; %Lower left of the LIS
activated_subpanels_position(:,3) = [0, 5, 3]; %Upper right of the LIS
activated_subpanels_position(:,4) = [0, -5, 3]; %Lower right of the LIS
activated_subpanels_position(:,5) = [0, 5, 0]; %Upper left of the LIS 


Pn = logspace(-10,-6, 15); %Noise power in W, to the function
Pn_dBm = 10*log10(Pn*1e3); %Noise power in dBm, for figure



tic
e_vec = User_Localization_Noise(activated_subpanels_position, Pn);
toc

