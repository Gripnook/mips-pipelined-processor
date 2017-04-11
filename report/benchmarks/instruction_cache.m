s16 = csvread('fwd_16_64_nt.csv', 1, 1);
s32 = csvread('fwd_32_64_nt.csv', 1, 1);
s64 = csvread('fwd_64_64_nt.csv', 1, 1);

col = 2;

programs = {'bitcnt', 'exp', 'gcd', 'matrix-multiply', 'primes', 'sqrt', 'stdev'};
cpi = [sum(s16, 2) ./ s16(:, 1) ...
       sum(s32, 2) ./ s32(:, 1) ...
       sum(s64, 2) ./ s64(:, 1)];
stalls = [s16(:, col) ./ sum(s16, 2) ...
          s32(:, col) ./ sum(s32, 2) ...
          s64(:, col) ./ sum(s64, 2)];

legends = {'64B', '128B', '256B'};

figure;
bar(cpi);
legend(legends);
set(gca, 'XTickLabel', programs);
xtickangle(45);
ylabel('CPI');
grid on;

figure;
bar(stalls);
legend(legends);
set(gca, 'XTickLabel', programs);
xtickangle(45);
ylim([0 1]);
ylabel('Normalized Stalls');
grid on;
