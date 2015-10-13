function [newTable, raw] = importData(windowSize, overlap, varargin)
    newTable = table;

    num_folders = length(varargin);
    
    for i = 1:num_folders
        folderpath = varargin{i};
        
        
        dd = dir(fullfile(strcat(pwd, '/data/', folderpath , '/','*.csv')));

        metadata = strsplit(folderpath,'/');
        
        if(size(metadata,2) > 4)
            name = metadata(1);
            metadata = metadata(2:end);
            metadata(1) = name;
        end
        
        fprintf('Importing: %s\n', metadata{1})
        
        TS = csvread(dd(1).name,1,0);
        TS = TS(:,1:6);

        num_files = length(dd);
        if(num_files > 1)
            for k = 2:num_files
              nTS = csvread(dd(k).name,1,0);
              nTS = nTS(:,1:6);
              TS = [TS; nTS];
            end
        end
        
        raw = TS;

        Windows = WindowSet(TS, windowSize,overlap, metadata(1));

        currTable = Windows.createFeatureTable;
        
        
        if (i == 1)
            newTable = currTable;
        end
        
        if (i > 1)
            newTable = [newTable;currTable];
        end
    end
    
end

