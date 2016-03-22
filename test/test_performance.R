#!/usr/bin/env Rscript
#
# Extract performance metrics from Apache access log
#

require(ggplot2)

a <- read.table("access.log")

# Request rate
x <- table(a$V4)
reqrate <- as.data.frame(x)
names(reqrate) <- c('dt', 'rps')
reqrate$dt <- strptime(reqrate$dt, format='[%d/%b/%Y:%H:%M:%S')
p <- ggplot(data=reqrate, aes(x=dt, y=rps)) + geom_smooth() + xlab("date") + ylab("requests per second")
ggsave(p, filename="requestrate.png", width=20, height=5)

# Response time
a$dt <- strptime(a$V4, format='[%d/%b/%Y:%H:%M:%S')
a$resp <- a$V11 * 1e-6
p <- ggplot(data=a, aes(x=dt, y=resp)) + geom_smooth() + xlab("date") + ylab("response time (seconds)")
ggsave(p, filename="responsetime.png", width=20, height=5)

p <- ggplot(data=a, aes(resp)) + stat_ecdf() + scale_x_log10(breaks=c(0.1,1,10)) + xlab("response time (seconds)")+ ylab("cumulative portion")
ggsave(p, filename="responsetimecdf.png", width=5, height=5)



