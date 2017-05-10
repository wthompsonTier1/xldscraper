### scrape_connectmd.R    Version 1.0
### This R script should be called from the command line or from another program
### This script can be run using a command line execution call such as the following:
###     "C:\full\path\to\R\bin\Rscript.exe" scrape_connectmd.R  
### This script loads and uses the contents of several files as follows:
###    col_names.csv - defines the column header for the output file
###    data_xpath_elements.csv - defines xpath and element ids for each desired data item
###    Sites.csv - specifies the URLs and identifiers for web sites from which data is processed
###    Subjects.csv - specifying the names and identifiers for doctors for which data is processed 
###    Subject_Site_Identifiers.csv - defines xPath expressions for desired data items
###
### Collectively, these files specify the doctors' names, URLs, xPath expressions to scrape
###    desired info from the web pages. These files are distributed with this script.
### This script loads the files, reads the data items from the web pages, does appropriate
###    processing for desired outputs, and writes results to a CSV file titled resultsyyyymmdd.csv


### DEBUG FUNCTION
debug <- function(str){
	print(str)
}


#scrape_file_list:  used to hold names, titles, and descriptions of files used/created during this scrape
scrape_file_list <- list()

### addToFileList:  adds a list item to scrape_file_list containing 
### 	filename, title, description
addToFileList <- function(filename, title, description, type){
	curList <- scrape_file_list
	
	curList[[length(curList)+1]] <- c(filename, title, description, type)
	scrape_file_list <<- curList
}




{
	if (require(xml2, quietly = TRUE)) 
    	0 
	else 
    	install.packages(c("xml2"), repos='http://cran.us.r-project.org')
}
library("xml2")
{
	if (require(stringr, quietly = TRUE)) 
    	0 
	else 
    	install.packages("stringr", repos='http://cran.us.r-project.org')
}
library("stringr")
{
	if (require(rvest, quietly = TRUE)) 
    	0 
	else 
    	install.packages("rvest", repos='http://cran.us.r-project.org')
}
library("rvest")
{
	if (require(lsa, quietly = TRUE)) 
    	0	 
	else 
    	install.packages(c("lsa"), repos='http://cran.us.r-project.org')
}
library("lsa")

if (! require(jsonlite, quietly = TRUE)){ 
    install.packages("jsonlite", repos='http://cran.us.r-project.org')
	library("jsonlite")
}


if (! require(anytime, quietly = TRUE)){ 
    install.packages("anytime", repos='http://cran.us.r-project.org')
	library("anytime")
}

### GOOGLE API KEY:
google_api_key <- "AIzaSyDWmQOAoJj3B6-IwCrgbNqEhCgVjzwilNU"

### Set working directory and load needed functions

setwd(paste0(getwd(), "/r_applications"))
source("scrapeFunctions.r")


#scrape_timestamp: used in naming any files created by scrape so we can easily group by date/time
scrape_timestamp <- format(Sys.time(), format="%Y%m%d-%H%M%S")




###
### 	Get the search directory param
###
args <- commandArgs(TRUE)
searchDir <- args[1]


### Read subject, site, xpath expression, and other needed data
report_colnames <- readLines("col_names.txt", warn = FALSE, encoding = "UTF-8")  ### column names for results report
dataids <- read.csv("data_xpath_elements.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)  ### data item identifiers, xpath, and html elements 


### Change the working directory to the searchDir, where the remaining csv files are located
setwd(paste0("../r_working_dir/", searchDir))


###  Send output to scrape_debug.txt also 
filename <- paste0(scrape_timestamp, "-scrape_debug.txt")
addToFileList(filename, "Scrape Debug Output", "Text file containing the entire debug output from the scrape routine.  Helps with tracking down errors.", "debug")
sink(filename, append=FALSE, split=TRUE)
debug(paste0("WORKING DIR:  ",getwd()))
debug(paste0("SEARCH DIR:  ", searchDir))





sites <- read.csv("Sites.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)  ### site names and urls
addToFileList("Sites.csv", "Sites.csv", "CSV file containing the details about all the sites included in the scrape routine.", "source")

###Load in subjects.csv file; fix column names; lowercase subject_key values
subjects <- read.csv("Subjects.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)  ### subject names and ids
names(subjects)[1] <- "subject_key"
names(subjects)[2] <- "subject_name"
subjects["subject_key"] <- lapply(subjects["subject_key"],function(x){tolower(x)})
addToFileList("Subjects.csv", "Subjects.csv", "CSV file containing the subject data used in the scrape.", "source")


###Load in subject_site_identifier.csv file; fix column names; lowercase subject_key and site key values
subj_site_id <- read.csv("Subject_Site_Identifiers.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)  ### subject ids and url differentiators
names(subj_site_id)[1] <- "subject_key"
names(subj_site_id)[2] <- "site_key"
names(subj_site_id)[3] <- "site_subject_ident"
subj_site_id["subject_key"] <- lapply(subj_site_id["subject_key"],function(x){tolower(x)})
subj_site_id["site_key"] <- lapply(subj_site_id["site_key"],function(x){tolower(x)})
addToFileList("Subject_Site_Identifiers.csv", "Subject_Site_Identifier.csv", "CSV file containing all profiles included in the scrape.", "source")






debug("<--------  BEGIN:  CSV DATA -------------->")
debug("SITES: ")
debug(sites)


debug(paste0("SUBJECTS:  ",nrow(subjects)))
debug(subjects)


debug(paste0("PROFILES:  ",nrow(subj_site_id)))
debug(subj_site_id)


debug("REPORT COLUMN NAMES: ")
debug(report_colnames)

debug("DATAIDS:  ")
debug(dataids)


debug("<--------  END:  CSV DATA -------------->")

### Create an empty matrix
### Doc's name, data label, data value, site
### results <- matrix(data=NA_character_, nrow=0, ncol=88) 
results <- matrix(data="", nrow=0, ncol = length(report_colnames))
colnames(results) <- report_colnames

### create data frame to collect reviews information
masterReviewData <- matrix(data="", nrow=0, ncol = 5)
colnames(masterReviewData) <- c("subject", "site", "date", "rating", "text")

### create profile-report data frame to collect issues with individual profiles 
### supplied in the site_subject_identifiers csv file
profileReport <- matrix(data="", nrow=0, ncol = 4)
colnames(profileReport) <- c("subject", "site", "ident", "status")



### Loop through all data and grab the data elements from the sites with the corresponding xpath expression
for (i in 1:length(subjects[["subject_key"]])) {  ### loop over docs  i <- 14  j <- 1 k <- 7
	aSubjKey <- subjects[i,"subject_key"]
	siteList <- subj_site_id[subj_site_id[["subject_key"]]==aSubjKey,]
	aDocName <- subjects[i,"subject_name"]
	
	debug(paste0("<---------  BEGIN SUBJECT LOOP (",i,": ", aSubjKey, ")  --------->"))
	
	debug("Site List for Subject:  ")
	debug(siteList)
	

	  
	### Setup up one line data structure for a user.  This temp structure will
	### get merged into the "results" data structure at the end of this loop   
	temp <- matrix(data="", nrow=1, ncol= length(report_colnames))   ### is.na(temp[1,1]) 
	colnames(temp) <- report_colnames
	
	
	temp[1,"name"] <- aDocName 

	uniqueSites <- unique(siteList$site_key)  
	debug("Unique Sites:")
	debug(uniqueSites)
	for(us in 1:length(uniqueSites)){
		aSiteKey <- uniqueSites[us]
		debug("SITEKEY:  ")
		debug(aSiteKey)
	
		dataItemList <- dataids[dataids[["site_key"]]==aSiteKey,] 
		
		
		### Create a data structure to store profile(s) information for a subject from a specific site.
		### At the end of this loop this data structure will be merged into the temp[] data matrix
		subjectSiteData <- matrix(data="", nrow=0, ncol=nrow(dataItemList))
		colnames(subjectSiteData) <- dataItemList[,"data_id"]
		
		profilesForSite <- siteList[siteList$site_key == aSiteKey,]
		
		siteFirstChar <- substr(aSiteKey,1,1)
		debug(paste0("First Char of aSiteKey:  ", siteFirstChar))
		
		### Set the "_num_prof" field 
		#temp[1,paste0(siteFirstChar, "_num_prof")] <- nrow(profilesForSite) 

		debug(paste0("<-------  BEGIN PROCESSING PROFILES FOR SUBJECT/SITE (", aSubjKey, ", ", aSiteKey, ") ---------->"))
		for (j in 1:nrow(profilesForSite)) {   ### Loop over sites j <- 1
			partialURL <- profilesForSite[j,"site_subject_ident"]
			
			## If facebook profile:  add to profile report and skip
			## until i can figure out how to get data
			if(aSiteKey == "facebook"){
				profileReport <- rbind(profileReport, 
					data.frame(
						subject=c(aSubjKey),
						site= c(aSiteKey), 
						ident=c(partialURL), 
						status= c("Facebook profiles are skipped at this time")
					)
				)
				next
			}
		
			if(is.null(partialURL) | is.na(partialURL) | partialURL == ""){
				profileReport <- rbind(profileReport, 
					data.frame(
						subject=c(aSubjKey),
						site= c(aSiteKey), 
						ident=c(""), 
						status= c("No Profile Supplied")
					)
				)					
				next
			}
			aURL <- paste0(sites[sites[["site_key"]]==aSiteKey,"site_home"], profilesForSite[j,"site_subject_ident"])
			debug(paste0("<-----  BEGIN PROFILE LOOP (subject: ",i," site: ", aSubjKey, " profile-num: ", j, " url: ", aURL, ")  ----->"))
			
			subjectSiteProfileData <- matrix(data="", nrow=1, ncol=nrow(dataItemList))
			colnames(subjectSiteProfileData) <- dataItemList[,"data_id"]
			

			if(aSiteKey != "google"){
				html_doc <- tryCatch(read_html(aURL, verbose=FALSE), error= function(e){return (FALSE)})
				
				if(is.logical(html_doc)){
					profileReport <- rbind(profileReport, 
						data.frame(
							subject=c(aSubjKey),
							site= c(aSiteKey), 
							ident=c(partialURL), 
							status= c("Profile Does Not Exist")
						)
					)					
					next
				}
			
			
			
				##debug("BEGIN DataItemList LOOP")  
				for (k in 1:length(dataItemList[["data_id"]])) { 
					dataItemName <- dataItemList[k,"data_id"]
					dataItemElement <- dataItemList[k,"element"]
					dataItemXPath <- dataItemList[k,"xpath"]
					dataItemElementId <- dataItemList[k,"element_id"]
					if (dataItemElement == "exist") {
						debug("Existance:")
						subjectSiteProfileData[1,dataItemName] <- getExistance(html_doc, xp=dataItemXPath)
						debug(paste0("EXIST:  ", dataItemName, ":"))
						debug(subjectSiteProfileData[1,dataItemName])
	
					}
					if (dataItemElement == "text") {
						debug("Text:")
						subjectSiteProfileData[1,dataItemName] <- getTextContent(html_doc, xp=dataItemXPath)
						debug(paste0("TEXT:  ", dataItemName, ":"))
						debug(subjectSiteProfileData[1,dataItemName])					
					}
					if (dataItemElement == "attribute") {
						debug("Attribute:")
						val <- getAttributeValue(html_doc, xp=dataItemXPath, element_id=dataItemElementId)
						if(is.na(val)){
							val <- 0
						}
						subjectSiteProfileData[1,dataItemName] <- val
						debug(paste0("xxxAttribute:  ", dataItemName, ":"))
						debug(subjectSiteProfileData[1,dataItemName])
					}
				}
				##debug("END DataItemList LOOP")
			}
	
			### Handle special case data elements without the loop
			##debug("BEGIN SPECIAL CASE ITEMS")
			if (aSiteKey == "ratemds") {
				subjectSiteProfileData[1,"r_num_reviews"] <- subjectSiteProfileData[1,"r_num_ratings"]
				if(subjectSiteProfileData[1,"r_num_ratings"] >0){
					tmpRatsRvws <- getRMDSRatingsReviews(subjectSiteProfileData[1,"r_num_ratings"], aURL)
					
			
					if (is.null(tmpRatsRvws)) tmpRatsRvws <- list(ratings=c(0,0,0,0,0), reviews="") 
					subjectSiteProfileData[1,"r_pos_reviews"] <- subjectSiteProfileData[1,"r_pos_ratings"] <- tmpRatsRvws$ratings[4] +  tmpRatsRvws$ratings[5] 
					subjectSiteProfileData[1,"r_neut_reviews"] <- subjectSiteProfileData[1,"r_neut_ratings"] <- tmpRatsRvws$ratings[3] 
					subjectSiteProfileData[1,"r_neg_reviews"] <- subjectSiteProfileData[1,"r_neg_ratings"] <- tmpRatsRvws$ratings[1] +  tmpRatsRvws$ratings[2] 
					subjectSiteProfileData[1,"r_neg_addressed"] <- ""
					
					##Add reviews to masterReviewData
					reviews <- tmpRatsRvws$reviews
					numReviewRows <- nrow(reviews)
					masterReviewData <- rbind(masterReviewData, 
						data.frame(
							subject=replicate(numReviewRows, aSubjKey), 
							site=replicate(numReviewRows, aSiteKey), 
							date=reviews[,"date"], 
							rating=reviews[,"rating"], 
							text=reviews[,"text"]
						)
					)
				}				
			} 
			if (aSiteKey == "vitals") {
				if (subjectSiteProfileData[1,"v_num_ratings"] > 0) {
					tmpRatsRvws <- getVitalsRatingsReviews(subjectSiteProfileData[1,"v_num_ratings"], subjectSiteProfileData[1,"v_num_reviews"], aURL)
					subjectSiteProfileData[1,"v_pos_ratings"] <- tmpRatsRvws$ratings[4] +  tmpRatsRvws$ratings[5] 
					subjectSiteProfileData[1,"v_neut_ratings"] <- tmpRatsRvws$ratings[3] 
					subjectSiteProfileData[1,"v_neg_ratings"] <- tmpRatsRvws$ratings[1] +  tmpRatsRvws$ratings[2]
					
					reviews <- tmpRatsRvws$reviews
					numReviewRows <- nrow(reviews)
					if(numReviewRows > 0){
						masterReviewData <- rbind(masterReviewData, 
							data.frame(
								subject=replicate(numReviewRows, aSubjKey), 
								site=replicate(numReviewRows, aSiteKey), 
								date=reviews[,"date"], 
								rating=reviews[,"rating"], 
								text=reviews[,"text"]
							)
						)					
						subjectSiteProfileData[1,"v_pos_reviews"] <- nrow(reviews[as.numeric(reviews$rating) >= 4,])
						subjectSiteProfileData[1,"v_neut_reviews"] <- nrow(reviews[as.numeric(reviews$rating) == 3,])
						subjectSiteProfileData[1,"v_neg_reviews"] <- nrow(reviews[as.numeric(reviews$rating) < 3,])
					}
				} else { ### else, number of reviews was zero
					subjectSiteProfileData[1,"v_pos_ratings"] <- subjectSiteProfileData[1,"v_neut_ratings"] <- subjectSiteProfileData[1,"v_neg_ratings"] <- 0
					subjectSiteProfileData[1,"v_pos_reviews"] <- subjectSiteProfileData[1,"v_neut_reviews"] <- subjectSiteProfileData[1,"v_neg_reviews"] <- 0
				}
			}
			if (aSiteKey == "healthgrades") {
				jsonObj <- hg_getProfileJSON(html_doc)
				#debug("HG JSON OBJECT:")
				#debug(jsonObj)
				
				subjectSiteProfileData[1,"h_own_prof"] <- hg_GetOwned(html_doc)
				subjectSiteProfileData[1,"h_rating"] <- jsonObj$model$overall$actualScore
				subjectSiteProfileData[1,"h_num_ratings"] <- jsonObj$model$overall$responseCount
				subjectSiteProfileData[1,"h_num_reviews"] <- jsonObj$model$overall$reviewCount


				if(jsonObj$model$overall$responseCount > 0){
					debug(jsonObj$model$surveyDistribution$aggregates)
					ratingCounts <- jsonObj$model$surveyDistribution$aggregates[,"count"]
					subjectSiteProfileData[1,"h_pos_ratings"] <- ratingCounts[1] +  ratingCounts[2] 
					subjectSiteProfileData[1,"h_neut_ratings"] <- ratingCounts[3] 
					subjectSiteProfileData[1,"h_neg_ratings"] <- ratingCounts[4] +  ratingCounts[5] 				
				}

				
				if(jsonObj$model$overall$reviewCount > 0){
					
					
					dates <- jsonObj$model$comments$results[,"submittedDate"]
					dates <- as.character(as.Date(dates,"%B %d, %Y"))
					ratings <- as.character(jsonObj$model$comments$results[,"overallScore"])
					reviews <- jsonObj$model$comments$results[,"commentText"]	
										
					subjectSiteProfileData[1,"h_pos_reviews"] <- length(subset(ratings,ratings>=4))
					subjectSiteProfileData[1,"h_neut_reviews"] <- length(subset(ratings,ratings==3))
					subjectSiteProfileData[1,"h_neg_reviews"] <- length(subset(ratings,ratings<3))
					subjectSiteProfileData[1,"h_neg_addressed"] <- ""						
					
					numReviewRows <- length(reviews)
					if(numReviewRows > 0){
						masterReviewData <- rbind(masterReviewData, 
							data.frame(
								subject=replicate(numReviewRows, aSubjKey), 
								site=replicate(numReviewRows, aSiteKey), 
								date= dates, 
								rating= ratings, 
								text= reviews
							)
						)
					}
				}
			}
	      
			if (aSiteKey == "yelp") {
				### Fix y_rating if it has a value; example value:  "5.0 star rating"
				if(subjectSiteProfileData[1,"y_rating"] != ""){
					newVal <- strsplit(subjectSiteProfileData[1,"y_rating"],split=" ")[[1]][1]
					subjectSiteProfileData[1,"y_rating"] <- newVal
				} else {
					subjectSiteProfileData[1,"y_rating"] <- 0
				}
				
				### Fix y_num_rating is it has a value;  example value "\n            12 reviews\n"
				if(subjectSiteProfileData[1,"y_num_ratings"] != ""){
					newVal <- strsplit(trimws(gsub("\n", "", subjectSiteProfileData[1,"y_num_ratings"])),split=" ")[[1]][1]
					#debug(paste0("OldVal:  ",subjectSiteProfileData[1,"y_num_ratings"], " NewVal:  ", newVal))
					subjectSiteProfileData[1,"y_num_ratings"] <- newVal
				}else{
					subjectSiteProfileData[1,"y_num_ratings"] <- 0
				}
				
				### Positive, Neutral, and negative ratings:
				## num of 5 ratings
				val <- getTextContent(html_doc, xp='//*[@class="histogram_count"][1]')
				rating_5 <- 0
				if(val != ""){
					rating_5 <- as.numeric(val)
				}
				## num of 4 ratings
				val <- getTextContent(html_doc, xp='//*[@class="histogram_count"][2]')
				rating_4 <- 0
				if(val != ""){
					rating_4 <- as.numeric(val)
				}
				## num of 3 ratings
				val <- getTextContent(html_doc, xp='//*[@class="histogram_count"][3]')
				rating_3 <- 0
				if(val != ""){
					rating_3 <- as.numeric(val)
				}
				## num of 2 ratings
				val <- getTextContent(html_doc, xp='//*[@class="histogram_count"][4]')
				rating_2 <- 0
				if(val != ""){
					rating_2 <- as.numeric(val)
				}
				## num of 1 ratings
				val <- getTextContent(html_doc, xp='//*[@class="histogram_count"][5]')
				rating_1 <- 0
				if(val != ""){
					rating_1 <- as.numeric(val)
				}	  	

				subjectSiteProfileData[1,"y_pos_ratings"] <- sum(rating_5, rating_4)
				subjectSiteProfileData[1,"y_neut_ratings"] <- rating_3
				subjectSiteProfileData[1,"y_neg_ratings"] <- sum(rating_2, rating_1)
				
				if(as.numeric(subjectSiteProfileData[1,"y_num_ratings"]) > 0){
					reviews <- yelp_GetReviews(subjectSiteProfileData[1,"y_num_ratings"],aURL)
					numReviewRows <- nrow(reviews)
					subjectSiteProfileData[1,"y_num_reviews"] <- numReviewRows
					subjectSiteProfileData[1,"y_pos_reviews"] <- nrow(reviews[as.numeric(reviews$rating) >= 4,])
					subjectSiteProfileData[1,"y_neut_reviews"] <- nrow(reviews[as.numeric(reviews$rating) == 3,])
					subjectSiteProfileData[1,"y_neg_reviews"] <- nrow(reviews[as.numeric(reviews$rating) < 3,])
					
					numReviewRows <- nrow(reviews)

					
					masterReviewData <- rbind(masterReviewData, 
						data.frame(
							subject=replicate(numReviewRows, aSubjKey), 
							site=replicate(numReviewRows, aSiteKey), 
							date=reviews[,"date"], 
							rating=reviews[,"rating"], 
							text=reviews[,"text"]
						)
					)					
				}


			}
			
			
			if (aSiteKey == "google"){
				#searchReturnObj <- fromJSON(paste0(site_url, returnObj$additional_search_params)
				
				debug("GOOGLE SPECIAL CASE DATA:")
				debug(partialURL)
				
				#regexMatch <- gregexpr("place_id",aURL)
				#place_id <- substr(aURL, regexMatch[[1]][1] + 9,nchar(aURL))
				place_id <- partialURL

				## Get the JSON for the place_id
				jsonURL <- paste0("https://maps.googleapis.com/maps/api/place/details/json?placeid=", place_id, "&key=", google_api_key)
				
				debug("JSON URL:")
				debug(jsonURL)
				
				googleJSON <- fromJSON(jsonURL)
				
				debug("GOOGLE JSON:")
				debug(googleJSON)
				
				if(googleJSON$status == "OK"){
					g_rating <- googleJSON$result$rating
					if(!is.null(g_rating)){
						subjectSiteProfileData[1,"g_rating"] <- g_rating					
					}
					reviews <- googleJSON$result$reviews
					if(!is.null(reviews)){
						debug("REVIEWS")
						debug(reviews)	
						
						subjectSiteProfileData[1,"g_num_ratings"] <- subjectSiteProfileData[1,"g_num_reviews"] <- nrow(reviews)
						subjectSiteProfileData[1,"g_pos_ratings"] <- subjectSiteProfileData[1,"g_pos_reviews"] <- nrow(reviews[as.numeric(reviews$rating) >= 4,])
						subjectSiteProfileData[1,"g_neut_ratings"] <- subjectSiteProfileData[1,"g_neut_reviews"] <- nrow(reviews[as.numeric(reviews$rating) == 3,])
						subjectSiteProfileData[1,"g_neg_ratings"] <- subjectSiteProfileData[1,"g_neg_reviews"] <- nrow(reviews[as.numeric(reviews$rating) < 3,])
												
						
						
						
										

						masterReviewData <- rbind(masterReviewData, 
							data.frame(
								subject=replicate(nrow(reviews), aSubjKey), 
								site=replicate(nrow(reviews), aSiteKey), 
								date=sapply(reviews[,"time"], function(x) as.character(anydate(x))), 
								rating=reviews[,"rating"], 
								text=reviews[,"text"]
							)
						)						
						
					
					}
				}else{
					profileReport <- rbind(profileReport, 
						data.frame(
							subject=c(aSubjKey),
							site= c(aSiteKey), 
							ident=c(partialURL), 
							status= c("Failed")
						)
					)
					next
				}
			}			
			
			
			
			##debug("END SPECIAL CASE ITEMS")
	
			###  Set "_num_prof" = 1
			subjectSiteProfileData[1, paste0(siteFirstChar,"_num_prof")] = "1"	      			
			##debug("SubjectSiteProfileData: ")
			##debug(subjectSiteProfileData)
			subjectSiteData <- rbind(subjectSiteData,subjectSiteProfileData)   
			 
			debug(paste0("<-----  END PROFILE LOOP (subject: ",i," site: ", aSubjKey, " profile-num: ", j, " url: ", aURL, ")  ----->"))
			
			
			profileReport <- rbind(profileReport, 
				data.frame(
					subject=c(aSubjKey),
					site= c(aSiteKey), 
					ident=c(partialURL), 
					status= c("OK")
				)
			)
			
		}
		debug(paste0("<-------  END PROCESSING PROFILES FOR SUBJECT/SITE (", aSubjKey, ", ", aSiteKey, ") ---------->"))
	   
	   debug(paste0("Data for Subject (",aSubjKey,") for Site (",aSiteKey,"):"))
	   debug(subjectSiteData)
	   debug("NUMBER ROWS OF SUBJECT SITE DATA:")
	   debug(nrow(subjectSiteData))
	   ###
	   #	Need to combine the column values in subjectSiteData.  NOTE, need to come up with a strategy that allows us to 
	   #	combine the necessary columns, excluding some columns, and allowing for special case calculations (rating with 
	   #	multiple profiles)
	   ###
	   if(nrow(subjectSiteData) == 0){
		   next
	   }
	   
	   
	   if(nrow(subjectSiteData)> 1){
		   
		   colsToCalculate <- c(
			   "_num_prof",
			   "_own_prof",
			   "_num_ratings",
			   "_pos_ratings",
			   "_neut_ratings",
			   "_neg_ratings",
			   "_num_reviews",
			   "_pos_reviews",
			   "_neut_reviews",
			   "_neg_reviews",
			   "_neg_addressed",
			   "_rating"		   
		   )
		   
		   colsInData <- colnames(subjectSiteData)
		   
		   for( col in colsInData){
			   strippedCol <- substr(col,2,nchar(col))
			   if(length(grep(paste0("^",strippedCol,"$"),colsToCalculate)) > 0){
					if(strippedCol == "_rating"){
						### Calculate weighted average:
						temp[1,col] <- round(weighted.mean(as.numeric(subjectSiteData[,paste0(siteFirstChar,"_rating")]), as.numeric(subjectSiteData[,paste0(siteFirstChar, "_num_ratings")]), na.rm=TRUE),1)
						
					}else{
						temp[1,col] <- sum(as.numeric(subjectSiteData[,col]),na.rm=TRUE)
					}
				}
			}		   
	   } else { 
		   ###  Just add the columns values to the correct columns in temp
		   temp[1,colnames(subjectSiteData)] <- subjectSiteData[1,]		   
	   }
	   debug(paste0("<-------  END PROCESSING PROFILES FOR SUBJECT/SITE (", aSubjKey, ", ", aSiteKey, ") ---------->"))
	}
	debug(paste0("Add row to results for User (", aSubjKey, "):"))
	debug(temp)
	
	### fix empty columns 
	nonNumericColumns <- c(
		"name",
		"pg_appear",
		"g_addr_ph_ex",
		"g_addr_ph_correct",
		"g_missing_info",
		"r_addr_ph_ex",
		"r_addr_ph_correct",
		"r_missing_info",
		"y_addr_ph_ex",
		"y_addr_ph_correct",
		"y_missing_info",
		"h_addr_ph_ex",
		"h_addr_ph_correct",
		"h_missing_info",
		"v_addr_ph_ex",
		"v_addr_ph_correct",
		"v_missing_info",
		"f_addr_ph_ex",
		"f_addr_ph_correct",
		"f_missing_info"
	)										
	
	
	temp[,!colnames(temp) %in% nonNumericColumns] <- replace(temp[,!colnames(temp) %in% nonNumericColumns],temp[,!colnames(temp) %in% nonNumericColumns]=="","0")
	
	results <- rbind(results, temp)
	debug(paste0("<---------  END SUBJECT LOOP (",i,": ", aSubjKey, ")  --------->"))
}

##  Write profile_status_report.csv
filename <- paste0(scrape_timestamp, "-profile_status_report.csv")
addToFileList(filename, "Profile Status Report", "CSV file containing a basic status report for each profile scraped.", "debug")
write.csv(profileReport, file = filename , row.names=FALSE)

## Write scrape_results.csv file
filename <- paste0(scrape_timestamp, "-scrape_results.csv")
addToFileList(filename, "Scrape Results", "CSV file containing scrape results data", "output")
write.table(results, file=filename, quote = TRUE, sep = ",", row.names = FALSE, col.names = TRUE)

## Write scrape_results-review-text.csv
reviewfilename <- paste0(scrape_timestamp, "-scrape_results_review_text.csv")
addToFileList(reviewfilename, "Review Text:  All Subjects", "CSV file containing review text and ratings for ALL Subjects", "output")
write.csv(masterReviewData, file = reviewfilename, row.names=FALSE)

unique_subjects <- unique(masterReviewData$subject)
for(i in 1:length(unique_subjects)){
	subject_key <- unique_subjects[i]
	filename <- paste0(scrape_timestamp, "-", subject_key, "-review_text.csv")
	addToFileList(filename, paste0("Review Text: ", subject_key), paste0("CSV file containing review text for: ", subject_key), "output")
	
	subjectReviews <- masterReviewData[masterReviewData[["subject"]]==subject_key,]	
	write.csv(subjectReviews, file = filename, row.names=FALSE)
}







### Create the output file list file
outputFile <- paste0(scrape_timestamp, "-output_file_list.txt")
for (i in 1:length(scrape_file_list)) { 
	cat(paste(scrape_file_list[[i]], collapse="~"), file = outputFile, append=TRUE, sep="\n")
}


##  Write the name of the outputFileList file
cat(outputFile)



#debug("Test:")
#debug(masterReviewData)
#debug(unique(masterReviewData$subject))
#debug(length(unique(masterReviewData$subject)))


### create data frame to collect reviews information for the subject
#subjectReviewData <- matrix(data="", nrow=0, ncol = 5)
#colnames(subjectReviewData) <- c("subject", "site", "date", "rating", "text")




### General flow
### Loop over docs
###    Loop over sites
###       Loop over data items
###          - direct gets first
###            if (element=="") skip as source is not yet defined 
###            if (element=="exist") test for xpath node existence, assign to 
###            if (element=="text") get text, assign to data_id
###            if (element=="attribute") get node, get attribute value for given element_id
###            
###          - multipage gets second
###            if (element=="children") get child xpath, count children elements,
### 
### Testing code here for debugging the loop above
### //*[@id="sdaon"]/div[1]/div/div/div/div[1]/div/div/div/div[3]/span[3]
### //*[@id="sdaon"]/div[1]/div/div/div/div[1]/div/div/div/div[3]/span[3]
### 
### nodes <- html_nodes(html_doc, xpath="//*[@id='sdaon']/div[1]/div/div/div/div[1]/div/div/div/div[3]/span[3]")
### nodes <- html_nodes(html_doc, xpath="//span")
### textContents[textContents[=="15"]]
### 
### html_structure(html_doc)
### textContents <- html_text(nodes )
### html_name(nodes )
### html_attrs(nodes )
### html_attr(nodes , "id")
### 
### LSA
### Obtain the textmatrix and calculate the term-vector matrix. 
### Columns represent the documents. The measure of the cosine of 
###     the angle between 2 column-vectors is a measure of the similarity of the 2 documents.
###     A high cosine value indicates high similarity.

