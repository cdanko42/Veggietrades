rm(list = ls())

library(comtradr)

vowels = c("a", "b", "c", "d", "e", "f","g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z")

countrylist <- c()
for (i in vowels){
countrylist <- append(countrylist, ct_country_lookup(i, "reporter"))
}
  
countrylist <- unique(countrylist)

begin = c(1988, 1993, 1998, 2003, 2008, 2013, 2018)


veggiedatmat = matrix(data=list(), nrow=length(countrylist), ncol=length(begin))
fruitdatmat = matrix(data=list(), nrow=length(countrylist), ncol=length(begin))
merged = matrix(data=list(), nrow=length(countrylist), ncol=length(begin))

query = 0 

a = Sys.time() + 3600
for (i in 1:(length(countrylist))){
  for (j in 1:(length(begin))) {
    fruitdatmat[[i,j]] <- ct_search(reporters = as.character(countrylist[i]), 
                                    partners = "all", 
                                    trade_direction = "all",
                                    freq = "annual",
                                    start_date = as.character(begin[j]),
                                    end_date = as.character(ifelse(begin[j]== 2018, begin[j]+1, begin[j]+4)),
                                    commod_codes = c("08"))
    
    veggiedatmat[[i,j]] <- ct_search(reporters = as.character(countrylist[i]), 
                                     partners = "all", 
                                     trade_direction = "all",
                                     freq = "annual",
                                     start_date = as.character(begin[j]),
                                     end_date = as.character(ifelse(begin[j]== 2018, begin[j]+1, begin[j]+4)),
                                     commod_codes = c("07"))
    
    merged[[i, j]] <- merge(fruitdatmat[[i, j]], veggiedatmat[[i,j]], by=c("year", "trade_flow", "reporter", "partner"), all = TRUE)
    
    if(i ==1 & j ==1){
      stackmerge <- merged[[1,1]]  
    } else{
      stackmerge <- rbind(stackmerge, merged[[i,j]])  
    }
    
    # for j = 7, then end_date = as.character(begin[j]+1), i.e., 2018-2019
    
    # Will hit the query limit a few times, so should think about adding a pause line
    # Then look into the time at which can resume querying, ct_get_reset_time()
    # Then resume in loop once clock > ct_get_reset_time
    # Delay between calls
    Sys.sleep(1)
    query = query + 2
    
    ## Make sure no more than 100 calls per hour
    
    if( query %% 100 == 0){
      while(Sys.time() < a){
      }
    a = Sys.time +3600
    }
  }
}

stackmerge$trade_value_usd.x[which(is.na(stackmerge$trade_value_usd.x))] <- 0
stackmerge$trade_value_usd.y[which(is.na(stackmerge$trade_value_usd.y))] <- 0

stackmerge$trade_sum <- stackmerge$trade_value_usd.x + stackmerge$trade_value_usd.y


setwd("..")
write.csv(stackmerge, "data/fruitveggies.csv")