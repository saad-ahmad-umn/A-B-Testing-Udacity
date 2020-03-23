
library(ggplot2)
library(tidyr)
library(lubridate)

treat = read.csv('experiment_data.csv')
control = read.csv('control_data.csv')

# metrics

# set baseline value for each metrics - how these metrics behave before the change
# Udacity gives the following rough estimates for these metrics - traffic on a daily level, population
pageviews = 40000 # -> invariate, Number of unique cookies to view the course overview page that day.
clicks = 3200 # -> invariate, Number of unique cookies to click the course overview page that day.
enrolls = 660 # Number of user-ids to enroll in the free trial that day.
clcik_through_rate = 0.08 # clicks / pageviews -> invariate
Gross_Conversion = 0.20625 #  enrolls / clicks -> evaluate, Dmin = 0.01
Retention = 0.53 # payments / enrolls -> evaluate, Dmin = 0.01
Net_Conversion = 0.109313 # payments / clicks -> evaluate, Dmin = 0.0075

## data preparation
control1 = control[1:23,]
treat1 = treat[1:23,]
control1$treatment = 0
treat1$treatment = 1
data = rbind(treat1, control1)
data = separate(data, Date, c('Week', 'Date'), sep = ',')
data$click_through_rate = data$Clicks / data$Pageviews
data$Gross_Conversion = data$Enrollments / data$Clicks
data$Retention = data$Payments / data$Enrollments
data$Net_Conversion = data$Payments / data$Clicks
data$treatment = as.factor(data$treatment)
# create dummy variable for weekday & weekends, set the interaction of treatment and weekday/weekend
data$Date = parse_date_time2(data$Date, orders = "md")
data$weekdays = 0
data[data$Week %in% c('Mon', 'Tue', 'Wed', 'Thu', 'Fri'),]$weekdays = 1
data$weekend = 0
data[data$Week %in% c('Sat', 'Sun'),]$weekend = 1

# How big a sample we would need to detect the practical change they hope to find?
## Gross conversion rate baseline = 0.20625 and least detectable change = 0.01 -> delta = 0.0020625
delta_grossc = 0.20625 * 0.01
power.t.test(n=NULL,type=c("two.sample"),power=0.8,sig.level=0.1,delta=delta_grossc, sd=sd(data$Gross_Conversion))
# 6277

## retention rate baseline = 0.53 and least detectable change = 0.01 -> delta = 0.0053
delta_retention = 0.53 * 0.01
power.t.test(n=NULL,type=c("two.sample"),power=0.8,sig.level=0.1,delta=delta_retention, sd=sd(data$Retention))
# 5539

## Net conversion rate baseline = 0.109313 and least detectable change = 0.0075 -> delta = 
delta_netc = 0.109313 * 0.0075
power.t.test(n=NULL,type=c("two.sample"),power=0.8,sig.level=0.1,delta=delta_netc, sd=sd(data$Net_Conversion))
# 17201


# current sum of pageviews for treatment and control group
treatment_sumviews = sum(data[data$treatment==1,]$Pageviews)
control_sumviews = sum(data[data$treatment==0,]$Pageviews)
total_views = treatment_sumviews + control_sumviews
total_views

# descriptive analysis
ggplot(data, aes(Date, Pageviews, col = treatment)) +
  geom_line()+
  xlab('Date') +
  ylab('PageViews') +
  ggtitle('Pageviews for Control and Test Group')+
  theme(plot.title = element_text(size=22),
        axis.title.x = element_text(size=14),
        axis.title.y = element_text(size=14),
        legend.title = element_text(size=14))+
  theme(plot.title = element_text(hjust = 0.5))

ggplot(data, aes(Date, Clicks, col = treatment)) +
  geom_line()+
  xlab('Date') +
  ylab('Clicks') +
  ggtitle('Clicks for Control and Test Group')+
  theme(plot.title = element_text(size=22),
        axis.title.x = element_text(size=14),
        axis.title.y = element_text(size=14),
        legend.title = element_text(size=14))+
  theme(plot.title = element_text(hjust = 0.5))

ggplot(data, aes(Date, click_through_rate, col = treatment)) +
  geom_line()+
  xlab('Date') +
  ylab('Click Through Rate') +
  ggtitle('Click Through Rate for Control and Test Group')+
  theme(plot.title = element_text(size=22),
        axis.title.x = element_text(size=14),
        axis.title.y = element_text(size=14),
        legend.title = element_text(size=14))+
  theme(plot.title = element_text(hjust = 0.5))

## Randomization check
t.test(Pageviews ~ treatment, data = data) # p-value = 0.887
t.test(Clicks ~ treatment, data = data) # p-value = 0.9477
t.test(click_through_rate ~ treatment, data = data) # p-value = 0.8753

## Testing
# Gross Conversion
m1 = lm(Gross_Conversion ~ treatment + Pageviews + Clicks + weekend, data = data)
summary(m1)

# Net Conversion
m2 = lm(Gross_Conversion ~ treatment + Pageviews + Clicks + weekend, data = data)
summary(m2)

# Retention
m3 = lm(Gross_Conversion ~ treatment + Pageviews + Clicks + weekend, data = data)
summary(m3)

# GC - interactions
m4 = lm(Gross_Conversion ~ treatment + treatment * Pageviews + treatment * Clicks, data = data)
summary(m4)

# Net Conversion - interactions
m5 = lm(Net_Conversion ~ treatment + treatment * Pageviews + treatment * Clicks, data = data)
summary(m5)

# Retention - interactions
m6 = lm(Retention ~ treatment + treatment * Pageviews + treatment * Clicks, data = data)
summary(m6)