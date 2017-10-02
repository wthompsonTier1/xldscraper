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
	# add file to scrape_files table
  if(db_active){
   sql <- paste0(
    "insert into scrape_files (scrape_id, filename, title, description, type) values (", scrapeId,
    ", '", filename,
    "', '", title, 
    "', '", description, 
    "', '", type,
    "')"
    )
    debug("File SQL:  ")
    debug(sql)
  
    rs <- dbSendQuery(db, sql)
    dbClearResult(rs)
  }
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

if (! require(httr, quietly = TRUE)){ 
    install.packages("httr", repos='http://cran.us.r-project.org')
	library("httr")
}

if (! require(anytime, quietly = TRUE)){ 
    install.packages("anytime", repos='http://cran.us.r-project.org')
	library("anytime")
}

if (! require(RMySQL, quietly = TRUE)){ 
  install.packages("RMySQL", repos='http://cran.us.r-project.org')
  library("RMySQL")
}



### GOOGLE API KEY:
google_api_key <- "AIzaSyDWmQOAoJj3B6-IwCrgbNqEhCgVjzwilNU"


###  Default values for production site:  (dev_setting file will overwrite these values if exists)
phantomjs_version <- "phantomjs-2.1.1-linux-x86_64"
db_name <- "xld-connectedmd"
db_user <- "root"
db_pwd <- "Nn1yhwz4dnq3"
db_host <- "127.0.0.1"
db_active <- FALSE

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

clientName <- args[2]
if(is.null(clientName) | is.na(clientName) | clientName == ""){
  clientName <- "generic"
}

###  Read in xpath statements for the different data columns;  future database addition
dataids <- read.csv("data_xpath_elements.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)  ### data item identifiers, xpath, and html elements 


### Change the working directory to the searchDir, where the remaining csv files are located
setwd(paste0("../r_working_dir/", searchDir))


### Set load any development environment settings.  If it exists, it will be located outside
### of the directory that is part of source control.  Production environment settings will
### be included in this file, with dev settings overriding

###  NOTE:  This the url to the article discussing using PhantomJS. After running it through phantom js
###  we will make a html page in the working directory.  We will then parse that file looking for the 
###  stars, dates, and comments.  Remember, we might need to look for 70px, 56px, 42px, 28px, 14px widths
###  of the star divs to decipher the 5-4-3-2-1 rating values
###  https://www.datacamp.com/community/tutorials/scraping-javascript-generated-data-with-r#gs.ivT8lDU

### NOTE:  Need to fix the issue Stephanie Savely brought up in regards to vitals.com issues

# Load the dev settings file if needed
if(file.exists("../../../dev-environment.txt")){
	dev_settings <- readLines("../../../dev-environment.txt", warn=FALSE)
	
	for (i in 1:length(dev_settings)) {

		temp <- strsplit(dev_settings[i],"=")		

		assign(temp[[1]][1],temp[[1]][2])	
	}	
}

### Set up database connection
db <- dbConnect(MySQL(), user=db_user, password=db_pwd, dbname=db_name, host=db_host)
if(db_active){
  dbGetQuery(db, "truncate clients")
  dbGetQuery(db, "truncate scrapes")
  dbGetQuery(db, "truncate scrape_data")
  dbGetQuery(db, "truncate scrape_files")
  dbGetQuery(db, "truncate scrape_subjects")
  dbGetQuery(db, "truncate scrape_subject_site_identifiers")
  dbGetQuery(db, "truncate scrape_reviews")
}
### Read subject, site, xpath expression, and other needed data

###  Get the report column information from the database
report_colnames <- dbGetQuery(db, "select id from data_columns order by display_order")[,1]


### Code below was used to populate the data_columns table based on the col_names.txt file.
### It is commented out now that the data has been stored in the DB
#
#report_colnames <- readLines("col_names.txt", warn = FALSE, encoding = "UTF-8")  ### column names for results report
#
#tempDF <- data.frame(
#  "id" = report_colnames, 
#  "title" = report_colnames,
#  "type" = unlist(lapply(report_colnames,sitename_by_colname)),
#  "display_order" = c(1:length(report_colnames)),
#  stringsAsFactors = FALSE
#)


###  Send output to scrape_debug.txt also 
scrapeDebugFilename <- paste0(scrape_timestamp, "-scrape_debug.txt")
sink(scrapeDebugFilename, append=FALSE, split=TRUE)

### Scrape Info:
debug(paste0("Client Name: ", clientName))
debug(paste0("Scrape Dir: ", searchDir))
debug(paste0("Scrape TS: ", scrape_timestamp))
debug(paste0("Working Dir: ",getwd()))

###  path to phantom js:
phantomjs_path <- paste0("../../r_applications/",phantomjs_version)
debug(paste0("PhantomJS Path: ", phantomjs_path))

#########################################
### key scrape components to DB
#########################################

### Insert client if needed
if(db_active){
  clients <- dbGetQuery(db, paste0("select * from clients where name='",clientName,"'"))
  if(nrow(clients) == 0){
    rs <- dbSendQuery(db, paste0("insert into clients (name) values ('", clientName, "')"))
    dbClearResult(rs)
    clientId <- dbGetQuery(db,"select last_insert_id()")
  }else{
    clientId <- clients[1,"id"]
  }
  debug(paste0("Client DB Id:", clientId))
}
### Add row to scrapes
if(db_active){
  sql <- paste0("insert into scrapes (client_id, output_dir, scrape_ts_string) values (", clientId, ",'", searchDir, "','", scrape_timestamp,"')")
  debug("SQL:")
  debug(sql)
  rs <- dbSendQuery(db, sql)
  dbClearResult(rs)
  scrapeId <- as.integer(dbGetQuery(db, "select last_insert_id()"))
  
  debug(paste0("DB Scrape ID: ", scrapeId))
}

###  Add Scrape debug to file list
addToFileList(scrapeDebugFilename, "Scrape Debug Output", "Text file containing the entire debug output from the scrape routine.  Helps with tracking down errors.", "debug")


###  NOTE:  we are no longer reading in the sites.csv file.  We have this information in the 
###  search_sites table.  Also, the search functionality no longer creates the sites.csv file
#sites <- read.csv("Sites.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)  ### site names and urls
#addToFileList("Sites.csv", "Sites.csv", "CSV file containing the details about all the sites included in the scrape routine.", "source")
sites <- dbReadTable(db, "search_sites")





###Load in subjects.csv file; fix column names; lowercase subject_key values
subjects <- read.csv("Subjects.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)  ### subject names and ids
names(subjects)[1] <- "subject_key"
names(subjects)[2] <- "subject_name"
subjects["subject_key"] <- lapply(subjects["subject_key"],fix_subject_keys)
addToFileList("Subjects.csv", "Subjects.csv", "CSV file containing the subject data used in the scrape.", "source")

###  Add Subject to DB:
if(db_active){
  tempDF <- data.frame(
    "subject_key" = subjects[,"subject_key"], 
    "subject_name" = subjects[,"subject_name"],
    "scrape_id" = replicate(nrow(subjects), scrapeId),
     stringsAsFactors = FALSE
  )
  rs <- dbWriteTable(db, "scrape_subjects", tempDF, append=TRUE, row.names=FALSE)
}

###Load in subject_site_identifier.csv file; fix column names; lowercase subject_key and site key values
subj_site_id <- read.csv("Subject_Site_Identifiers.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE, colClasses="character")  ### subject ids and url differentiators
names(subj_site_id)[1] <- "subject_key"
names(subj_site_id)[2] <- "site_key"
names(subj_site_id)[3] <- "site_subject_ident"
subj_site_id["subject_key"] <- lapply(subj_site_id["subject_key"],fix_subject_keys)
subj_site_id["site_key"] <- lapply(subj_site_id["site_key"],function(x){tolower(x)})
addToFileList("Subject_Site_Identifiers.csv", "Subject_Site_Identifier.csv", "CSV file containing all profiles included in the scrape.", "source")

###  Write subj_site_id to database
if(db_active){
  tempDF <- data.frame(
    "subject_key" = subj_site_id[,"subject_key"], 
    "site_key" = subj_site_id[,"site_key"],
    "site_subject_ident" = subj_site_id[,"site_subject_ident"],
    "scrape_id" = replicate(nrow(subj_site_id), scrapeId),
    stringsAsFactors = FALSE
  )
  
  rs <- dbWriteTable(db, "scrape_subject_site_identifiers", tempDF, append=TRUE, row.names=FALSE)
}

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
		for (j in 1:nrow(profilesForSite)) {
			partialURL <- profilesForSite[j,"site_subject_ident"]
			
			###  profile_id:  this is used for profile related file creation
			profile_id <- paste0(aSubjKey,"-",aSiteKey,"-",j)
			
			## If facebook profile:  add to profile report and skip
			## until i can figure out how to get data
			#if(aSiteKey == "facebook"){
			#	profileReport <- rbind(profileReport, 
			#		data.frame(
			#			subject=c(aSubjKey),
			#			site= c(aSiteKey), 
			#			ident=c(partialURL), 
			#			status= c("Facebook profiles are skipped at this time")
			#		)
			#	)
			#	next
			#}
		
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
			partialURL <- trimws(partialURL)
			aURL <- paste0(sites[sites[["site_key"]]==aSiteKey,"site_home"], profilesForSite[j,"site_subject_ident"])
			debug(paste0("<-----  BEGIN PROFILE LOOP (subject: ",i," site: ", aSubjKey, " profile-num: ", j, " url: ", aURL, ")  ----->"))
			
			subjectSiteProfileData <- matrix(data="", nrow=1, ncol=nrow(dataItemList))
			colnames(subjectSiteProfileData) <- dataItemList[,"data_id"]
			

			if(aSiteKey != "google" & aSiteKey != "facebook"){
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
				
								
				###  Create the phantomjs file
				script_template <- paste(readLines('../../r_applications/phantom_js_template_ratemds.txt', warn=FALSE), collapse="\n")
				phantom_output_file <- paste0(scrape_timestamp,"_phantom_response_", profile_id, "_firstpage", ".html")
				script_template <- paste0("var output_file = '", phantom_output_file,"';\n", script_template)
				script_template <- paste0("var source_url = '",trimws(aURL),"';\n", script_template)
				
				# Create the phantom js file
				phantom_input_file <- paste0(scrape_timestamp, "_phantom_input_", profile_id, "_firstpage", ".js")
				write.table(script_template, 
				            file= phantom_input_file, 
				            quote = FALSE,
				            col.names = FALSE,
				            row.names = FALSE)							
				
				# Run phantom on the input.js file
				system(paste0(phantomjs_path, "/bin/phantomjs ", phantom_input_file))
				
				debug("DONE PHANTOM JS")
				
				firstPageDoc <- read_html(phantom_output_file, verbose=FALSE)

				subjectSiteProfileData[1,"r_rating"] 
				
				subjectSiteProfileData[1,"r_num_ratings"]
					

				###  NOTICE:  there are 2 types of pages (doctor and practice), thus we 
				###  need 2 different xpath expressions;
				
				### RATING VALUE
				tempVal <- getAttributeValue(firstPageDoc, xp='//*[@class="search-item-info"]//*[@class="star-rating"]', element_id="title")				
				if(tempVal == ""){
					tempVal <- getAttributeValue(firstPageDoc, xp='//*[@class="search-banner-panel"]//*[@class="star-rating "]', element_id="title")					
				}
				subjectSiteProfileData[1,"r_rating"] <- tempVal
				
				### NUM RATINGS
				tempVal <- getTextContent(firstPageDoc, xp='//*[@class="search-item-info"]//*[@class="star-rating-count"]/span[1]')			
				if(tempVal == ""){
					tempVal <- getTextContent(firstPageDoc, xp='//*[@class="search-banner-panel"]//*[@class="star-rating-count"]/span[1]/span[1]')					
				}
				subjectSiteProfileData[1,"r_num_ratings"] <- tempVal				
				
				subjectSiteProfileData[1,"r_num_reviews"] <- subjectSiteProfileData[1,"r_num_ratings"]
				
				
				if(subjectSiteProfileData[1,"r_num_ratings"] >0){
					tmpRatsRvws <- getRMDSRatingsReviews(subjectSiteProfileData[1,"r_num_ratings"], aURL)
					
					
					debug("After getting ratings and reviews------>")
					debug(tmpRatsRvws)					
					
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
							date= reviews[,"date"], 
							rating=reviews[,"rating"], 
							text=reviews[,"text"]
						)
					)
				}else{
					debug("Rate MDS Num ratings is 0")
				}			
			} 
			if (aSiteKey == "vitals") {
			  if(grepl("[^0-9.]",subjectSiteProfileData[1,"v_rating"])){
			    subjectSiteProfileData[1,"v_rating"] <- gsub("[^0-9.]","",subjectSiteProfileData[1,"v_rating"])			    
			  }
			  
			  if(grepl("[^0-9.]",subjectSiteProfileData[1,"v_num_ratings"])){
			    subjectSiteProfileData[1,"v_num_ratings"] <- gsub("[^0-9.]","",subjectSiteProfileData[1,"v_num_ratings"])			    
			  }
			  
			  if(grepl("[^0-9.]",subjectSiteProfileData[1,"v_num_reviews"])){
			    subjectSiteProfileData[1,"v_num_reviews"] <- gsub("[^0-9.]","",subjectSiteProfileData[1,"v_num_reviews"])			    
			  }		  
			  
				if (subjectSiteProfileData[1,"v_num_ratings"] > 0) {
					tmpRatsRvws <- getVitalsRatingsReviews(subjectSiteProfileData[1,"v_num_ratings"], aURL)
					reviews <- tmpRatsRvws
					
					subjectSiteProfileData[1,"v_pos_ratings"] <- nrow(reviews[as.numeric(reviews$rating) >= 3.5,])
					subjectSiteProfileData[1,"v_neut_ratings"] <- nrow(reviews[as.numeric(reviews$rating) >= 2.5 & as.numeric(reviews$rating) < 3.5,])
					subjectSiteProfileData[1,"v_neg_ratings"] <- nrow(reviews[as.numeric(reviews$rating) < 2.5,])					
					
					numReviewRows <- nrow(reviews[reviews$text != "",])
					if(numReviewRows > 0){
					  masterReviewData <- rbind(masterReviewData, 
              data.frame(
                subject=replicate(numReviewRows, aSubjKey), 
                site=replicate(numReviewRows, aSiteKey), 
                date=reviews[reviews$text != "","date"], 
                rating=reviews[reviews$text != "","rating"], 
                text=reviews[reviews$text != "","text"]
              )
					  )					  
					  subjectSiteProfileData[1,"v_pos_reviews"] <- nrow(reviews[reviews$text != "" & as.numeric(reviews$rating) >= 3.5,])
					  subjectSiteProfileData[1,"v_neut_reviews"] <- nrow(reviews[reviews$text != "" & as.numeric(reviews$rating) >= 2.5 & as.numeric(reviews$rating) < 3.5,])
					  subjectSiteProfileData[1,"v_neg_reviews"] <- nrow(reviews[reviews$text != "" & as.numeric(reviews$rating) < 2.5,])					
					}

				} else { ### else, number of reviews was zero
					subjectSiteProfileData[1,"v_pos_ratings"] <- subjectSiteProfileData[1,"v_neut_ratings"] <- subjectSiteProfileData[1,"v_neg_ratings"] <- 0
					subjectSiteProfileData[1,"v_pos_reviews"] <- subjectSiteProfileData[1,"v_neut_reviews"] <- subjectSiteProfileData[1,"v_neg_reviews"] <- 0
				}
			}
			if (aSiteKey == "healthgrades") {
				if(grepl("group-directory", partialURL)){
					scriptNodes <- html_nodes(html_doc, xpath="//*/script")
					dataNode <- ""
					for (i in 1:length(scriptNodes)){ 
						if(grepl("HGEppUi.Model",scriptNodes[i])){
							dataNode <- scriptNodes[i]
							break
						}
					}

					nodeText <- html_text(dataNode)
					match <- regexpr("return \\{",nodeText)
					nodeText <- substr(nodeText,match + attr(match, "match.length")-1,nchar(nodeText))
					
					
					#  NEXT: find the end of the javascript obj string and turn into json
					match <- regexpr(',\\"ScheduledProviders',nodeText)
					
					nodeText <- paste0(substr(nodeText,1,match-1),"}")
					
					
					jsonObj <- fromJSON(nodeText)
					
					
					
					#  Figure out how to get the star rating based on score information:  looks like the comment score / 2
					debug("JSON OBJ")
					debug(jsonObj$Surveys$comments)
					
					if(is.null(jsonObj)){
						profileReport <- rbind(profileReport, 
							data.frame(
								subject=c(aSubjKey),
								site= c(aSiteKey), 
								ident=c(partialURL), 
								status= c("Healthgrades data doesn't exist")
							)
						)						
						next
					}
					
					
					if(is.null(jsonObj$Surveys)){
						profileReport <- rbind(profileReport, 
							data.frame(
								subject=c(aSubjKey),
								site= c(aSiteKey), 
								ident=c(partialURL), 
								status= c("Healthgrades surveys don't exist")
							)
						)						
						next
					}
					
					if(is.null(jsonObj$Surveys$comments)){
						profileReport <- rbind(profileReport, 
							data.frame(
								subject=c(aSubjKey),
								site= c(aSiteKey), 
								ident=c(partialURL), 
								status= c("Healthgrades survey comments don't exist")
							)
						)						
						next
					}
					comments <- jsonObj$Surveys$comments
					
					
					debug("COMMENTS")
					debug(comments)
					
					ratings <- (comments$score)/2
					debug(ratings)
					debug(length(ratings))
					
					subjectSiteProfileData[1,"h_num_ratings"] <- length(ratings)
					subjectSiteProfileData[1,"h_num_reviews"] <- length(ratings)	
					subjectSiteProfileData[1,"h_pos_ratings"] <- subjectSiteProfileData[1,"h_pos_reviews"] <- length(subset(ratings,ratings>=4))
					subjectSiteProfileData[1,"h_neut_ratings"] <- subjectSiteProfileData[1,"h_neut_reviews"] <- length(subset(ratings,ratings==3))
					subjectSiteProfileData[1,"h_neg_ratings"] <- subjectSiteProfileData[1,"h_neg_reviews"] <- length(subset(ratings,ratings<3))					
				
					# calculate overall rating:
					
					overallSum = 0;
					for(a in 1:5){
						overallSum <- overallSum + (a * length(subset(ratings,ratings == a)))
					}
					
					debug("Overall Sum")
					debug(overallSum)
					
					overallRating <- round(overallSum/length(ratings), digits=1)
					subjectSiteProfileData[1,"h_rating"] <- overallRating

					
					debug("Profile Data:")
					debug(subjectSiteProfileData)
					
					numReviewRows <- length(ratings)
					if(numReviewRows > 0){
						dates <- comments$submittedDate
						dates <- as.character(format(as.Date(dates,"%m/%d/%Y"), "%m/%d/%y"))
						ratings <- as.character(comments$score/2)
						reviews <- paste0(comments$displayLastName, " - ", comments$commentText)						
						
						
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
					
					

				} else {
					
					debug("Not a Group Directory")
					
					jsonObj <- hg_getProfileJSON(html_doc)
					
					if(is.null(jsonObj) | is.na(jsonObj) | jsonObj == ""){					
						profileReport <- rbind(profileReport, 
							data.frame(
								subject=c(aSubjKey),
								site= c(aSiteKey), 
								ident=c(partialURL), 
								status= c("No Data From URL")
							)
						)						
						next					
					}
					subjectSiteProfileData[1,"h_own_prof"] <- hg_GetOwned(html_doc)
					subjectSiteProfileData[1,"h_rating"] <- jsonObj$model$overall$actualScore
					subjectSiteProfileData[1,"h_num_ratings"] <- jsonObj$model$overall$responseCount
					subjectSiteProfileData[1,"h_num_reviews"] <- jsonObj$model$overall$reviewCount
	
	
					if(jsonObj$model$overall$responseCount > 0){
						if(!is.null(nrow(jsonObj$model$surveyDistribution$aggregates))){
							ratingCounts <- jsonObj$model$surveyDistribution$aggregates[,"count"]
							subjectSiteProfileData[1,"h_pos_ratings"] <- ratingCounts[1] +  ratingCounts[2] 
							subjectSiteProfileData[1,"h_neut_ratings"] <- ratingCounts[3] 
							subjectSiteProfileData[1,"h_neg_ratings"] <- ratingCounts[4] +  ratingCounts[5]
						}else{
							# If no distribution is provided, it seems the h_rating value is used for the total
							# number of h_num_ratings
							subjectSiteProfileData[1,"h_pos_ratings"] <- if(subjectSiteProfileData[1,"h_rating"] >= 4) subjectSiteProfileData[1,"h_num_ratings"] else 0
							subjectSiteProfileData[1,"h_neut_ratings"] <- if(subjectSiteProfileData[1,"h_rating"] == 3) subjectSiteProfileData[1,"h_num_ratings"] else 0
							subjectSiteProfileData[1,"h_neg_ratings"] <- if(subjectSiteProfileData[1,"h_rating"] < 3) subjectSiteProfileData[1,"h_num_ratings"] else 0				
						}
					}
	
					reviewCount <- jsonObj$model$overall$reviewCount
					if(reviewCount > 0){
						if(reviewCount <= 50){
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
						}else{
							### More than 50 reviews requires another call to get the json
							opString = partialURL
							if(regexpr("\\?",partialURL)[[1]][1] > -1){
								opString <- substr(opString,1,regexpr("\\?",opString)[[1]][1]-1)
							}
	
							profileCodeParts <- strsplit(opString,"-")
							profileCode <- profileCodeParts[[1]][length(profileCodeParts[[1]])]
				
							
							commentURL <- "https://www.healthgrades.com/uisvc/v1_0/pesui/api/comments"
							body <- list(pwid = profileCode, currentPage = 1, perPage= reviewCount, sortOption = 1)
							response <- POST(commentURL, body=body, encode="form")
							json <- fromJSON(content(response, "text"))
							
							
							dates <- json$results[,"submittedDate"]
							dates <- as.character(as.Date(dates,"%B %d, %Y"))

							ratings <- as.character(json$results[,"overallScore"])
							reviews <- json$results[,"commentText"]	
												
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
				
				if(grepl("place_id", partialURL)){
					match <- regexpr("place_id",partialURL)
					place_id <- substr(partialURL, match + attr(match, "match.length") +1 ,nchar(partialURL))					
				}else{
					place_id <- partialURL
				}		
				## Get the JSON for the place_id
				jsonURL <- paste0("https://maps.googleapis.com/maps/api/place/details/json?placeid=", place_id, "&key=", google_api_key)
				
				googleJSON <- fromJSON(jsonURL)
					
				if(googleJSON$status == "OK"){     			
					mapUrl <- googleJSON$result$url
					debug("Map Url:")
					debug(mapUrl)
					
					mapDoc <- read_html(mapUrl, verbose=FALSE)
					mapDoc <- tryCatch(read_html(mapUrl, verbose=FALSE), error= function(e){return (FALSE)})
					if(!is.logical(mapDoc)){
						mapText <- html_text(mapDoc)
						
						start <- regexpr("lrd=",mapText)
						mapText <- substr(mapText,start + attr(start, "match.length"), start + 100)
						end <- regexpr("\\,",mapText)
						lrdVal <- gsub(":","%3A",substr(mapText,1, end -1))
						
						debug("LRD Value:")
						debug(lrdVal)
						if(!(is.null(lrdVal) | is.na(lrdVal) | lrdVal == "")){
							startItemNum <- 0
							googleData <- data.frame(date=c(), rating=c(), comment=c(), stringsAsFactors=FALSE)
							commentPage <- 0
							repeat{
								commentPage <- commentPage + 1
								commentUrl <- paste0("https://www.google.com/async/reviewSort?yv=2&async=feature_id:",lrdVal,",start_index:",startItemNum,",sort_by:newestFirst,more:true,_pms:s")
		
								debug("Comment URL")
								debug(commentUrl)	
		
								
								###  Create the phantomjs file
								script_template <- paste(readLines('../../r_applications/phantom_js_template.txt', warn=FALSE), collapse="\n")
								phantom_output_file <- paste0(scrape_timestamp,"_phantom_response_", profile_id, "_commentpage_", commentPage, ".json")
								script_template <- paste0("var output_file = '", phantom_output_file,"';\n", script_template)
								script_template <- paste0("var source_url = '",trimws(commentUrl),"';\n", script_template)
								
								# Create the phantom js file
								phantom_input_file <- paste0(scrape_timestamp, "_phantom_input_", profile_id,"_commentpage_",commentPage, ".js")
								write.table(script_template, 
								            file= phantom_input_file, 
								            quote = FALSE,
								            col.names = FALSE,
								            row.names = FALSE)							
								
								# Run phantom on the input.js file
								system(paste0(phantomjs_path, "/bin/phantomjs ", phantom_input_file))
								
								debug("DONE PHANTOM JS")
								
								commentJSON <- fromJSON(phantom_output_file)
								
								debug("JSON")
								debug(commentJSON)
								
								commentHtml <- commentJSON[[2]][[2]][1]
								
		
								commentDoc <- read_html(commentHtml,verbose=FALSE)
								commentItems <- html_nodes(commentDoc, xpath="//body/div/div[3]/div")
					
								
								debug("Number of comments on this page:")
								debug(length(commentItems))
								
								
								if(length(commentItems) == 0){
									debug("0 comments on this page")
									break
								}
								
		
								
								### Process the comments on this page:
								#gComments <- trimws(getTextContent(commentItems, xp='div[1]/div[3]/div/span'))
								gComments <- trimws(getTextContent(commentItems, xp='div[@class="_vor"]/div[3]/div[@class="_ucl"]/span'))
		
							
								#gDates <- trimws(getTextContent(commentItems, xp='div[1]/div[2]/span[1]'))
								gDates <- trimws(getTextContent(commentItems, xp='div[@class="_vor"]/div[3]/div[@class="_Rps"]/span[@class="_Q7k"]'))
								gDates <- unlist(lapply(gDates, google_formatDate))
							
					
								gRatings <- as.numeric(substr(trimws(getAttributeValue(commentItems, "//g-review-stars/span", "aria-label")),6,9))
								
								googleData <- rbind(googleData, 
									data.frame(
										date=gDates,
										rating= gRatings, 
										comment=gComments 
									)
								)		
								
		
								if(length(commentItems) < 10){
									break
								}else{
									startItemNum <- startItemNum + 10
								}
							}
							debug("Google Data")
							debug(googleData)
		
		
							filename <- paste0("googleData_",profile_id,".csv")
							write.csv(googleData, file = filename , row.names=FALSE)					
							
							
							##  NOTE:  this calculation does not reflect what the actual rating is.  We still need to figure 
							##  out how to grab the rating value from google.  Calculating it is not accurate						
							subjectSiteProfileData[1,"g_rating"] <- round(sum(as.numeric(googleData[,"rating"]))/nrow(googleData),1)
		
							if(nrow(googleData) > 0){							
								subjectSiteProfileData[1,"g_num_ratings"] <- nrow(googleData)
								subjectSiteProfileData[1,"g_pos_ratings"] <- nrow(googleData[googleData$rating >= 4,])
								subjectSiteProfileData[1,"g_neut_ratings"] <- nrow(googleData[googleData$rating == 3,])
								subjectSiteProfileData[1,"g_neg_ratings"] <- nrow(googleData[googleData$rating < 3,])
				
								subjectSiteProfileData[1,"g_num_reviews"] <- nrow(googleData[googleData$comment != "",])
								subjectSiteProfileData[1,"g_pos_reviews"] <- nrow(googleData[googleData$comment != "" & googleData$rating >= 4,])
								subjectSiteProfileData[1,"g_neut_reviews"] <- nrow(googleData[googleData$comment != "" & googleData$rating == 3,])
								subjectSiteProfileData[1,"g_neg_reviews"] <- nrow(googleData[googleData$comment != "" & googleData$rating < 3,])	
							
								masterReviewData <- rbind(masterReviewData, 
									data.frame(
										subject=replicate(nrow(googleData[googleData$comment != "",]), aSubjKey), 
										site=replicate(nrow(googleData[googleData$comment != "",]), aSiteKey), 
										date=googleData[googleData$comment != "","date"], 
										rating=as.character(googleData[googleData$comment != "","rating"]), 
										text=googleData[googleData$comment != "","comment"]
									)
								)											
							}							
						}else{
							profileReport <- rbind(profileReport, 
								data.frame(
									subject=c(aSubjKey),
									site= c(aSiteKey), 
									ident=c(partialURL), 
									status= c("Google Error:  No lrd value")
								)
							)					
						}
					}else{
						profileReport <- rbind(profileReport, 
							data.frame(
								subject=c(aSubjKey),
								site= c(aSiteKey), 
								ident=c(partialURL), 
								status= c("Google Error:  No Map URL")
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
				}
			}			
			
			if (aSiteKey == "facebook"){
				
				debug("FACEBOOK SPECIAL CASE DATA:")
				debug(partialURL)


				if(grepl("id=", partialURL)){
					match <- regexpr("id=",partialURL)
					pageid <- substr(partialURL, match + attr(match, "match.length") ,nchar(partialURL))					
				}else{
					pageid <- partialURL
				}

				debug("PAGEID")
				debug(pageid)
				ajaxURL <- paste0("https://www.facebook.com/ajax/pages/review/spotlight_reviews_tab_pager/?fetch_on_scroll=1&max_fetch_count=3000&page_id=",pageid,"&sort_order=most_recent&dpr=2&__user=0&__a=1&__dyn=5V5yAW8-aFoFxp2u6aOGeFxqeCwKAKGgS8zCC-C267UKewWhE98nyUdUaqwHUW4UJi28rxuF8WUOuVWxeUW6UO4GDgdUHDBxe6rCCyW-FFUkxvxOcxnxm1iyECQum2m4oqyU9omUmC-Wx2vgqx-u64i9CUW5oy5Fp89VQh1q4988VEf8Cu4rGUkACxe9yazEOcxO12y9EryoKfzUy&__af=iw&__req=a&__be=-1&__pc=PHASED%3ADEFAULT&__rev=3044736&__spin_r=3044736&__spin_b=trunk&__spin_t=1495740284")
				
				
				debug("Facebook ajax URL")
				debug(ajaxURL)
				response <- tryCatch(readLines(ajaxURL, warn=FALSE), error= function(e){return (FALSE)})
				if(is.logical(response)){
					profileReport <- rbind(profileReport, 
						data.frame(
							subject=c(aSubjKey),
							site= c(aSiteKey), 
							ident=c(partialURL), 
							status= c("Unable to open facebook page")
						)
					)
					next
				}			
				#response <- readLines(ajaxURL)
				
				response <- substr(response, attr(regexpr("[^\\{]*\\{",response), "match.length"), nchar(response))
				facebookJSON <- fromJSON(response)

				#debug("Facebook JSON")
				#debug(facebookJSON)
				
				html <- read_html(facebookJSON$domops[[1]][[4]]$`__html`,verbose=FALSE)
        #debug("FACEBOOK HTML:")
        #debug(facebookJSON$domops[[1]][[4]]$`__html`)
        #stop()
				
				if(!grepl("No reviews to show",html)){
						
					
					textComments <- html_text(html_nodes(html, xpath="//div/div/div[2]/div[1]/div[2]/div[2]"))
          #debug(textComments)
          #debug(length(textComments))
          

					ratings <- substr(html_text(html_nodes(html, xpath="//div/div/div[2]/div[1]/div[2]/div[1]/div/div/div[2]/div/div/div[2]/h5/span/span/i/u")),1,1)		
					#debug(ratings)
					#debug(length(ratings))
		
					#stop()
					#dates <-html_attr(html_nodes(html,xpath="//div/div/div[2]/div[1]/div[2]/div[1]/div/div/div[2]/div/div/div[2]/div/span[3]/span/a/abbr"),"title")
	
					dates <-as.character(as.Date(html_attr(html_nodes(html,xpath="//div/div/div[2]/div[1]/div[2]/div[1]/div/div/div[2]/div/div/div[2]/div/span[3]/span//abbr"),"title"), format="%A, %B %d, %Y "))	

					#debug("lengths:")
					#debug(length(dates))
					#debug(length(ratings))
					#debug(length(textComments))
					
					#stop()
					
					
					f_df <- data.frame(date=dates, rating=ratings, comment=textComments, stringsAsFactors=FALSE)
			
			
					debug("DATA FRAME")
					debug(f_df)
					
					#debug("Number of positive ratings")
					#debug(nrow(f_df[as.numeric(f_df$rating) >= 4,]));
					#debug(nrow(f_df[f_df$rating >= 4,]));
					
					
					
					
					debug(f_df)
	
					f_rating_sum <- 0		
					for(z in 1:5){
						f_rating_sum <- f_rating_sum + (z * nrow(f_df[f_df$rating == z,]))
					}		
	
					f_rating <- round(f_rating_sum / nrow(f_df),1)
					subjectSiteProfileData[1,"f_rating"] <- f_rating				
							
					
					subjectSiteProfileData[1,"f_num_ratings"] <- nrow(f_df)
					subjectSiteProfileData[1,"f_pos_ratings"] <- nrow(f_df[f_df$rating >= 4,])
					subjectSiteProfileData[1,"f_neut_ratings"] <- nrow(f_df[f_df$rating == 3,])
					subjectSiteProfileData[1,"f_neg_ratings"] <- nrow(f_df[f_df$rating < 3,])
	
					subjectSiteProfileData[1,"f_num_reviews"] <- nrow(f_df[f_df$comment != "",])
					subjectSiteProfileData[1,"f_pos_reviews"] <- nrow(f_df[f_df$comment != "" & f_df$rating >= 4,])
					subjectSiteProfileData[1,"f_neut_reviews"] <- nrow(f_df[f_df$comment != "" & f_df$rating == 3,])
					subjectSiteProfileData[1,"f_neg_reviews"] <- nrow(f_df[f_df$comment != "" & f_df$rating < 3,])	
				
					masterReviewData <- rbind(masterReviewData, 
						data.frame(
							subject=replicate(nrow(f_df[f_df$comment != "",]), aSubjKey), 
							site=replicate(nrow(f_df[f_df$comment != "",]), aSiteKey), 
							date=f_df[f_df$comment != "","date"], 
							rating=as.character(f_df[f_df$comment != "","rating"]), 
							text=f_df[f_df$comment != "","comment"]
						)
					)						
				}else{
					profileReport <- rbind(profileReport, 
						data.frame(
							subject=c(aSubjKey),
							site= c(aSiteKey), 
							ident=c(partialURL), 
							status= c("Found, but no rating/review data")
						)
					)
					next					
				}
						
					
				#	}
				#}else{
				#	profileReport <- rbind(profileReport, 
				#		data.frame(
				#			subject=c(aSubjKey),
				#			site= c(aSiteKey), 
				#			ident=c(partialURL), 
				#			status= c("Failed")
				#		)
				#	)
				#	next
				#}
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

debug("Number of rows in masterReviewData")
debug(nrow(masterReviewData))

if(nrow(masterReviewData) > 0){
	unique_subjects <- unique(masterReviewData$subject)
	for(i in 1:length(unique_subjects)){
		subject_key <- unique_subjects[i]
		filename <- paste0(scrape_timestamp, "-", subject_key, "-review_text.csv")
		addToFileList(filename, paste0("Review Text: ", subject_key), paste0("CSV file containing review text for: ", subject_key), "output")
		subjectReviews <- masterReviewData[masterReviewData[["subject"]]==subject_key,]	
		write.csv(subjectReviews, file = filename, row.names=FALSE)
	}
}

### Create the output file list file
outputFile <- paste0(scrape_timestamp, "-output_file_list.txt")
for (i in 1:length(scrape_file_list)) { 
	cat(paste(scrape_file_list[[i]], collapse="~"), file = outputFile, append=TRUE, sep="\n")
}



###  write masterReviewData to the scrape_reviews table




###  Write scrape reviews to DB:
if(db_active){
  tempDF <- data.frame(
    "scrape_id" = replicate(nrow(masterReviewData), scrapeId),
    "subject_key" = masterReviewData[,"subject"],
    "site_key" = masterReviewData[,"site"],
    "review_date" = masterReviewData[,"date"],
    "rating" = masterReviewData[,"rating"],
    "text" = masterReviewData[,"text"],
    stringsAsFactors = FALSE
  )
  debug(tempDF)
  rs <- dbWriteTable(db, "scrape_reviews", tempDF, append=TRUE, row.names=FALSE)
}




##  Write the name of the outputFileList file
cat(outputFile)



