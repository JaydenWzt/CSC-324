library(plyr)
library(dplyr)
library(ggiraph)

logdf <- read.csv('./log.csv')

logdf <- logdf %>%
  mutate(Date = substr(Time, 6, 10),
         Start_hr = as.numeric(substr(Time, 12, 13)),
         Start_min = as.numeric(substr(Time, 15, 16)),
         End_hr = as.numeric(substr(Time, 20, 21)),
         End_min = as.numeric(substr(Time, 23, 24))) %>%
  mutate(Duration = (End_hr - Start_hr) + (End_min - Start_min)/60)

print(logdf)
par(cex.axis=0.7)
barplot(logdf$Duration, names.arg=logdf$Date ,xlab="Date", ylab="Duration(hr)", col="grey",
        main="Dates and Hours Worked on the Project", las=2)


