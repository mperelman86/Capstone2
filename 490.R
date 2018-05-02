#####!!!!#####!!###run install.packages("rbitcoinchartsapi") and install.packages("RMySQL") FIRST
library ("rbitcoinchartsapi")
library ("RMySQL")


now <- round(as.numeric(as.POSIXct(Sys.time())))

now <- as.POSIXlt(round(as.double(now)/(15*60))*(15*60),origin=(as.POSIXlt('1970-01-01')))


if (now > as.POSIXct(Sys.time())){
  now <- now - 900
}



now <- round(as.numeric(as.POSIXct(now)))

historicTradeDataParams <- list (symbol="bitstampUSD",start = now)
historicTradeData <- GetHistoricTradeData (historicTradeDataParams)
historicTradeData$unixtime <- as.POSIXct(historicTradeData$unixtime,origin="1970-01-01")

now <- as.POSIXct(now,origin="1970-01-01")

open <- round(historicTradeData$price[1])


low <- round(min(historicTradeData$price))

high <- round(max(historicTradeData$price))
close <- 0

##################USE YOUR OWN CREDENTIALS PLEASE
mydb = dbConnect(MySQL(), user='FAKEUSER', password='FAKEPASSWORD', dbname='mysql', host='localhost')

maxQ <- paste('select * from Next where ID = (select max(ID) from Next)')

rn <- dbGetQuery(mydb, maxQ)

if (rn$Date == now){
  now <- paste("'",now,"'",sep = "")
  query3 <- paste('Update Next set High = ',high,',Low=',low,'Where Date = ',now)
  dbGetQuery(mydb, query3)
}else{
  
  before <- now - 900
  before <- round(as.numeric(as.POSIXct(before)))
  
  historicTradeDataParams <- list (symbol="bitstampUSD",start = before)
  historicTradeData <- GetHistoricTradeData (historicTradeDataParams)
  historicTradeData$unixtime <- as.POSIXct(historicTradeData$unixtime,origin="1970-01-01")
  historicTradeData <- historicTradeData[historicTradeData$unixtime < round(as.numeric(as.POSIXct(now))),]
  
  before <-  as.POSIXct(before,origin="1970-01-01")
  updateclose <- round(historicTradeData$price[length(historicTradeData$price)])
  updatelow <- round(min(historicTradeData$price))
  updatehigh <- round(max(historicTradeData$price))
  
  before <- paste("'",before,"'",sep = "")
  now <- paste("'",now,"'",sep = "")
  ##### FIRST QUERY WILL THROW AN ERROR SINCE THE LAST ROW IS NOT 15 MINUTES BEFORE THE RUN OF THIS SCRIPT
  query1 <- paste('Update Next set Close = ',updateclose,',High =',updatehigh,',Low=',updatelow,'Where Date = ',before)
  query2 <- paste('insert into Next (Open,Low,High,Date,Close) values(',open ,',',low,',',high,',',now,',',close,')')
  dbGetQuery(mydb, query1)
  dbGetQuery(mydb, query2)
}


lapply(dbListConnections( dbDriver( drv = "MySQL")), dbDisconnect)

