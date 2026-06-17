function Pest = fdicohere(Pest, dat)
%FDICOHERE - periodic (ensemble) coherence for an frd from TIME2FRF_ML.
%   Pest = fdicohere(Pest)        % uses the time data saved in Pest.UserData
%   Pest = fdicohere(Pest, dat)   % uses the time data of the iodata DAT
%
% Computes the ensemble coherence over the periods at the selected lines and
% stores it in Pest.UserData.cxy (size nl x ny x nu). For each output o and
% input i it evaluates, bin by bin from the per-period DFTs,
%   gamma^2 = |sum_p Y_{o,p} conj(U_{i,p})|^2
%             / ( (sum_p |U_{i,p}|^2) (sum_p |Y_{o,p}|^2) ).
% No Signal Processing Toolbox required (uses fft only).
%
% The lines are the excited lines ms.ex when present, otherwise the band
% [ms.harm.fl, ms.harm.fh]. The time data is taken from DAT when given, else
% from Pest.UserData.x / Pest.UserData.y (saved by time2frf_ml).
%
% See also TIME2FRF_ML, BODE_FDI.
%   Author : Wataru Ohnishi, The University of Tokyo, 2019 (rev. 2026)
%%%%
ms    = Pest.UserData.ms;
nrofs = ms.nrofs;
fs    = ms.harm.fs;

% time-domain input/output: explicit iodata wins, else the saved fields
if nargin >= 2 && ~isempty(dat)
    ed = getexp(dat, 1);
    u  = ed.InputData;   y = ed.OutputData;
else
    u  = Pest.UserData.x;  y = Pest.UserData.y;
end
nu = size(u,2);  ny = size(y,2);
M  = floor(size(u,1)/nrofs);                  % number of periods
if M < 2
    error('fdicohere:periods','need >= 2 periods for coherence.');
end

% lines to evaluate: excited lines, else the [fl,fh] band
if isfield(ms,'ex')
    sel = ms.ex(:);
else
    half1 = floor(nrofs/2)+1;
    ff = (0:half1-1)'*fs/nrofs;
    [~,kmin] = min(abs(ff-ms.harm.fl));
    [~,kmax] = min(abs(ff-ms.harm.fh));
    sel = (kmin:kmax)';
end
nl = numel(sel);

% per-period DFTs, kept only at the selected bins
Up = zeros(nl, M, nu);  Yp = zeros(nl, M, ny);
for p = 1:M
    idx = (p-1)*nrofs + (1:nrofs);
    Uf  = fft(u(idx,:));   Yf = fft(y(idx,:));
    Up(:,p,:) = Uf(sel,:);  Yp(:,p,:) = Yf(sel,:);
end

cxy = zeros(nl, ny, nu);
for o = 1:ny
    Yo  = reshape(Yp(:,:,o), nl, M);          % nl x M
    Syy = sum(abs(Yo).^2, 2);
    for i = 1:nu
        Ui  = reshape(Up(:,:,i), nl, M);      % nl x M
        Suu = sum(abs(Ui).^2, 2);
        Suy = sum(Yo.*conj(Ui), 2);
        cxy(:,o,i) = abs(Suy).^2 ./ (Suu .* Syy);
    end
end

Pest.UserData.cxy = cxy;
end
