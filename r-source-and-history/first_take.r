library(ggplot2)

######################################################################
## setup. load the csv and compute a few extra vectors
######################################################################
votes  <- read.table('equipment_results_2012_2016.csv', header = TRUE, sep = ",")
votes$pct_rep16 <- votes$REP16/votes$totalvote16
votes$pct_rep12 <- votes$REP12/votes$totalvote12
votes$pct_delta <- 100 * (votes$pct_rep16 - votes$pct_rep12)
votes$edge <-  (votes$voting_machine  == 'Dominion (Sequoia)/Command Central-Edge')
votes$log10_totalvote16 <- log10(votes$totalvote16)

######################################################################
## since we're using percentages, exclude the 4 municipalities that
## had less than 10 votes in 2012, 3 of whom also had less than 10 in
## 2016.
######################################################################
votes_minus_outliers <- subset(votes, votes$totalvote12 > 10)
v2 <- votes_minus_outliers[,c("pct_delta", "voting_machine", "totalvote16")]
vmo <- votes_minus_outliers

######################################################################
## first, visualize the increase in votes for Trump with respect to
## voting machine in use at the municipality.
######################################################################
# boxplot
g <- ggplot(v2, aes(x=v2$voting_machine, y=v2$pct_delta))
g + geom_boxplot(notch = TRUE) + geom_jitter(alpha = 0.5, aes(color=v2$voting_machine, size=v2$totalvote16))

# violin plot
g <- ggplot(v2, aes(x=v2$voting_machine, y=v2$pct_delta))
g + geom_violin() + geom_jitter(alpha = 0.5, aes(color=v2$voting_machine, size=v2$totalvote16))

# violin plot scaled by count
g <- ggplot(v2, aes(x=v2$voting_machine, y=v2$pct_delta))
g + geom_violin(scale="count") + geom_jitter(alpha = 0.5, aes(color=v2$voting_machine, size=v2$totalvote16))


######################################################################
## an alternate hypothesis is that being in a larger town makes you less
## likely to vote for Trump, and perhaps Edge machines are more in
## counties with smaller towns.
######################################################################

# relationship of total vote size to pct_delta
v3 <- votes_minus_outliers[,c("pct_delta", "edge", "log10_totalvote16")]
coefficients <- coef(lm(v3$pct_delta ~ v3$log10_totalvote16))

g <- ggplot(v3, aes(x=v3$log10_totalvote16, y=v3$pct_delta))
g + geom_point() + geom_hline(yintercept=0) + geom_abline(intercept=coefficients[1], slope=coefficients[2])

lm(v3$pct_delta ~ v3$log10_totalvote16)
anova(lm(v3$pct_delta ~ v3$log10_totalvote16))

# residuals after accounting for total vote size
v3$tv_residuals <- coefficients[1] + v3$log10_totalvote16 * coefficients[2] - v3$pct_delta

# looks good
ggplot(v3, aes(x=v3$log10_totalvote16, y=v3$tv_residuals)) + geom_point() + geom_smooth(method = "lm", se = FALSE) + labs(title="residuals of trump edge on totalvotes", subtitle="no visually obvious signs of a bad fit")

# lets dig in to residuals by edge
# residuals conditioned on edge, violin
g <- ggplot(v3, aes(x=v3$edge, y=v3$tv_residuals))
g + geom_violin(scale="count") + geom_jitter(alpha = 0.5, aes(color=v3$edge, size=v3$log10_totalvote16))

# residuals conditioned on edge, boxplot
g + geom_boxplot(notch = TRUE) + geom_jitter(alpha = 0.5, aes(color=v3$edge, size=v3$log10_totalvote16))


# so 
ggplot(v3, aes(x=v3$log10_totalvote16, y=v3$tv_residuals)) + geom_point(aes(color=v3$edge)) + geom_smooth(method = "lm", se = FALSE) + labs(title="residuals split by Edge vs non-Edge show a bump for Trump from Edge")


g <- ggplot(v3, aes(x=v3$edge, y=v3$tv_residuals))
g + geom_boxplot(notch = TRUE) + geom_jitter(alpha = 0.5, aes(color=v3$edge, size=v3$log10_totalvote16))



mu_true <- mean(v3$log10_totalvote16[v3$edge == TRUE])
mu_false <- mean(v3$log10_totalvote16[v3$edge == FALSE])
edge_totalvote_avg <- mean(vmo$totalvote16[vmo$edge == TRUE])
nonedge_totalvote_avg <- mean(vmo$totalvote16[vmo$edge == FALSE])
subtitle <- sprintf("Municipalities with Edge machines had fewer total voters, averaging %.0f  as opposed to non-Edge averaging %.0f total votes in 2016",
    edge_totalvote_avg,
    nonedge_totalvote_avg)
title <- "log10 municipality size distributions of Edge vs non-Edge"


g <- ggplot(v3, aes(x=v3$log10_totalvote16, color=v3$edge, fill=v3$edge))
g + geom_histogram(aes(y=..density..), position="identity", alpha=0.5)+
    geom_density(alpha=0.6, aes(y=..density..)) +
    geom_vline(data=v3, aes(xintercept=mu_true), linetype="dashed") +
    geom_vline(data=v3, aes(xintercept=mu_false), linetype="dashed") +
    labs(title=title, subtitle=subtitle)

g <- ggplot(v3, aes(x=v3$edge, y=v3$log10_totalvote16, color=v3$edge, fill=v3$edge))
g + geom_boxplot(notch=TRUE) + labs(title=title, subtitle=subtitle)

