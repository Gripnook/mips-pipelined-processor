fwd = csvread('fwd_64_64_nt.csv', 1, 1);
nofwd = csvread('nofwd_64_64_nt.csv', 1, 1);

col = 4;

programs = {'bitcnt', 'exp', 'gcd', 'matrix-multiply', 'primes', 'sqrt', 'stdev'};
cpi = [sum(nofwd, 2) ./ nofwd(:, 1) sum(fwd, 2) ./ fwd(:, 1)];
stalls = [nofwd(:, col) ./ sum(nofwd, 2) fwd(:, col) ./ sum(fwd, 2)];

legends = {'No Forwarding', 'Forwarding'};

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
ylabel('Normalized Stalls');
grid on;
