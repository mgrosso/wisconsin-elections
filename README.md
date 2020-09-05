# Municipality Size, not the use of Edge voting machines, predicted Trump support in 2016 Wisconsin

## 1. Abstract

The intent of this effort was to follow up on the work of Sean Case documented here https://sean-case.github.io/avcedgetrump.html and here https://github.com/Sean-Case/WisconsinElection2016, by using fresh downloads from the elections.wi.gov, an independent code base, and independent statistical methods.

What Case found was that in Wisconsin's 2016 presidential election, counties with Edge voting machines favored Trump over Clinton, even after accounting for demographics and 2012 Romney voting patterns. He joined to demographic data from the census at the county level.

Replicating these results is of extreme importance given [broad and partially successful efforts by Russia to penetrate US election equipment and vendors](https://en.wikipedia.org/wiki/Russian_interference_in_the_2016_United_States_elections#Intrusions_into_state_election_systems) and [support Trump in the 2016 US presidential election](https://en.wikipedia.org/wiki/Russian_interference_in_the_2016_United_States_elections) are well documented and given that [Russian is currently interfering in the 2020 presidential election in favor of Trump](https://en.wikipedia.org/wiki/Russian_interference_in_the_2020_United_States_elections)

[This analysis, documented here](https://github.com/mgrosso/wisconsin-election-integrity), used simple regression to find that the size of the municipality was the biggest predictor of how Trump's support versus Clinton would differ from Romney's support vs Obama. After accounting for that, there was no remaining Edge voting machine effect. Edge machines are over represented in smaller municipalities in Wisconsin.

Wisconsin reports results at the level of groups of wards within a municipality plus county. A municipality can be a city, village, or town that may cross county boundaries, thus both municipality and county are needed to uniquely identify a set of results. That combination is referred to in this report as the municipality-county. In some cases results are released for each individual ward while in other cases multiple wards are lumped together. Wisconsin releases data about voting machines at the municipality plus county level.

This analysis was conducted at the municipality-county level and used the size of the 2016 total votes as a proxy for population; the log10 of that total vote count was used as a predictive variable in a regression analysis where the dependent variable was the increase in percentage of votes for Trump in 2016 vs Romney in 2012. The results (intercept=27.787, slope=-7.415, p < 0.001, F=833.45) were strongly significant. After accounting for this effect, there was no remaining support for the hypothesis that Edge voting machines favored one candidate in 2016 but not 2012.

TODO: describe the boundaries on how badly a voting machine could flip votes before this analysis detected it.

## 2. Previous Work

The intent of this repo is to follow up on the work of Sean Case documented here https://sean-case.github.io/avcedgetrump.html and here https://github.com/Sean-Case/WisconsinElection2016 .

That work found that counties with Edge voting machines in at least 25% of their voting centers experienced a higher than average increase in votes for Trump, even after taking account of demographic variables first. This effect wasn't found in the 2012 election, but was also found in the 2016 presidential primary. The processing work for that effort was all done in the R programming language. Individual municipality-county voting machine choices were rolled up to a county level percentage of Edge machines that was used as the independent variable.

## 3. Methods

This investigation independently retrieves the same data from elections.wi.gov, joins 2012 and 2016 results to voting equipment data, and runs a statistical analysis at the municipality level, a finer grain than the county level. A significant amount of code is devoted to joining the 2012 and 2016 results as the boundaries and names of municipalities and counties are not constant over time. Voting machine data is released at the municipality plus county, but the names used in that csv release do not always track changes to the names of counties and municipalities over time, so it is necessary to individually build up a list of errata so the join of voting machine data to results can be accurate at the most fine grained level possible. See `lib/errata.rb` for the complete list.

The Ruby programming language is used to retrieve and process the data. The statistical analysis is performed with R. All source code, retrieved data, intermediate processing files, and final result files are available in the git repo https://github.com/mgrosso/wisconsin-election-integrity/.

## 3. Results

The number of total votes in the municipality is strongly negatively correlated with support for Trump; regression was performed on the log10 of the 2016 total votes the dependent variable being the increase in percentage votes for Trump vs Romney in 2012, results were `(intercept=27.787, slope=-7.415, p < 0.001, F=833.45)`, suggesting that log10(municipality total votes) is a decent proxy for more complex cultural dynamics. After subtracting that effect, no strong voting machine effect remained.

### linear regression `log10_totalvote16` and `pct_delta`

here `pct_delta` refers to the dfference in percentage voting for Trump vs Clinton in 2016 minus the same percentage for Romney vs Obama in 2012. 
`log10_totalvote16` refers to the log base 10 of the total votes of the municipality-county in 2016.

```
> anova(lm(v3$pct_delta ~ v3$log10_totalvote16))
Analysis of Variance Table

Response: v3$pct_delta
                       Df Sum Sq Mean Sq F value    Pr(>F)
v3$log10_totalvote16    1  26713 26712.6  833.45 < 2.2e-16 ***
Residuals            1876  60127    32.1
---
Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
>
>
> lm(v3$pct_delta ~ v3$log10_totalvote16)

Call:
lm(formula = v3$pct_delta ~ v3$log10_totalvote16)

Coefficients:
         (Intercept)  v3$log10_totalvote16
              27.787                -7.415

```

### TODO: add stats for zero effect of Edge after backing out `log10_totalvote16` impact

### Caveats

  1. Turnout impacts total votes and could be a confounder, however turnout differences from one election to another are measured in single or low double digits of percentage change, while municipality populations (and thus total votes) vary over several orders of magnitude.
  2. The impact of municipality total votes on preferences for Trump over Clinton versus Romney over Obama may not be stable in future elections.

## 4. Conclusion, 

In Wisconsin, the log base 10 of total municipality votes provided a solid proxy for demographic's that favored Trump in 2016 versus Romney in 2012. Since this variable can be measured without joining

In Wisconsin in 2016 smaller municipality voted for Trump over Clinton more than they voted for Romney over Obama. The distribution of municipality size among those with Edge voting machines tilted towards smaller municipalities. This created the appearance of an Edge related large pro-Trump effect that went away once the municipality size was accounted for first.
This analysis does not disprove allegations of election impropriety; it merely finds that any vote flipping was not large enough to be detected simply by analyzing this particular set of public data. The overall margin of victory Trump had over Clinton in 2016 in Wisconsin was 22,748 votes out of nearly 3 million cast while results were reported at the level of almost 4,000 municipality, county, and ward combinations. This analysis was not sensitive enough to detect vote flipping on that scale.

## 5. Future Work

An obvious extension of this work would be to analyze the 2018 midterms and 2020 presidential elections, as well as to anlyze other states' results.

The difficulty of finding vote flipping with just aggregate statistical data only emphasizes the importance of using an election technology that can be audited, namely [hand marked paper ballots]() with carefully documented [chains of custody]() and [risk limiting audits](https://www.stat.berkeley.edu/~stark/Preprints/gentle12.pdf). Putting those methods into effect universally would reduce the need for work like this to painstakingly search for election fraud using low resolution tools. Since [US election security](https://www.americanprogress.org/issues/democracy/reports/2018/02/12/446336/election-security-50-states/)  [remains](https://www.npr.org/2020/01/29/800131854/1-simple-step-could-help-election-security-governments-arent-doing-it) [highly](https://www.govtech.com/security/Election-Security-Scandals-in-Georgia-Heighten-2020-Concerns.html) [vulnerable](https://www.washingtonpost.com/investigations/los-angeles-countys-new-voting-machines-hailed-for-accessibility-dogged-by-security-concerns/2020/03/02/fabe5108-5768-11ea-ab68-101ecfec2532_story.html) after the 2016 election, it will be advantageous to extend this kind of effort to other swing states in order to at least detect high magnitude ham-fisted vote flipping. In addition, more sophisticated statistical analysis could be applied to provide an indication of how many votes could have been flipped by any particular kind of voting machine or county administrations without leaving a statistically significant trail.
Additionally, in 2020, concerns about the Sars-Cov-2 respiratory pandemic have [dramatically increased vote by mail percentages in primaries](https://fivethirtyeight.com/features/there-have-been-38-statewide-elections-during-the-pandemic-heres-how-they-went/). This analysis didn't break out scanners versus ballot marking devices, but in analyzing the 2020 election for statistical indications of vote flipping it will be important to distinguish between the voting equipment used by in-person voters versus the optical scanners used for mail-in ballots.
