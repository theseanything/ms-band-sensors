classdef WindowSet
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        window
        classificationData
        numberOfWindows
        fs = 16;
        numberOfFeatures
        
        participantName
        sensorSide
        continuousAction
        
    end
    
    properties (Constant)
        features = {'avg', 'absmean', 'sd','perc10','perc25','perc50'...
            ,'perc75','perc90','minV','maxV','absAvg','skew'...
            ,'kurt','rootms','autocor','zeroCrossings'};
        
        vectorFeatures = {'avg', 'absmean', 'sd','perc10','perc25','perc50'...
            ,'perc75','perc90','minV','maxV','absAvg','skew'...
            ,'kurt','rootms','autocor','zeroCrossings'};
        
        magnitudeFeatures = {'avg', 'sd' , 'perc10',  'perc25',  'perc50'...
            ,'perc75',  'perc90', 'minV',  'maxV', 'skew', 'kurt'};
        
        otherFeatures = {'corraXY','corraXZ','corraYZ'...
                        ,'corrgXY','corrgXZ','corrgYZ'...
                        ,'corraXgX' ,'corraXgY' ,'corraXgZ'...
                        ,'corraYgX' ,'corraYgY' ,'corraYgZ'...
                        ,'corraZgX' ,'corraZgY' ,'corraZgZ'};
        
        axes = {'aX','aY','aZ','aM','gX','gY','gZ','gM'};
        
        others = {'Label','corraXY','corraXZ','corraYZ'...
                         ,'corrgXY','corrgXZ','corrgYZ'...
                         ,'corraXgX' ,'corraXgY' ,'corraXgZ'...
                         ,'corraYgX' ,'corraYgY' ,'corraYgZ'...
                         ,'corraZgX' ,'corraZgY' ,'corraZgZ'};
         
        sc = {'a','g'};
        
        names = {'accelerometer', 'gyroscope'};
        
        direction = { 'X', 'Y', 'Z'};
        
    end
    
    methods
        function ws = WindowSet(timeSeries, windowSize, overlap, label)
            
            fprintf('Building WindowSet: %s\nWindowSize: %d with %d %% overlap\n', label{1}, windowSize, overlap)
            
            % calculate interval between windows in time-series
            
                % check overlap is between 1 and 100
            if ( overlap >100 || overlap < 0)
                error('Overlap need to be between 0 and 100');
            end
            
                % calculate
            interval = windowSize - (windowSize*(overlap/100));
            
                % check if interval is valid
            if (interval == 0)
                interval = 1;
            elseif(interval > windowSize)
                interval = windowSize;
            end
           
            % calculate number of windows
            indexOfLastWindow = size(timeSeries,1)-windowSize;
            
            numofWindows = int32(floor(indexOfLastWindow/interval)+1);
            
            fprintf('\nInterval: %d \n',interval)
            
            % Preallocate structs for number of windows needed
           
             windowStructure = struct('Label',[]);
%             vectorAxisStructure = struct('type',[],'direction',[],'raw',[]);
%             magnitudeAxisStructure = struct('type',[],'direction',[],'raw',[]);
            
%             for feature = 1:size(ws.vectorFeatures, 2)
%                 vectorAxisStructure.(ws.vectorFeatures{feature}) = [];
%             end
%             
%             for feature = 1:size(ws.magnitudeFeatures, 2)
%                 magnitudeAxisStructure.(ws.magnitudeFeatures{feature}) = [];
%             end
%             
            for sensor = 1:size(ws.sc, 2)
                for axis = 1:size(ws.direction, 2)
                    for feature = 1:size(ws.vectorFeatures,2)
                        field = strcat(ws.sc{sensor}, ws.direction{axis}, ws.vectorFeatures{feature});
                        windowStructure.(field) = [];
                    end
                end
                for feature = 1:size(ws.magnitudeFeatures,2)
                    field = strcat(ws.sc{sensor}, 'M', ws.magnitudeFeatures{feature});
                    windowStructure.(field) = [];
                end
            end
            
            for other = 1:size(ws.otherFeatures, 2)
                windowStructure.(ws.otherFeatures{other}) = [];
            end

            ws.window = repmat(windowStructure, numofWindows, 1);
            
%             ws.windowSet(numofWindows) =...
%                 struct('Size',[],'Label',[],...
%                 'aX',[],'aY',[],'aZ',[],...
%                 'gX',[],'gZ',[],'gY',[],...
%                 'aM',[],'gM',[],...
%                 'corraXY',[],'corraXZ',[],'corraYZ',[],...
%                 'corrgXY',[],'corrgXZ',[],'corrgYZ',[]);

%             ws.window = repmat(struct('Label',[],...
%                 'aX',[],'aY',[],'aZ',[], 'aM',[],...
%                 'gX',[],'gZ',[],'gY',[], 'gM',[],...
%                 'corraXY',[],'corraXZ',[],'corraYZ',[],...
%                 'corrgXY',[],'corrgXZ',[],'corrgYZ',[]), numofWindows,1);
%  
            
            fprintf('Processing: %d/     ', numofWindows)
            
            % calculate the features
            windowNumber = 1;
            
            rawData = struct('aXraw', [], 'aYraw', [], 'aZraw', [], ...
                             'gXraw', [], 'gYraw', [], 'gZraw', []);
                         
            fields = fieldnames(ws.window(1));
           
                % Loop thorugh the windows
            for n = 1:interval:(size(timeSeries,1) - windowSize);
                fprintf('\b%d',windowNumber)

                ws.window(windowNumber).Label = label;
                
                endOfWindow = windowSize+n-1;
                
                %%%
                
                
                for sensor = 1:2
                    for axis = 1:3
                        
                        % create field name to for a struct reference
                        field = 1 + (axis-1) * size(ws.vectorFeatures,2) ...
                                  + (size(ws.direction,2)*size(ws.vectorFeatures,2)+size(ws.magnitudeFeatures,2)) * (sensor -1);
                        
                        
%                         (size(ws.vectorFeatures,2) *...
%                             ((sensor - 1) * (size(ws.direction, 2))) + (axis - 1));
                        
%                         ((sensor - 1) * (  * (size(ws.direction, 2)) ) )...
%                                   + (size(ws.vectorFeatures, 2) * (axis - 1))...
%                                   + ((axis - 1) + (sensor - 1) * (size(ws.direction, 2)));
                        
                        sensorLab = strcat(ws.sc{sensor}, ws.direction{axis});
                        % get index for rawData
                        dataIndex = (3 * (sensor - 1)) + axis;
                        
                        axisSeries = timeSeries(n:endOfWindow, dataIndex);
                        
                        % precalculate 
                        absDiff = abs(axisSeries(2:end) - axisSeries(1:end-1));

                        R = xcorr(axisSeries);
                        ac = max(R);
                        %[~, locs] = findpeaks(R);
                        %ac = max(16./diff(locs));

                        if isempty(ac)
                            ac = 0;
                        end

%                         ws.window(windowNumber).(strcat(field,'type')) = ws.names{sensor};
%                         ws.window(windowNumber).(strcat(field, 'direction')) = ws.direction{axis};
                        rawData.(strcat(sensorLab, 'raw')) = axisSeries;
                        ws.window(windowNumber).(fields{(field+1)}) = mean(axisSeries);
                        ws.window(windowNumber).(fields{(field+2)}) = mean(abs(axisSeries));
                        ws.window(windowNumber).(fields{(field+3)}) = std(axisSeries);
                        ws.window(windowNumber).(fields{(field+4)}) = prctile(axisSeries, 10);
                        ws.window(windowNumber).(fields{(field+5)}) = prctile(axisSeries, 25);
                        ws.window(windowNumber).(fields{(field+6)}) = prctile(axisSeries, 50);
                        ws.window(windowNumber).(fields{(field+7)}) = prctile(axisSeries, 75);
                        ws.window(windowNumber).(fields{(field+8)}) = prctile(axisSeries, 90);
                        ws.window(windowNumber).(fields{(field+9)}) = min(axisSeries);
                        ws.window(windowNumber).(fields{(field+10)}) = max(axisSeries);
                        ws.window(windowNumber).(fields{(field+11)}) = skewness(axisSeries);
                        ws.window(windowNumber).(fields{(field+12)}) = kurtosis(axisSeries);
                        ws.window(windowNumber).(fields{(field+13)}) = mean(absDiff);
                        ws.window(windowNumber).(fields{(field+14)}) = rms(axisSeries);
                        ws.window(windowNumber).(fields{(field+15)}) = ac;
                        ws.window(windowNumber).(fields{(field+16)}) = sum(abs(diff(sign(axisSeries - mean(axisSeries)))));

                    end
                    
                    
                    %field = strcat(ws.sc{sensor}, 'M');
                    field = 1 + ((size(ws.direction,2)*size(ws.vectorFeatures,2)) * (sensor)...
                              + (size(ws.magnitudeFeatures,2)*(sensor-1)));
                    
                    axisSeries = sqrt(power(rawData.(strcat(ws.sc{sensor}, 'X', 'raw')),2)...
                                    + power(rawData.(strcat(ws.sc{sensor}, 'Y', 'raw')),2)...
                                    + power(rawData.(strcat(ws.sc{sensor}, 'Z', 'raw')),2));
                    
                    ws.window(windowNumber).(fields{(field+1)}) = mean(axisSeries);
                    ws.window(windowNumber).(fields{(field+2)}) = std(axisSeries);
                    ws.window(windowNumber).(fields{(field+3)}) = prctile(axisSeries, 10);
                    ws.window(windowNumber).(fields{(field+4)}) = prctile(axisSeries, 25);
                    ws.window(windowNumber).(fields{(field+5)}) = prctile(axisSeries, 50);
                    ws.window(windowNumber).(fields{(field+6)}) = prctile(axisSeries, 75);
                    ws.window(windowNumber).(fields{(field+7)}) = prctile(axisSeries, 90);
                    ws.window(windowNumber).(fields{(field+8)}) = min(axisSeries);
                    ws.window(windowNumber).(fields{(field+9)}) = max(axisSeries);
                    ws.window(windowNumber).(fields{(field+10)}) = skewness(axisSeries);
                    ws.window(windowNumber).(fields{(field+11)}) = kurtosis(axisSeries);
                end
                
                %%%
%                 
%                 axisSeries = sqrt(power(ws.window(windowNumber).aX.raw,2)+ power(ws.window(windowNumber).aY.raw,2) + power(ws.window(windowNumber).aZ.raw,2));
%                 
%                 ws.window(windowNumber).aM = struct('type', 'accelerometer', 'direction', 'M', 'raw', axisSeries,...
%                     'avg', mean(axisSeries), 'sd',std(axisSeries) ,'perc10', prctile(axisSeries, 10),...
%                     'perc25', prctile(axisSeries, 25), 'perc50', prctile(axisSeries, 50),...
%                     'perc75', prctile(axisSeries, 75), 'perc90', prctile(axisSeries, 90),...
%                     'minV', min(axisSeries), 'maxV', max(axisSeries), 'skew',skewness(axisSeries) ,...
%                     'kurt', kurtosis(axisSeries));
%                 
%                 
%                 axisSeries = sqrt(power(ws.window(windowNumber).gX.raw,2)+ power(ws.window(windowNumber).gY.raw,2) + power(ws.window(windowNumber).gZ.raw,2));
%                 
%                 ws.window(windowNumber).gM = struct('type', 'gyroscope', 'direction', 'M', 'raw', axisSeries,...
%                     'avg', mean(axisSeries), 'sd',std(axisSeries) ,'perc10', prctile(axisSeries, 10),...
%                     'perc25', prctile(axisSeries, 25), 'perc50', prctile(axisSeries, 50),...
%                     'perc75', prctile(axisSeries, 75), 'perc90', prctile(axisSeries, 90),...
%                     'minV', min(axisSeries), 'maxV', max(axisSeries), 'skew',skewness(axisSeries) ,...
%                     'kurt', kurtosis(axisSeries));
                
                %%%%
                ws.window(windowNumber).corraXY = corr(rawData.aXraw, rawData.aYraw);
                ws.window(windowNumber).corraXZ = corr(rawData.aXraw, rawData.aZraw);
                ws.window(windowNumber).corraYZ = corr(rawData.aYraw, rawData.aZraw);
                ws.window(windowNumber).corrgXY = corr(rawData.gXraw, rawData.gYraw);
                ws.window(windowNumber).corrgXZ = corr(rawData.gXraw, rawData.gZraw);
                ws.window(windowNumber).corrgYZ = corr(rawData.gYraw, rawData.gZraw);
                
                ws.window(windowNumber).corraXgX = corr(rawData.aXraw, rawData.gXraw);
                ws.window(windowNumber).corraXgY = corr(rawData.aXraw, rawData.gYraw);
                ws.window(windowNumber).corraXgZ = corr(rawData.aXraw, rawData.gZraw);
                ws.window(windowNumber).corraYgX = corr(rawData.aYraw, rawData.gXraw);
                ws.window(windowNumber).corraYgY = corr(rawData.aYraw, rawData.gYraw);
                ws.window(windowNumber).corraYgZ = corr(rawData.aYraw, rawData.gZraw);
                ws.window(windowNumber).corraZgX = corr(rawData.aZraw, rawData.gXraw);
                ws.window(windowNumber).corraZgY = corr(rawData.aZraw, rawData.gYraw);
                ws.window(windowNumber).corraZgZ = corr(rawData.aZraw, rawData.gZraw);
                
                %area = (trapz(abs(ws.windowSet(num).aX.raw)) + trapz(abs(ws.windowSet(num).aY.raw)) + trapz(abs(ws.windowSet(num)).aZ.raw))/windowSize;
                %area = (trapz(abs(ws.windowSet(num).aX.raw)) + trapz(abs(ws.windowSet(num).aY.raw)) + trapz(abs(ws.windowSet(num)).aZ.raw))/windowSize;

                
                windowNumber = windowNumber + 1;
            end
            ws.numberOfWindows = windowNumber - 1;
            
        end
        
        
        
        %%%%
        function T = createFeatureTable(self)
            fprintf('\nBuilding table...\n\n')
            T = struct2table(self.window);
            
%             
%             
%             % preallocate array and table
%             x = cell(self.numberOfWindows + 1, 125);
%             
%             windowFields = fieldnames(self.window);
%             
%             columnNum = 1;
%             
%             for w = 1:size(windowFields,1)
%                 if (isstruct(self.window(1).(windowFields{w})))
%                     axisFields = fieldnames(self.window(1).(windowFields{w}));
%                     for a = 4:size(axisFields,1)
%                         columnName = strcat(windowFields{w}, axisFields{a});
%                         x{1,columnNum} = columnName;
%                         columnNum = columnNum + 1;
%                     end
%                 else
%                 x{1,columnNum} = windowFields{w};
%                 columnNum = columnNum + 1;
%                 end
%             end
%             
%             
% 
%             
%             %decalare column names
% %             for o = 1:size(self.others,2)
% %                 columnName = sprintf('%s',self.others{o});
% %                 columnNum = o;
% %                 x{1,columnNum} = columnName;
% %             end
%             
% 
%             
% 
%             skippedC = 0;
%             for a = 1:size(self.axes,2)
%                 for f = 1:size(self.features,2)
%                     if (isfield(self.window(1).(self.axes{a}), self.features{f}))
%                         columnName = sprintf('%s%s', self.axes{a},self.features{f});
%                         columnNum = ((a - 1) * size(self.features,2) + f) + size(self.others, 2) - skippedC;
%                         x{1,columnNum} = columnName;
%                     else
%                         skippedC = skippedC +1;
%                     end
%                 end
%             end
%             
%             
%             %             x{i+1, columnNum} = self.windowSet(i).(self.others{o});
%             
%             % Add values for each window
%             for i = 1:self.numberOfWindows
%                 for o = 1:size(self.others,2)
%                     x{i+1, o} = self.window(i).(self.others{o});
%                 end
%                 
%                 
%                 for columnNum = 8:size(x,2)
%                     x{i+1, columnNum} = self.window(i).(x{1,columnNum}(1:2)).(x{1,columnNum}(3:end));
%                 end
%                 
%                 
%                 %                 % select each non-axis feature
%                 %                 for a = 1:size(self.axes,2)
%                 %                     for f = 1:size(self.features,2)
%                 %                         if (isfield(self.windowSet(1).(self.axes{a}), self.features{f}))
%                 %                             x{i+1, columnNum} = self.windowSet(i).(self.axes{a}).(self.features{f});
%                 %                         else
%                 %                             skippedC = skippedC +1;
%                 %                         end
%                 %                     end
%                 %                 end
%             end
%             
%             
%             
%             
%             
%             
%             % create table from classification
%             C = x(2:end,:);
%             T = cell2table(C);
%             T.Properties.VariableNames = x(1:1,:);
%             
        end
    end
    
end

