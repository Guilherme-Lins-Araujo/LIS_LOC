function intersectionPoint = intersectionLSQ(line_points)
%Function which finds the intesection of given lines. Relies on a objective
%function

%Guilherme Araujo
%IT Coimbra - Portugal
%29-01-2024


    lb = [0; -5; 0];  
    ub = [20; 5; 3]; 
    %Lower and upper bounds for x, y, z coordinates
    
    
    options = optimoptions('fmincon', 'Display', 'off');
    intersectionPoint = fmincon(@(x) objective(x', line_points), zeros(3,1), [], [], [], [], lb, ub, [], options);
    %optimization to find the intersection point
end