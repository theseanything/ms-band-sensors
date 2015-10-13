% [pxx,f] = periodogram(normX,[],[],fs);

nfft = length(normX);

[pxx,f] = periodogram(normX,[],nfft);

[~, locs] = findpeaks(pxx);
max(locs/32)



fs = 32;

t = (0:length(window.X.raw) - 1)/fs;

Fs = 32;                    % Sampling frequency
T = 1/Fs;                     % Sample time
L = 200;                     % Length of signal
t = (0:L-1)*T;                % Time vector
% Sum of a 50 Hz sinusoid and a 120 Hz sinusoid
y = normX;     % Sinusoids plus noise


NFFT = 2^nextpow2(L); % Next power of 2 from length of y
Y = fft(y,NFFT)/L;
[~, locs] = findpeaks(2*abs(Y(1:NFFT/2+1)));
max(locs/32)


% f = Fs/2*linspace(0,1,NFFT/2+1);

% Plot single-sided amplitude spectrum.
% plot(f,2*abs(Y(1:NFFT/2+1))) 
% title('Single-Sided Amplitude Spectrum of y(t)')
% xlabel('Frequency (Hz)')
% ylabel('|Y(f)|')


% [pxx,f] = periodogram(normX,[],[],fs);
% 
% plot(f,pxx)
% ax = gca;
% ax.XLim = [0 10];
% xlabel('Frequency (cycles/second)')
% ylabel('Magnitude')

% 
%  x = table2array(CT(1:end,2:end));
%  y = table2array(CT(1:end,1:1:1));
% % 
% holdoutCVP = cvpartition(y, 'Holdout', 10);
% xTrain = x(holdoutCVP.training,:);
% yTrain = y(holdoutCVP.training);
% 
% xTest = x(holdoutCVP.test,:);
% yTest = y(holdoutCVP.test);
% 
% dataTrainG1 = xTrain(grp2idx(yTrain)==1,:);
% dataTrainG2 = xTrain(grp2idx(yTrain)==2,:);
% 
% [h,p,ci,stat] = ttest2(dataTrainG1,dataTrainG2,'Vartype','unequal');
% 
% 
% ecdf(p);
% xlabel('P value');
% ylabel('CDF value')
% 
% 
% 



% opts = statset('display','iter');
% 
% [fs,history] = sequentialfs(@SVM_class_fun,x,y,'options',opts)
 