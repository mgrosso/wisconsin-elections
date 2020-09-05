1. DONE commit
2. DONE validate all rows have same size
3. DONE validate totals from csv are correct
4. investigate anything where two totalvotes are too different
5. investigate anything where vote percentages are too different
6. check if equipment list is substantially different from upstream
7. add equipment columns to csv
8. pull it up in R or python




totals from csv correct?
exact match for 2016, off by 600 for 2012

[77] pry(main)> xcsv[1..-1].map { |a| a[2].to_i }.reduce(&:+)
=> 2976150
[78] pry(main)> xcsv[1..-1].map { |a| a[11].to_i }.reduce(&:+)
=> 3089094
[79] pry(main)> ResultsParser2016.last_row_totals
=> [2976150, 1405284, 1382536, 12162, 106674, 0, 31072, 1770, 1502, 47, 11855, 284, 1, 67, 15, 80, 4, 33, 22764]
[80] pry(main)> ResultsParser2012.last_row_totals
=> [3068434, 1407966, 1620985, 4930, 20439, 0, 526, 553, 7665, 112, 88, 5170]
[81] pry(main)> 9094 - 8434
=> 660

