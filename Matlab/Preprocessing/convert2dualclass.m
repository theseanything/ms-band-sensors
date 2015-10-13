function table = convert2dualclass(table, className, className2)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    for i = 1:height(table)
        if (~strcmp(table{i,1}, className) && ~strcmp(table{i,1}, className2))
            table.Label{i} = 'other';
        end
    end
end

