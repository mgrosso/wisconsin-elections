votes  <- read.table('y.csv', header = TRUE, sep = ",")
plot(votes)
votes
votes.pct_rep16 <- votes.REP16/votes.totalvote16
votes$pct_rep16 <- votes$REP16/votes$totalvote16
votes$pct_rep12 <- votes$REP12/votes$totalvote12
votes$pct_delta <- votes$pct_rep16 - votes$pct_rep12
plot(votes$voting_machine, votes$pct_delta
)
plot(votes$voting_machine, votes$pct_delta)
plot(votes$voting_machine ~ votes$pct_delta)
plot(votes$pct_delta ~ votes$voting_machine)
plot(votes$pct_delta ~ votes$totalvote16)
abline(0, 0, col='black')
plot(votes$pct_delta ~ log(votes$totalvote16))
library(ggplot2)
install.packages("ggplot2")
library(ggplot2)
help(ggplot2)
ggplot()
aes()
ggsave()
ggplot(votes$pct_delta ~ log(votes$totalvote16))
ggplot(votes)
geom_boxplot()
ggsave()
ggsave('x.png')
#v2 <- votes[,c(
colnames(votes)
v2 <- votes[,c("pct_delta", "voting_machine", "totalvote16")]
ggplot(v2)
geom_boxplot()
ggsave()
ggsave('x.png')
g <- ggplot(v2)
g + geom_boxplot(fill="red")
g <- ggplot(v2, y = v2$pct_delta)
g + geom_boxplot(fill="red")
g <- ggplot(v2, aes(x = v2$voting_machine, y = v2$pct_delta))
g + geom_boxplot(fill="red")
g + geom_boxplot(fill="red") + geom_jitter(alpha = 0.5, aes(color=v2$voting_machine))
g + geom_boxplot(fill="red") + geom_jitter(alpha = 0.5, aes(color=v2$voting_machine, size=v2$totalvote16))
g + geom_violin() + geom_jitter(alpha = 0.5, aes(color=v2$voting_machine, size=v2$totalvote16))
g + geom_boxplot(notch=TRUE) + geom_jitter(alpha = 0.5, aes(color=v2$voting_machine, size=v2$totalvote16))
g + geom_violin() + geom_jitter(alpha = 0.5, aes(color=v2$voting_machine, size=v2$totalvote16))
lm(v2)
anova(lm(v2))
votes$edge <- votes$voting_machine == "Dominion (Premier)-Accuvote TSX/ES&S ExpressVote"
votes$edge
v3 <- votes[,c("pct_delta", "edge")]
g <- ggplot(v3, aes(x = v3$edge, y = v3$pct_delta))
g + geom_boxplot(notch=TRUE) + geom_jitter(alpha = 0.5, aes(color=v2$voting_machine))
g + geom_boxplot(notch=TRUE) + geom_jitter(alpha = 0.5, aes(color=v3$edge))
votes$voting_machine
votes$edge <- strcmp(votes$voting_machine, 'Dominion (Premier)-Accuvote TSX/ES&S ExpressVote')
votes$edge <-  (votes$voting_machine == 'Dominion (Premier)-Accuvote TSX/ES&S ExpressVote')
votes$edge
votes$edge <-  (votes$voting_machine != 'Dominion (Premier)-Accuvote TSX/ES&S ExpressVote')
votes$edge
votes$voting_machine
"ES&S Automark" == "ES&S Automark"
votes$edge <-  (votes$voting_machine  = 'Dominion (Sequoia)/Command Central-Edge')
votes$edge
  
votes$voting_machine
votes2  <- read.table('y.csv', header = TRUE, sep = ",")
votes$voting_machine <- votes2$voting_machine
votes$edge <-  (votes$voting_machine  == 'Dominion (Sequoia)/Command Central-Edge')
votes$edge
v3 <- votes[,c("pct_delta", "edge")]
g <- ggplot(v3, aes(x = v3$edge, y = v3$pct_delta))
g + geom_boxplot(notch=TRUE) + geom_jitter(alpha = 0.5, aes(color=v3$edge)) 
anova(lm(v3))
ttest(lm(v3))
ptest(lm(v3))
g + geom_violin() + geom_jitter(alpha = 0.5, aes(color=v3$edge)) 
g + geom_boxplot(notch=TRUE) + geom_jitter(alpha = 0.5, aes(color=v3$edge)) 
g + geom_point()
v4 <- v3
#v4$totalvotes16 
columns(votes)
colnames(votes)
v4$totalvote16 <- votes$totalvote16
g <- ggplot(v4, aes(x = v4$totalvote16, y = v4$pct_delta, col=v4$edge))
g + geom_plot()
g + geom_point()
g <- ggplot(v4, aes(x = ln(v4$totalvote16), y = v4$pct_delta, col=v4$edge))
g <- ggplot(v4, aes(x = ln(v4$totalvote16), y = v4$pct_delta, col=v4$edge, alpha=0.2))
g + geom_point()
g <- ggplot(v4, aes(x = log(v4$totalvote16), y = v4$pct_delta, col=v4$edge, alpha=0.2))
g + geom_point()
g <- ggplot(v4, aes(x = log(v4$edge), y = v4$totalvote16, col=v4$edge, alpha=0.2))
g + geom_point()
v4$log_vote <- log(v4$totalvote16)
g <- ggplot(v4, aes(x = log(v4$edge), y = v4$log_vote, col=v4$edge, alpha=0.2))
g + geom_point()
g <- ggplot(v4, aes(x = v4$edge, y = v4$log_vote, col=v4$edge, alpha=0.2))
g + geom_point()
g + geom_boxplot()
g + geom_boxplot(notch = TRUE)
lm(v4$pct_delta ~ v4$totalvote16 + v4$voting_machine)
lm(v4$pct_delta ~ v4$totalvote16 + v4$edge)
summary(lm(v4$pct_delta ~ v4$totalvote16 + v4$edge))
aftertv <- 4.902e-02 + -1.301e-06 * v4$totalvote16
lm(formula = aftertv ~ v4$edge)
summary(lm(formula = aftertv ~ v4$edge))
plot(lm(formula = aftertv ~ v4$edge))
v5
v5 <- v4[,c("edge") 
]
v5$aftertv <- aftertv
v5$aftertv
g <- ggplot2(v5)
g <- ggplot(v5)
v5 <- v4[,c("edge", "pct_delta") ]
v5$aftertv <- 4.902e-02 + -1.301e-06 * v4$totalvote16
g <- ggplot(v5, aes(x = v5$edge, y = v5$aftertv))
g + geom_box()
g + geom_boxplot()
histogram(v5$aftertv)
hist(v5$aftertv)
g <- ggplot(v5, aes(x = v5$edge, y = v5$aftertv))
g + geom_violin()
v5$logaftertv <- log(4.902e-02 + -1.301e-06 * v4$totalvote16)
v5$logaftertv <- log(1 + 4.902e-02 + -1.301e-06 * v4$totalvote16)
g <- ggplot(v5, aes(x = v5$edge, y = v5$logaftertv))
g + geom_violin()
v5$logaftertv <- log(1 + 4.902e-02 + -1.301e-06 * v4$totalvote16)
g <- ggplot(v5, aes(x = v5$edge, y = v5$logaftertv))
g + geom_violin()
v5$logaftertv <- 1 + 4.902e-02 + -1.301e-06 * v4$totalvote16
g + geom_violin()
v5$logaftertv <- (1 + 4.902e-02 + -1.301e-06 * v4$totalvote16)^2
g <- ggplot(v5, aes(x = v5$edge, y = v5$logaftertv))
g + geom_violin()
v5$logaftertv <- (1 + 4.902e-02 + -1.301e-06 * v4$totalvote16)^10
g <- ggplot(v5, aes(x = v5$edge, y = v5$logaftertv))
g + geom_violin()
v6 <- subset(v5, v5$logaftertv > 1)
g <- ggplot(v6, aes(x = v6$edge, y = v6$logaftertv))
g + geom_violin()
g + geom_boxplot(notches=TRUE)
g + geom_boxplot(notche=TRUE)
g + geom_boxplot(notch=TRUE)
v6 <- subset(v5, v5$logaftertv > 1.4)
g <- ggplot(v6, aes(x = v6$edge, y = v6$logaftertv))
g + geom_boxplot(notch=TRUE)
summary(lm(formula = aftertv ~ v4$edge))
plot(summary(lm(formula = aftertv ~ v4$edge)))
ggplot2(summary(lm(formula = aftertv ~ v4$edge)))
 history(max.show=Inf)
savehistory('first_take_history.r')
