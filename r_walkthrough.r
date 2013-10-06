# libraries - load these before you get started
library(ggplot2)
library(Hmisc)
library(forecast)
library(RMySQL)

#  load data
# this is a basic file, notice it loads from a url
# this will create a dataframe. read about these. I use dataframes almost all the time. these are like a table in a database.
timeSeries <- read.csv("http://dl.dropbox.com/u/23226147/time_series_test.csv")

# here are some handy functions for evaluating the data you imported. select each one after the comment.
# head(timeSeries)
# summary(timeSeries)
# str(timeSeries)
# describe(timeSeries)

# some basic field manipulation assignments
# convert a field to a date format
timeSeries$Date <- as.Date(timeSeries$Date)
# rename a column
timeSeries$Revenue <- timeSeries$Bookings
# delete a column
timeSeries$Bookings <-NULL

# lets start by creating a basic scatter plot
# plot orders over time with a regression line and confidence bands
ggplot(timeSeries, aes(x=Date, y=Orders)) + geom_point() + stat_smooth() 

# now we need to create some dates that extend into the future so we can forecast them
date.seq <- as.Date("2010-10-18"):as.Date("2010-11-30")
# print(date.seq)

# next we use forecast to create future results
uv.results <- data.frame(forecast(timeSeries$Unique.Visitors,44,level=c(80,95), fan=FALSE))
carts.results <- data.frame(forecast(timeSeries$Carts,44,level=c(80,95), fan=FALSE))
orders.results <- data.frame(forecast(timeSeries$Orders,44,level=c(80,95), fan=FALSE))
revenue.results <- data.frame(forecast(timeSeries$Revenue,44,level=c(80,95), fan=FALSE))

# create basic forecasts for each column and create a new dataframe with all our data
new.dates <- data.frame(days = as.Date(date.seq, origin = "1970-01-01"), uv.results$Point.Forecast, carts.results$Point.Forecast, orders.results$Point.Forecast, revenue.results$Point.Forecast)

# head(new.dates)

# now we have a dataframe of future dates and forecast then add it to your existing dates
names(new.dates) <- list(a="Date", b="Unique.Visitors", c="Carts", d="Orders", e="Revenue")
results.fc <- rbind(timeSeries, new.dates)

print(results.fc)
str(results.fc)

# create a better visual with our new forecast, notice we are changing the color of the dots to align with revenue
ggplot(results.fc, aes(x = Date, y = Unique.Visitors)) +
    geom_point(aes(colour = Revenue)) +
    stat_smooth()

# now save your sweet graph
ggsave("/filepath/visitors_bookings_timeSeries_results.png",width=4,height=2)
	
# now lets save this great data out to our MySQL database
# create the connection (assuming this database already exists)
my_db <- dbConnect(MySQL(), user="root", dbname="my_db")
# writing the data to a new table called "forecast_data"
dbWriteTable(my_db, "forecast_data", results.fc, append=FALSE)
# disconnect from db
dbDisconnect(my_db)