### scrapeFunctions.R    Version 1.0
### This R script should be sourced from a master R script to load the included functions and data objects.
### This script can be sourced using the following function call:
###     source("scrapeFunctions.R")
###     The call to this function presumes that the working directory folder has been set appropriately
###     using setwg("/path/to/script/folder")  
### This functions and data objects loaded in this script are:
###    getExistance(html_doc, xpath) 
###    getTextContent(html_doc, xpath)
###    getAttributeValue(html_doc, xpath, element_id)
###    
###    
###    hg_GetReviews(html_doc)
###    hg_GetRatings(html_doc)
###    hg_GetOwned(html_doc)
###    hg_GetOverallRating(html_doc)
###    
#########################################################################################################
### Functions for this script
#########################################################################################################
getExistance <- function(html_doc, xp) {
      nodes <- html_nodes(html_doc, xpath=xp)
      tmp_result <- 0
      if (length(nodes) > 0) tmp_result <- 1 
	return( tmp_result )
}
### getExistance(html_doc, xpath01)

getTextContent <- function(html_doc, xp) {
	  nodes <- html_nodes(html_doc, xpath=xp)
      tmp_result <- html_text(nodes)
      if (length(tmp_result)==0) result <- ""
	else result <- tmp_result
	return( result )
}
### getTextContent(html_doc, xpath01)

getAttributeValue <- function(html_doc, xp, element_id) {
      nodes <- html_nodes(html_doc, xpath=xp)
      tmp_result <- html_attr(nodes, element_id)
      if (length(tmp_result)==0) result <- ""
	else result <- tmp_result
	return( result )
} 
### getAttributeValue(html_doc, xpath02, "title")

### This function gets a node, then all of its immediate children.
### Then for each child node, it gets the child element attributes using the given element_id
### The function returns all results as a list
getChildAttrRatings <- function(html_doc, xp, child_xp, child_element) {
      nodes <- html_nodes(html_doc, xpath=xp)
      kids <- html_children(nodes)
      ratingSpans <- html_nodes(kids, xpath=child_xp)
      if (length(ratingSpans)==0) result <- ""
	else result <- ratingSpans 
	return( result )
} 
### getChildAttrRatings(html_doc, xpath03, xpath04, "title")

hg_GetReviews <- function(doc) {
	####Find the appropriate script tag
	scriptxpath <- "/html/body/div[2]/div[3]/script[5]"
	scriptnode <- html_nodes(doc,xpath=scriptxpath)
	if(length(scriptnode) == 0) return ("")
	scripttext <- html_text(scriptnode)
	if(scripttext == "") return ("")
			
	####Find the commentText section
	regex <- "\"commentText\":\"([^\"]*)\",\""
	result = gregexpr(regex,scripttext)
	if(length(result[[1]]) <= 0) return ("")
	
	reviews <- vector("character", length(result[[1]]))
	for (i in 1:length(result[[1]])){
		temp <- substr(scripttext, result[[1]][i], result[[1]][i] + attr(result[[1]], "match.length")[i]-1)
		#Trim garbage from beginning and end of review:
		temp <- substr(temp,16,nchar(temp)-3)
		reviews[i] <- temp 	
	}	
	return(reviews)
}
### hg_GetReviews(html_doc)



hg_getProfileJSON <- function(doc){
	
	####Find the appropriate script tag
	scriptxpath <- "/html/body/div[2]/div[3]/script[contains(text(),'pageState.pes = ')]"
	scriptnode <- html_nodes(doc,xpath=scriptxpath)
	json <- "";
	if(length(scriptnode) > 0){ 
		scriptText <- html_text(scriptnode)
		if(scriptText != ""){
			################
			##	Find the chunk of javascript that begins with "pageState.pes =" and
			##	ends with "facilityLocations";  The goal is to convert the json structure
			## 	that is in pageState.pes
			#########
			regexResult = regexec("pageState\\.pes =.*pageState\\.facilityLocations",scriptText)
			jsonString <- substr(scriptText, regexResult[[1]][1], regexResult[[1]][1] + attr(regexResult[[1]], "match.length")[1]-1)
			firstBracket <- gregexpr("\\{", jsonString)[[1]][1]
			lastBracket <- rev(gregexpr("\\}", jsonString)[[1]])[1]
			jsonString <- substr(jsonString,firstBracket,lastBracket)
			json <- fromJSON(jsonString)
		}
	}
	return (json)	
}





hg_GetRatingsReviews <- function(doc){
	
	ratingCounts <- c(0,0,0,0,0)
	dates <- c()
	ratings <- c()
	reviews <- c()
	
	####Find the appropriate script tag
	scriptxpath <- "/html/body/div[2]/div[3]/script[contains(text(),'pageState.pes = ')]"
	scriptnode <- html_nodes(doc,xpath=scriptxpath)
	if(length(scriptnode) > 0){ 
		scriptText <- html_text(scriptnode)
		if(scriptText != ""){
			################
			##	Find the chunk of javascript that begins with "pageState.pes =" and
			##	ends with "facilityLocations";  The goal is to convert the json structure
			## 	that is in pageState.pes
			#########
			regexResult = regexec("pageState\\.pes =.*pageState\\.facilityLocations",scriptText)
			jsonString <- substr(scriptText, regexResult[[1]][1], regexResult[[1]][1] + attr(regexResult[[1]], "match.length")[1]-1)
			firstBracket <- gregexpr("\\{", jsonString)[[1]][1]
			lastBracket <- rev(gregexpr("\\}", jsonString)[[1]])[1]
			jsonString <- substr(jsonString,firstBracket,lastBracket)
			json <- fromJSON(jsonString)
			
			debug("JSON OBJECT:")
			debug(json)
		
			#debug("Aggregates:")
			#debug(json$model$surveyDistribution$aggregates)
			
			#debug("Review Data:")
			#debug(json$model$comments)
			
			if(nrow(json$model$surveyDistribution$aggregates)>0){
				ratingCounts <- rev(json$model$surveyDistribution$aggregates[,"count"])
			}
			if(length(json$model$comments$results) > 0){
				if(nrow(json$model$comments$results)>0){
					dates <- json$model$comments$results[,"submittedDate"]
					dates <- as.character(as.Date(dates,"%B %d, %Y"))
					ratings <- as.character(json$model$comments$results[,"overallScore"])
					reviews <- json$model$comments$results[,"commentText"]	
				}
			}
		}
	}
	return (list(ratings=ratingCounts, reviews=data.frame(date=dates, rating=ratings, text=reviews)))	
}
### hg_GetRatings(html_doc) 

hg_GetOwned = function(doc){
	xpath <- '//*[@id="sdaon"]/div[1]/div/div/div/div[5]/div/div[2]/span/span/a'
	node <- html_nodes(doc,xpath=xpath)
	if(length(node) == 0) return(0) else return(1)
}

hg_GetOverallRating <- function(doc){
	scriptxpath <- "/html/body/div[2]/div[3]/script[5]"
	scriptnode <- html_nodes(doc,xpath=scriptxpath)
	if(length(scriptnode) == 0) return ("")
	scripttext <- html_text(scriptnode)
	if(scripttext == "") return ("")
	
	
	###Find the surveyDistribution part of javascript object
	regex <- 'overall\\":[^}]*}'
	result = regexec(regex,scripttext)
	if(length(result[[1]]) <= 0) return ("")

	str1 <- substr(scripttext, result[[1]][1], result[[1]][1] + attr(result[[1]], "match.length")[1]-1)
	if(str1 == "") return ("")

	###Get just the actualScore section
	regex <- 'actualScore\\":[^,]*'
	result <- regexec(regex,str1)

	if(length(result[[1]]) <= 0) return ("")
	value <- substr(str1, result[[1]][1], result[[1]][1] + attr(result[[1]], "match.length")[1]-1)
	value <- substr(value,14,nchar(value))

	return(value)
}
### joel-m-warren	healthgrades	dr-joel-warren-g4n42
### hg_GetOverallRating(html_doc)
### xpath01 <- '//*[@id="sdaon"]/div[1]/div/div/div/div[1]/div/div/div/div[2]/span[1]'   ### h_rating	  text
### getTextContent(html_doc, xpath2)
### xpath2 <- '//*[@id="sdaon"]/div[1]/div/div/div/div[1]/div/div/div/div[3]/span[3]'   ### h_num_ratings text
### url <- "https://www.healthgrades.com/physician/dr-joel-warren-g4n42"
### xpath2 <- '//*[@id="sdaon"]/div[1]/div/div/div/div[1]/div/div/div/div[3]/span[6]/span[1]'  ### h_num_reviews  text


### Combine ratings and reviews results x <- list(ratings=c(0,1,0,0,0), reviews="abc")  y <-  list(ratings=c(0,0,0,1,0), reviews="def") 
cResults <- function(x, y) {
   return( list(ratings=(x$ratings + y$ratings), reviews=c(x$reviews, y$reviews)) ) 
}

getRMDSRatingReviewPage <- function(url) {
	html_doc <- read_html(url, verbose=FALSE)
	dates <- c();
	ratings <- c();
	reviews <- c();
	
	ratingSpans <- html_nodes(html_doc, xpath='//*[@id="left-content"]/span/div/span/span[2]/span/span/span')
	if(length(ratingSpans) > 0){
		dates <- trimws(getTextContent(html_doc,'//*[@class="rating"]//*[contains(@class,"rating-comment-created")]/a/span[2]'))
		dates <- as.character(as.Date(dates,"%B %d, %Y"))
		ratings <-	trimws(getAttributeValue(html_doc, '//*[@class="rating"]//*[@class="star-rating"]', 'title'))
		reviews <- trimws(getTextContent(html_doc, '//*[@class="rating"]//*[@class="rating-comment-body"]/span'))		
	}
	
	return(data.frame(date=dates, rating=ratings, text=reviews, stringsAsFactors=FALSE))	
}

# ratings spans//*[@id="left-content"]/span/div/span/span[2]/span/span/span
# star rating:  //*[@class="rating"]//*[@class="star-rating"]
# text: //*[@class="rating"]//*[@class="rating-comment-body"]/span
# date: //*[@class="rating"]//*[contains(@class,"rating-comment-created")]/a/span[2]
	
#	ratsSpanChildrenXP <- 'div[1]/div[1]/div[2]/span/span' 
#	ratingsParent <- html_nodes(html_doc, xpath=ratsSpanXP )
#	ratingsSpans <- html_children(ratingsParent)
#	data <- data.frame(date=c(), rating=c(), text=c(), stringsAsFactors=FALSE)
#	if (length(ratingsSpans)==0){ 
#		result <- list(ratings=c(0,0,0,0,0), reviews="") 
#	} else { 
#		ratingNodes <- html_nodes(ratingsSpans, xpath=ratsSpanChildrenXP )
#		ratings <- as.numeric(html_attr(ratingNodes , "title"))
#		if (length(ratings)==0) { 
#			num5 <- num4 <- num3 <- num2 <- num1 <- 0 
#		} else {
#			num5 <- length(which(ratings >= 4.5))
#			num4 <- length(which(ratings < 4.5 & ratings >= 3.5))
#			num3 <- length(which(ratings < 3.5 & ratings >= 2.5))
#			num2 <- length(which(ratings < 2.5 & ratings >= 1.5))
#			num1 <- length(which(ratings < 1.5))
#		}
#		resultRatings <- c(num1, num2, num3, num4, num5)
#		reviewsNodes <- html_nodes(ratingsSpans, xpath="div[1]/div[2]/p[1]/span" )
#		responseNodes <- html_nodes(ratingsSpans, xpath="div[1]/div[3]/p[1]/span/span" ) ### Not using these yet
#		reviews <- html_text(reviewsNodes)
#		result <- list(ratings=resultRatings, reviews=reviews) 
#	}
#	if (is.null(result )) result <- list(ratings=c(0,0,0,0,0), reviews="") 
#	return( data )
#}
### url <- "https://www.ratemds.com/doctor-ratings/171094/Dr-Mitch-Freeman-YUMA-AZ.html?page=28"

### pageReviews <- getVitalsReviewPage(pageURL) 
### tmpReviews <- cReviews(tmpReviews, pageReviews )

### ratemds get ratings and reviews
getRMDSRatingsReviews <- function(num, url) {  
	num <- as.numeric(num)
	reviewInfo <- data.frame(date=c(), rating=c(), text=c(), stringsAsFactors=FALSE)
	num5 <- num4 <- num3 <- num2 <- num1 <- 0 
	
	if (is.na(num) | is.null(num)) num <- 0

	if (num==1) {
		tmpResult <- getRMDSRatingReviewPage(url)
		reviewInfo <- rbind(reviewInfo,tmpResult)
		
		#if (is.null(tmpResult)) tmpResult <- list(ratings=c(0,0,0,0,0), reviews="") 
		#return( tmpResult  )         
	}
	if (num > 1) {
		#print(paste0("num: ", num, " type: ", typeof(num)))
		numPages <- ceiling(num / 10)
		for (i in 1:numPages) {
			pageURL <- paste0(url, "?page=", i)
			pageResult <- getRMDSRatingReviewPage(pageURL)
			reviewInfo <-rbind(reviewInfo, pageResult)
		}
	}

	if(nrow(reviewInfo)> 0){
		num5 <- nrow(reviewInfo[as.numeric(reviewInfo$rating) >= 4.5,])
		num4 <- nrow(reviewInfo[as.numeric(reviewInfo$rating) >= 3.5 & as.numeric(reviewInfo$rating) < 4.5,])
		num3 <- nrow(reviewInfo[as.numeric(reviewInfo$rating) >= 2.5 & as.numeric(reviewInfo$rating) < 3.5,])
		num2 <- nrow(reviewInfo[as.numeric(reviewInfo$rating) >= 1.5 & as.numeric(reviewInfo$rating) < 2.5,])
		num1 <- nrow(reviewInfo[as.numeric(reviewInfo$rating) < 1.5,])
	}

	return (list(ratings=c(num1, num2, num3, num4, num5), reviews=reviewInfo))
}



### num <- 48   i <- 2  url <- aURL

getVitalsReviewPage <- function(url)  {
   html_doc <- read_html(url, verbose=FALSE)
   ##//*[@id="reviewPage"]/div[4]/div[2]
   #revNodeXP <- '//*[@id="reviewPage"]/div[4]/div[2]'
   #revParent <- html_nodes(html_doc, xpath=revNodeXP )
   #revDivNodes <- html_children(revParent)
   
   revNodeXP <- "//div[contains(@class,'individualReviews')]"
   revNodes <- html_nodes(html_doc, xpath=revNodeXP)
   ##debug("Number of reviews on this page:")
   ##debug(length(revNodes))
   
   ## Get the review date  //*[@id="reviewPage"]/div[4]/div[2]/div[1]/div[1]/div[2]/div
   reviewDate <- as.character(as.Date(gsub("st,|nd,|rd,|th,", ",", getTextContent(revNodes, 'div[1]/div[2]/div')), "%B %d, %Y"))
   
   ## Get the review rating  //*[@id="reviewPage"]/div[4]/div[2]/div[1]/div[1]/div[1]/span[2]
   reviewRating <- gsub(" of .*", "", getTextContent(revNodes, 'div[1]/div[1]/span[2]'))
   ##reviewRating <- gsub(pattern = "\n", replacement = "", reviewRating, fixed = TRUE )
   reviewRating <- str_trim(reviewRating)   
   
   ## Get the review text
   reviewText <- getTextContent(revNodes, 'div[3]/div/div') 
   reviewText <- gsub(pattern = "\n", replacement = "", reviewText, fixed = TRUE )
   reviewText <- str_trim(reviewText)
   

   return(data.frame(date=reviewDate, rating=reviewRating, text=reviewText, stringsAsFactors=FALSE))
}
### getVitalsReviewPage("http://www.vitals.com/doctors/Dr_Franklin_Richards/reviews?page=1")


getVitalsRatingsReviews <- function(numRatings, numReviews, url) { 
   numRatings <- as.numeric(numRatings)
   numReviews <- as.numeric(numReviews)
   
   if (is.na(numReviews) | is.null(numReviews)) numReviews <- 0
   aURL <- gsub(pattern = ".html", replacement = "/reviews", url, fixed = TRUE )
   
   
   xp5 <- '//*[@id="reviewPage"]/div[2]/div/div/div[1]/div/ul/li[1]/div[2]/div[2]/span'
   xp4 <- '//*[@id="reviewPage"]/div[2]/div/div/div[1]/div/ul/li[2]/div[2]/div[2]/span'
   xp3 <- '//*[@id="reviewPage"]/div[2]/div/div/div[1]/div/ul/li[3]/div[2]/div[2]/span'
   xp2 <- '//*[@id="reviewPage"]/div[2]/div/div/div[1]/div/ul/li[4]/div[2]/div[2]/span'
   xp1 <- '//*[@id="reviewPage"]/div[2]/div/div/div[1]/div/ul/li[5]/div[2]/div[2]/span'
   html_doc <- read_html(aURL, verbose=FALSE)
   
   tmpRating <- c("0","0","0","0","0")
   tmpRating[5] <- getTextContent(html_doc, xp5) 
   tmpRating[4] <- getTextContent(html_doc, xp4)
   tmpRating[3] <- getTextContent(html_doc, xp3)
   tmpRating[2] <- getTextContent(html_doc, xp2)
   tmpRating[1] <- getTextContent(html_doc, xp1)
   tmpRating <- as.numeric(gsub(pattern = "%", replacement = "", tmpRating, fixed = TRUE ))
      
   resultRatings <- round((numRatings * tmpRating / 100), digits = 0)
   
   reviewInfo <- data.frame(date=c(), rating=c(), text=c(), stringsAsFactors=FALSE)
   ##resultReviews <- vector("character")
   if (numReviews > 0) {
      numPages <- ceiling(numReviews / 10)
      for (i in 1:numPages) {
         pageURL <- paste0(aURL, "?page=", (i-1))
         pageReviews <- getVitalsReviewPage(pageURL) 
         reviewInfo <- rbind(reviewInfo, pageReviews)
         ##resultReviews <- c(resultReviews, pageReviews )
      }
   }
   debug("REVIEWS:")
   debug(reviewInfo)
   
   
   
   
   result <- list(ratings=resultRatings, reviews=reviewInfo) 
   return( result )
}



yelp_GetReviews <- function(num, url) {  
	reviewInfo <- data.frame(date=c(), rating=c(), text=c(), stringsAsFactors=FALSE)
	totalNumRatings <- as.numeric(num)
	
	numPages <- ceiling(totalNumRatings/20)
	for (i in 1:numPages) {
		pageURL <- paste0(url, "?start=", (i*20)-20)
		pageResult <- yelp_GetReviewPage(pageURL)
		reviewInfo <-rbind(reviewInfo, pageResult)
	}	

	return (reviewInfo)
}



yelp_GetReviewPage <- function(url) {
	html_doc <- read_html(url, verbose=FALSE)
	dates <- c();
	ratings <- c();
	reviews <- c();
	
	ratings <- substr(trimws(getAttributeValue(html_doc, '//*[@class="review review--with-sidebar"]//*[@class="review-content"]/div[1]/div[1]/div[1]', 'title')),1,3)
	
	debug("GET REVIEW PAGE -> RATINGS")
	debug(ratings)
	
	dates <- trimws(getTextContent(html_doc, '//*[@class="review review--with-sidebar"]//*[@class="review-content"]/div[1]/span'))
	dates <- as.character(as.Date(dates,"%m/%d/%Y"))
	
	debug("GET REVIEW PAGE -> DATES")
	debug(dates)
	
	reviews <- trimws(getTextContent(html_doc, '//*[@class="review review--with-sidebar"]//*[@class="review-content"]/p[1]'))
	
	debug("GET REVIEW PAGE -> REVIEWS")
	debug(reviews)
			
	return(data.frame(date=dates, rating=ratings, text=reviews, stringsAsFactors=FALSE))	
}

### num <- 48   i <- 2  url <- aURL
### url <- "http://www.vitals.com/doctors/Dr_Franklin_Richards.html"
###    ratTxt <- c("0%","0%","0%","0%","0%")
