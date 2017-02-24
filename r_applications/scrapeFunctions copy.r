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

hg_GetRatings <- function(doc){
	####Find the appropriate script tag
	scriptxpath <- "/html/body/div[2]/div[3]/script[5]"
	scriptnode <- html_nodes(doc,xpath=scriptxpath)
	if(length(scriptnode) == 0) return ("")
	scripttext <- html_text(scriptnode)
	if(scripttext == "") return ("")

	###Find the surveyDistribution part of javascript object
	regex <- "surveyDistribution[^]]*]"
	result = regexec(regex,scripttext)
	if(length(result[[1]]) <= 0) return ("")

	text1 <- substr(scripttext, result[[1]][1], result[[1]][1] + attr(result[[1]], "match.length")[1]-1)
	regex <- "\\[.*"
	result <- regexec(regex,text1)
	if(length(result[[1]]) <= 0) return ("")
	
	text2 <- substr(text1, result[[1]][1], result[[1]][1] + attr(result[[1]], "match.length")[1]-1)
	regex <- "\\{[^\\}]*\\}"
	result <- gregexpr(regex,text2)
	if(length(result[[1]]) <= 0) return ("")
	
	data <- vector("character", length(result[[1]]))
	for (i in 1:length(result[[1]])){
		groupstr <- substr(text2, result[[1]][i], result[[1]][i] + attr(result[[1]], "match.length")[i]-1)
		regex <- ":[0-9]*}"
		result2 <- regexec(regex,groupstr)
		countstr <- substr(groupstr, result2[[1]][1], result2[[1]][1] + attr(result2[[1]], "match.length")[1]-1)
		count <- substr(countstr,2,nchar(countstr)-1)
		data[i] <- count	
	}	
	return(rev(data))	
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
   ratsSpanXP <- '//*[@id="left-content"]/span/div/span/span[2]/span/span'
   ratsSpanChildrenXP <- 'div[1]/div[1]/div[2]/span/span' 
   ratingsParent <- html_nodes(html_doc, xpath=ratsSpanXP )
   ratingsSpans <- html_children(ratingsParent)
   if (length(ratingsSpans)==0) result <- list(ratings=c(0,0,0,0,0), reviews="") 
   else { 
      ratingNodes <- html_nodes(ratingsSpans, xpath=ratsSpanChildrenXP )
      ratings <- as.numeric(html_attr(ratingNodes , "title"))
      if (length(ratings)==0) { num5 <- num4 <- num3 <- num2 <- num1 <- 0 }
      else {
         num5 <- length(which(ratings >= 4.5))
         num4 <- length(which(ratings < 4.5 & ratings >= 3.5))
         num3 <- length(which(ratings < 3.5 & ratings >= 2.5))
         num2 <- length(which(ratings < 2.5 & ratings >= 1.5))
         num1 <- length(which(ratings < 1.5))
      }
      resultRatings <- c(num1, num2, num3, num4, num5)
      reviewsNodes <- html_nodes(ratingsSpans, xpath="div[1]/div[2]/p[1]/span" )
      responseNodes <- html_nodes(ratingsSpans, xpath="div[1]/div[3]/p[1]/span/span" ) ### Not using these yet
      reviews <- html_text(reviewsNodes)
      result <- list(ratings=resultRatings, reviews=reviews) 
   }
   if (is.null(result )) result <- list(ratings=c(0,0,0,0,0), reviews="") 
   return( result )
}
### url <- "https://www.ratemds.com/doctor-ratings/171094/Dr-Mitch-Freeman-YUMA-AZ.html?page=28"

### pageReviews <- getVitalsReviewPage(pageURL) 
### tmpReviews <- cReviews(tmpReviews, pageReviews )

### ratemds get ratings and reviews
getRMDSRatingsReviews <- function(num, url) {  
   num <- as.numeric(num)
   if (is.na(num) | is.null(num)) num <- 0
   tmpResult <- list(ratings=c(0,0,0,0,0), reviews="") 
   print(paste0("num: ", num, " type: ", typeof(num) ))
   if (num==0) {
      return( tmpResult )
   }
   if (num==1) {
      tmpResult <- getRMDSRatingReviewPage(url)
      if (is.null(tmpResult)) tmpResult <- list(ratings=c(0,0,0,0,0), reviews="") 
      return( tmpResult  )         
   }
   if (num > 1) {
      print(paste0("num: ", num, " type: ", typeof(num)))
      numPages <- ceiling(num / 10)
      for (i in 1:numPages) {
         pageURL <- paste0(url, "?page=", i)
         pageResult <- getRMDSRatingReviewPage(pageURL) 
         tmpResult <- cResults(tmpResult, pageResult)
      }
      return( tmpResult )
   }
}
### num <- 48   i <- 2  url <- aURL

getVitalsReviewPage <- function(url)  {
   html_doc <- read_html(url, verbose=FALSE)
   revNodeXP <- '//*[@id="reviewPage"]/div[4]/div[2]'
   revParent <- html_nodes(html_doc, xpath=revNodeXP )
   revDivNodes <- html_children(revParent)
   tmpReview <- getTextContent(revDivNodes, 'div[3]/div/div') 
   tmpReview <- gsub(pattern = "\n", replacement = "", tmpReview, fixed = TRUE )
   tmpReview <- str_trim(tmpReview)
   return(tmpReview)
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
   html_doc <- read_html(url, verbose=FALSE)
   tmpRating <- c("0","0","0","0","0")
   tmpRating[5] <- getTextContent(html_doc, xp5)   
   tmpRating[4] <- getTextContent(html_doc, xp4)
   tmpRating[3] <- getTextContent(html_doc, xp3)
   tmpRating[2] <- getTextContent(html_doc, xp2)
   tmpRating[1] <- getTextContent(html_doc, xp1)
   tmpRating <- as.numeric(gsub(pattern = "%", replacement = "", tmpRating, fixed = TRUE ))
   resultRatings <- round((numRatings * tmpRating / 100), digits = 0) 
   resultReviews <- vector("character")
   if (numReviews > 0) {
      numPages <- ceiling(numReviews / 10)
      for (i in 1:numPages) {
         pageURL <- paste0(url, "?page=", (i-1))
         pageReviews <- getVitalsReviewPage(pageURL) 
         resultReviews <- c(resultReviews, pageReviews )
      }
   }
   result <- list(ratings=resultRatings, reviews=resultReviews) 
   return( result )
}
### num <- 48   i <- 2  url <- aURL
### url <- "http://www.vitals.com/doctors/Dr_Franklin_Richards.html"
###    ratTxt <- c("0%","0%","0%","0%","0%")
