function obj = objective_triang(x, line_points)
%Objective function which intersects the lines in a LSQ manner, accepting
%as parameter the optimizable variable x

%Guilherme Araujo
%IT Coimbra - Portugal
%29-01-2024
    
    num_lines = size(line_points, 1);
    line_distances = zeros(num_lines, 1);
    for i = 1:num_lines
        p1 = line_points(i, 1:3);
        p2 = line_points(i, 4:6);
        p3 = x;
        line_distances(i) = norm(cross(p2 - p1, p3 - p1)) / norm(p2 - p1);
        %Finds the distance between x and each line 
    end

    obj = sum(line_distances.^2);
    %Minimizes the sum of the squares of the distances calculated before
end