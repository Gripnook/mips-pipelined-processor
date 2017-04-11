nottaken = csvread('fwd_64_64_nt.csv', 1, 1);
taken = csvread('fwd_64_64_t.csv', 1, 1);
onebit = csvread('fwd_64_64_1bit_4.csv', 1, 1);
twobit = csvread('fwd_64_64_2bit_4.csv', 1, 1);
correlating = csvread('fwd_64_64_2_2_4.csv', 1, 1);
tournament = csvread('fwd_64_64_tournament_4.csv', 1, 1);

col = 5;

programs = {'bitcnt', 'exp', 'gcd', 'matrix-multiply', 'primes', 'sqrt', 'stdev'};
cpi = [sum(nottaken, 2) ./ nottaken(:, 1) ...
       sum(taken, 2) ./ taken(:, 1) ...
       sum(onebit, 2) ./ onebit(:, 1) ...
       sum(twobit, 2) ./ twobit(:, 1) ...
       sum(correlating, 2) ./ correlating(:, 1) ...
       sum(tournament, 2) ./ tournament(:, 1)];
stalls = [nottaken(:, col) ./ sum(nottaken, 2) ...
          taken(:, col) ./ sum(taken, 2) ...
          onebit(:, col) ./ sum(onebit, 2) ...
          twobit(:, col) ./ sum(twobit, 2) ...
          correlating(:, col) ./ sum(correlating, 2) ...
          tournament(:, col) ./ sum(tournament, 2)];

legends = {'Not Taken', 'Taken', 'One-Bit', 'Two-Bit', 'Correlating', 'Tournament'};

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
