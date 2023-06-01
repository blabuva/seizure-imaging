function powersd(x,fs)
%% powersd Calculates power spectral density using Welch method
%
% INPUTS:
%   ----------------------Name-Value-Pairs----------------------   %
%   Name: 'name1'     Value: Description of value including default (default = NaN)
%   Name: 'name2'     Value: Description of value including default (default = NaN)
%   Name: 'name3'     Value: Description of value including default (default = NaN)
%   ------------------------------------------------------------   %
%
% OUTPUTS:
%   output1 - Description of output variable
%
% Written by Scott Kilianski
% Updated on 6/1/2023

%   ------------------------------------------------------------   %
%% ---- Function Body Here ---- %%%

% Calculate the PSD
N = length(x);      % Length of the signal
window = hann(N);   % Window function (Hann window)
nfft = 2^8;        % Next power of 2 for efficient FFT computation
[Pxx, f] = pwelch(x, window, [], nfft, fs);  % PSD estimation
% f(1) = [];
% Pxx(1) = [];

% % Define the 1/f function
% fitted_fun = @(x, xdata) x(1) ./ (xdata.^x(2));
% 
% % Initial guess for the parameters
% x0 = [1, 1];  % Adjust these values based on your data
% 
% % Perform the curve fitting
% x = lsqcurvefit(fitted_fun, x0, f, Pxx);
% 
% % Evaluate the fitted function
% fitted_Pxx = fitted_fun(x, f);
% 
% smoothed_Pxx = smoothdata(Pxx,'movmean',5);
% Plot the PSD
figure;
plot(f, 10*log10(Pxx), 'b', 'LineWidth', 1.5);
hold on;
% plot(f, 10*log10(smoothed_Pxx), 'b', 'LineWidth', 1.5);
% plot(f, 10*log10(fitted_Pxx), 'r--', 'LineWidth', 1.5);
xlabel('Frequency (Hz)');
ylabel('Power Spectral Density (dB/Hz)');
xlim([0, max(f)]);
% legend('Original PSD', 'Fitted Curve');
grid on;
end % function end