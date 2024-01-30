function [inter, error] = User_Localization(txpos, activated_subpanels_position, Pn)

%Guilherme Araujo
%IT Coimbra - Portugal
%29-01-2024

%User Localization with Large Intelligent Surfaces

%This code utilizes a pre-generated .stl file which represents a room. It
%defines a Large Intelligent Surface (LIS) located in one of the walls to
%perform localization of a user in a randomly generated position in the
%room.

%Room size: 20x10x3 (x, y and z dimensions respectively).
%The LIS is located in the YOZ wall.

%The function accepts as parameters the user's position as a 3x1 vector,
%the subpanel positions as a 3xN_c matrix, and a noise power in W.

%It returns the estimated position of the user (inter) and the estimation
%error of the system.


%% Simulation Setup


%Parameter definition ----------------------------------------------

f = 26e9; %Define frequency of operation [Hz]
lambda = 299792458/f; %Wavelength of operation [m]
Pt = 1; %Transmitted power [W].  

loc_method = "trilateration"; 
%choose between triangulation or trilateration

if loc_method == "triangulation"
    loc_method = 1;
elseif loc_method == "trilateration"
    loc_method = 0;
else
    sprintf("Error in localization method choice! Defaulting to triangulation!")
    loc_method = 1;
end

LOS_assumption = false; 
%Parameter which defines if the system is able or not to differentiate the
%incoming power from the LOS component and estimate the received power as
%only that (true); or if it considers the interference of all incoming rays
%as the total incident power (false). Is relevant only in trilateration.

lb = [0; -5; 0]; 
ub = [20; 5; 3]; %Lower and upper bounds of possible user positions, 
% as defined by the room size


Nsamp = 1e3; %Number of samples used for signal generation

N_c = size(activated_subpanels_position, 2); %Number of subpanels used in localization, as checked from input

rxArray = phased.URA([5 5], 'ElementSpacing', lambda/2);
%Definition of the template of an individual subpanel of the LIS.
%The subpanel size and form can be changed freely.


pm = propagationModel("raytracing", ...
    "CoordinateSystem","cartesian", ...
    "Method","sbr", ...
    "MaxNumReflections",2, ...
    "SurfaceMaterial","wood");

%pm is the propagation model used in this simulation.
%The SBR method is preferred here  for its lower
%complexity. Both the maximum number of reflections a ray can suffer and
%the surface material parameters can be defined.

musicazelspectrum = phased.MUSICEstimator2D('SensorArray',rxArray,...
    'OperatingFrequency',f,...
    'AzimuthScanAngles',-90:1:90,'ElevationScanAngles',-90:1:90,...
    'DOAOutputPort',true,'NumSignalsSource','Property','NumSignals',1);
%Definition of the MUSIC estimator. This is the preliminary (coarse) scan
%performed first in the AoA estimation phase. It runs through the whole
%grid of possible AoAs (in a defined frequency of operation) while looking
%for the incident ray with the highest received power.


PA = zeros(N_c,3);
PB = zeros(N_c,3);
%Variables used for storing lines information


rx = rxsite("cartesian", ...
    "Antenna", rxArray, ...
    "AntennaPosition",activated_subpanels_position);
%Positioning of the subpanels in the LIS, placing the templates rxArray at
%the centers contained in activated_subpanels_position.


%% Localization Procedure

tx = txsite("cartesian", ...
    "AntennaPosition",txpos, ...
    "TransmitterPower", Pt, ...
    "TransmitterFrequency",f);

%User definition and placement at coordinates contained in txpos.

if loc_method %Triangulation

    for ii = 1:N_c %Iterates over all subpanels


        %Beamscan ----------------------------------------------

        rays = raytrace(tx, rx(ii), pm, "Map", "room.stl");
        %Change room.stl to desired file
        %Raytracing between user and subpanels
        rays = rays{1}; %Takes rays
        ang = [rays(:).AngleOfArrival]; %AoA matrix
        PL_dB = [rays(:).PathLoss]; %Path Loss matrix, in dB
        PL = 10.^(PL_dB/10); %Path Loss matrix, in W
        Pr = Pt./PL; %Received Power matrix, in W


        signal = sensorsig(getElementPosition(rxArray)/lambda,Nsamp, ang, Pn, Pr);
        %Definition of the signal which arrives at the LIS

        [~,angest1] = musicazelspectrum(signal); %Coarse estimation of the AoA

        musicazelspectrum2 = phased.MUSICEstimator2D('SensorArray',rxArray,...
            'OperatingFrequency',f,...
            'AzimuthScanAngles',max(-90, angest1(1)-5):0.25:min(90, angest1(1)+5),...
            'ElevationScanAngles',max(-90, angest1(2)-5):0.25:min(90, angest1(2)+5),...
            'DOAOutputPort',true,'NumSignalsSource','Property','NumSignals',1);
        %Definition of the second estimator, which searches locally for the
        %highest power ray around the coarse estimation, yielding a finer AoA

        [~,angest2] = musicazelspectrum2(signal); %Fine estimation of the AoA

        %Prevent cases in which angle refining does not work
        if (isnan(angest2))
            angest = angest1;
        else
            angest = angest2;
        end



        %Lines definition--------------------------------------

        point = activated_subpanels_position(:,ii)';
        %Starting points of the lines

        az = deg2rad(angest(1));      % Azimuth angle in radians
        el = deg2rad(angest(2));   % Elevation angle in radians, measured from -z direction
        %Definition of azimuth and elevation angles relative to ZOY plane

        cos_az = cos(az);
        sin_az = sin(az);
        cos_el = cos(el);
        sin_el = sin(el);
        %Definition of cosine and sine of angles

        %ni = zeros(N_c,3);
        ni = [cos_az * cos_el, sin_az * cos_el, sin_el];
        %Direction vector of the line

        new_point = point + 25 * ni;
        %Calculation of the new points along the lines. 25 is used here as the
        %distance between the start and end points so that the lines can
        %stretch the whole dimension of the room, which is needed in
        %intersection.

        PA(ii,:) = point;
        PB(ii,:) = new_point;
        %Storage of the line points in matrices


    end

    % Line intersection

    %linePoints = [PA PB]; %Merge PA and PB
    options = optimoptions('fmincon', 'Display', 'off');
    inter = fmincon(@(x) objective_triang(x', [PA PB]), zeros(3,1), [], [], [], [], lb, ub, [], options);




    
else %Trilateration

    if LOS_assumption  %LOS component only
        sigstrlin = zeros(1,N_c);
        for ii = 1:N_c
            rays = raytrace(tx, rx(ii), pm);
            rays = rays{1}; %N rays array
            PL_dB = [rays(:).PathLoss]; %1xM Path Loss matrix, in dB
            PL = 10.^(PL_dB(1)/10); %Linear PL
            sigstrlin(ii) = Pt/PL; %Received power in W, LOS only
        end

    else %All components interfere

        sigstrdb = sigstrength(rx,tx, pm);
        sigstrlin = 10.^(sigstrdb./10); %mW
        sigstrlin = sigstrlin/1000;%W, sum of all rays

    end

    sigstrlin_noisy = sigstrlin + Pn; %Noise

    d = lambda./(4*pi*sqrt(sigstrlin_noisy/Pt)); %distance to each center

    % Spheres Intersection

    objective = @(x) sum((sqrt(sum((x - activated_subpanels_position').^2, 2)) - d').^2);
    options = optimset('Algorithm', 'interior-point', 'TolX', 1e-10);
    inter = fmincon(objective, [10 0 1.5], [], [], [], [], lb, ub, [], options);

end



%Localization estimation error
error = sqrt((inter(1) - txpos(1))^2 + (inter(2) - txpos(2))^2 + (inter(3) - txpos(3))^2);

