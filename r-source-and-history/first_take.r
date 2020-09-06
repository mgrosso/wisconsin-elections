library(ggplot2)

######################################################################
## setup. load the csv and compute a few extra vectors
######################################################################
votes  <- read.table('outputs/equipment_results_2012_2016.csv', header = TRUE, sep = ",")
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
bigger_font <- theme(text = element_text(size=24)) 
# not_red_blue_color_palette <- scale_color_brewer(palette="Accent") + scale_fill_brewer(palette="Accent")
not_red_blue_color <- scale_color_brewer(palette="Accent")
not_red_blue_fill <- scale_fill_brewer(palette="Accent")

# boxplot
png(filename="outputs/all-machines-by-pct_delta-boxplot.png", width=2048, height=1024)
g <- ggplot(v2, aes(x=v2$voting_machine, y=v2$pct_delta))
g + coord_flip() + geom_boxplot(notch = TRUE) + geom_jitter(alpha = 0.5, aes(color=v2$voting_machine, size=v2$totalvote16)) + theme(axis.text.x = element_text(angle=0, hjust = 1, vjust = 0.5)) + theme(text = element_text(size=24)) + ggtitle("By voting machine, how much more did municipalities vote for Trump in 2016 than for Romney in 2012?")
dev.off()

# # visualize overall partisan bias
# png(filename="outputs/all-machines-by-pct_delta-boxplot.png", width=2048, height=1024)
# g <- ggplot(v2, aes(x=v2$voting_machine, y=v2$pct_delta))
# sizes <- v2$totalvote16 * 10
# g + coord_flip() + geom_boxplot(notch = TRUE) + geom_jitter(alpha = 0.5, aes(color=v2$voting_machine, size=sizes)) + theme(axis.text.x = element_text(angle=0, hjust = 1, vjust = 0.5)) + theme(text = element_text(size=24)) + ggtitle("By voting machine, how much more did municipalities vote for Trump in 2016 than for Romney in 2012?")
# dev.off()
# 
# 
# # violin plot
# png(filename="outputs/all-machines-by-pct_delta-violin.png", width=2048, height=1024)
# g <- ggplot(v2, aes(x=v2$voting_machine, y=v2$pct_delta))
# g + coord_flip() + geom_violin() + geom_jitter(alpha = 0.5, aes(color=v2$voting_machine, size=v2$totalvote16)) + theme(axis.text.x = element_text(angle=0, hjust = 1, vjust = 0.5)) + theme(text = element_text(size=24))
# dev.off()
# 
# 
# # violin plot scaled by count
# g <- ggplot(v2, aes(x=v2$voting_machine, y=v2$pct_delta))
# g + geom_violin(scale="count") + geom_jitter(alpha = 0.5, aes(color=v2$voting_machine, size=v2$totalvote16))


######################################################################
## an alternate hypothesis is that being in a larger town makes you less
## likely to vote for Trump, and perhaps Edge machines are more in
## counties with smaller towns.
######################################################################

# relationship of total vote size to pct_delta
v3 <- votes_minus_outliers[,c("pct_delta", "edge", "log10_totalvote16")]
coefficients <- coef(lm(v3$pct_delta ~ v3$log10_totalvote16))
## TODO: I've been reviewing these result by looking at the console outputs but I'd
## prefer to have them in variables than can be sprintf'ed to the subtitles of images
lm(v3$pct_delta ~ v3$log10_totalvote16)
anova(lm(v3$pct_delta ~ v3$log10_totalvote16))

# residuals after accounting for total vote size
v3$tv_residuals <- coefficients[1] + v3$log10_totalvote16 * coefficients[2] - v3$pct_delta

png(filename="outputs/municipality-vs-trump-edge.png", width=2048, height=1024)
g <- ggplot(v3, aes(x=v3$log10_totalvote16, y=v3$pct_delta, color=v3$edge, size=v2$totalvote16))
g + geom_point() + geom_hline(yintercept=0) + geom_abline(intercept=coefficients[1], slope=coefficients[2], color="red") + bigger_font + labs(title="log10 of municipality votes negatively correlates with Trump percentage over Clinton minus minus Romney percentage over Obama.", subtitle="y intercept=27.787, slope=-7.415, p < 0.001, F=833.45. municipalities omitted if total votes in 2016 < 10 to avoid spurious percentage changes.") + not_red_blue_color + not_red_blue_fill
dev.off()

# looks good
png(filename="outputs/municipality-vs-trump-edge-residuals.png", width=1024, height=512)
ggplot(v3, aes(x=v3$log10_totalvote16, y=v3$tv_residuals)) + geom_point() + geom_smooth(method = "lm", se = FALSE) + labs(title="residuals of trump edge on log10 of total votes in 2016", subtitle="no visually obvious signs of a bad fit") + bigger_font
dev.off()

# lets dig in to residuals by edge
no_pro_trump_effect="There does not appear to be a pro Trump effect based on Edge voting machines in the residuals, ie: after subtracting the effect of municipality size"

png(filename="outputs/municipality-vs-trump-edge-residuals-by-edge.png", width=2048, height=1024)
ggplot(v3, aes(x=v3$log10_totalvote16, y=v3$tv_residuals, color=v3$edge, size=v2$totalvote16)) + geom_point() + geom_smooth(method = "lm", se = FALSE) + labs(title="residuals of trump edge on log10 of total votes in 2016", subtitle=no_pro_trump_effect) + bigger_font + not_red_blue_color
dev.off()

# # residuals conditioned on edge, violin
# png(filename="outputs/municipality-vs-trump-edge-residuals-by-edge.png", width=1024, height=512)
# g <- ggplot(v3, aes(x=v3$edge, y=v3$tv_residuals))
# g + geom_violin(scale="count") + geom_jitter(alpha = 0.5, aes(color=v3$edge, size=v3$log10_totalvote16)) + not_red_blue_color + bigger_font
# 
# residuals conditioned on edge, boxplot
# png(filename="outputs/municipality-vs-trump-edge-residuals-by-edge-boxplot.png", width=1024, height=512)
# ggplot(v3, aes(x=v3$log10_totalvote16, y=v3$tv_residuals, color=v3$edge, size=v2$totalvote16))
# g + geom_boxplot(notch = TRUE)
# dev.off()

# ggplot(v3, aes(x=v3$log10_totalvote16, y=v3$tv_residuals)) + geom_point(aes(color=v3$edge)) + geom_smooth(method = "lm", se = FALSE) + labs(title="residuals colored by Edge vs non-Edge")


png(filename="outputs/municipality-vs-trump-edge-residuals-by-edge-boxplot.png", width=2048, height=1024)
t <- "Trump support vs Romney support after subtracting the effect of municipality size"
st <- "After adjusting for municipality size, Edge equipment municipalities were actually somewhat less likely to support Trump more in 2016 than Romney in 2012"
g <- ggplot(v3, aes(x=v3$edge, y=v3$tv_residuals, color=v3$edge, size=v2$totalvote16))
g + geom_boxplot(notch = TRUE) + bigger_font + not_red_blue_color + not_red_blue_fill + labs(title=t, subtitle=st)
dev.off()

# + geom_jitter(alpha = 0.5, aes(color=v3$edge, size=v3$log10_totalvote16))


######################################################################
## Edge machines had fewer large municipalities than non-Edge.
######################################################################
mu_true <- mean(v3$log10_totalvote16[v3$edge == TRUE])
mu_false <- mean(v3$log10_totalvote16[v3$edge == FALSE])
edge_totalvote_avg <- mean(vmo$totalvote16[vmo$edge == TRUE])
nonedge_totalvote_avg <- mean(vmo$totalvote16[vmo$edge == FALSE])
subtitle <- sprintf("Edge machines were less likely to be installed in large municipalities, averaging %.0f  as opposed to non-Edge averaging %.0f total votes in 2016.",
    edge_totalvote_avg,
    nonedge_totalvote_avg)
title <- "log10 municipality size distributions of Edge vs non-Edge"


png(filename="outputs/municipality-size-distribution-by-edge.png", width=2048, height=1024)
# g + geom_histogram(aes(y=..density..), position="identity", alpha=0.5)+
    # geom_density(alpha=0.6, aes(y=..density..)) +
title <- "Histogram of 'log10 municipality total votes', Edge vs non-Edge"
g <- ggplot(v3, aes(x=v3$log10_totalvote16, color=v3$edge, fill=v3$edge))
g + geom_histogram(binwidth=0.1, alpha=0.5)+
    labs(title=title, subtitle=subtitle) +
    bigger_font + not_red_blue_color + not_red_blue_fill
dev.off()

subtitle_with_caveat <- sprintf("%s. Note that the lines are averages while the boxplots hinge on median so they don't line up exactly.", subtitle)

png(filename="outputs/municipality-size-vs-edge-boxplot.png", width=2048, height=1024)
g <- ggplot(v3, aes(x=v3$edge, y=v3$log10_totalvote16, color=v3$edge, fill=v3$edge))
g + geom_boxplot(notch=TRUE) + labs(title=title, subtitle=subtitle_with_caveat) +
    geom_hline(data=v3, aes(yintercept=mu_true), linetype="dashed") +
    geom_hline(data=v3, aes(yintercept=mu_false), linetype="dashed") +
    bigger_font + not_red_blue_color + not_red_blue_fill
dev.off()

png(filename="outputs/municipality-size-vs-edge-violin.png", width=2048, height=1024)
g <- ggplot(v3, aes(x=v3$edge, y=v3$log10_totalvote16, color=v3$edge, fill=v3$edge))
g + geom_violin() + labs(title=title, subtitle=subtitle) +
    geom_hline(data=v3, aes(yintercept=mu_true), linetype="dashed") +
    geom_hline(data=v3, aes(yintercept=mu_false), linetype="dashed") +
    bigger_font + not_red_blue_color + not_red_blue_fill
dev.off()

######################################################################
## Edge machines had fewer large municipalities than non-Edge.
######################################################################

v4 <- votes_minus_outliers[,c("pct_delta", "log10_totalvote16", "totalvote16", "voting_machine")]
# R mystery, this simple copy gave a warning
# v4$tv_residuals <- v3$tv_residuals
v4$tv_residuals <- coefficients[1] + v4$log10_totalvote16 * coefficients[2] - v4$pct_delta
png(filename="outputs/all-machines-by-residual-boxplot.png", width=2048, height=1024)
g <- ggplot(v2, aes(x=v4$voting_machine, y=v4$tv_residuals))
g + coord_flip() + geom_boxplot(notch = TRUE) + geom_jitter(alpha = 0.5, aes(color=v4$voting_machine, size=v4$totalvote16)) + theme(axis.text.x = element_text(angle=0, hjust = 1, vjust = 0.5)) + theme(text = element_text(size=24)) + labs(title="After accounting for municipality size, by voting machine, how much more did municipalities vote for Trump in 2016 than for Romney in 2012?", subtitle="All VotePad municipalities were in one county, all Clear Access were in another." )
dev.off()



