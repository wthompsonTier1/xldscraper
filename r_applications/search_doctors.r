
####################################################
###		BEGIN:   FUNCTIONS
####################################################
	
####################################################
###
###		debug(str)
### 
###		used to print items during testing; can be 
###		turned off with "testing" var
###
####################################################
	debug <- function(str){
		if(testing == TRUE){
			print(str)
		}
	}
	
	
####################################################
###
###		search_site(searchItem, siteinfo)
### 
###		 
###		
###
####################################################

	getStateFull <- function(twoLetterCode){
		stateInfo<-data.frame(
			state=c("AK", "AL", "AR", "AZ", "CA", "CO", "CT", "DC", "DE", "FL", "GA",
			                 "HI", "IA", "ID", "IL", "IN", "KS", "KY", "LA", "MA", "MD", "ME",
			                 "MI", "MN", "MO", "MS",  "MT", "NC", "ND", "NE", "NH", "NJ", "NM",
			                 "NV", "NY", "OH", "OK", "OR", "PA", "PR", "RI", "SC", "SD", "TN",
			                 "TX", "UT", "VA", "VT", "WA", "WI", "WV", "WY"),
			full=c("alaska","alabama","arkansas","arizona","california","colorado",
			               "connecticut","district of columbia","delaware","florida","georgia",
			               "hawaii","iowa","idaho","illinois","indiana","kansas","kentucky",
			               "louisiana","massachusetts","maryland","maine","michigan","minnesota",
			               "missouri","mississippi","montana","north carolina","north dakota",
			               "nebraska","new hampshire","new jersey","new mexico","nevada",
			               "new york","ohio","oklahoma","oregon","pennsylvania","puerto rico",
			               "rhode island","south carolina","south dakota","tennessee","texas",
			               "utah","virginia","vermont","washington","wisconsin",
			               "west virginia","wyoming")
		)
		
		return (as.character(stateInfo[which(stateInfo$state==toupper(twoLetterCode)),"full"]))
	}





	search_site <- function(searchItem, siteinfo){
		location <- searchItem$location
		search_term <- searchItem$search_term
		site_url = siteinfo$search_url
		site_key = siteinfo$site_key
		
		returnObj = getSearchItemResult()
		returnObj$site_key = unbox(site_key)
		
		switch(
			site_key,
			
	        "yelp"={
		        ###
		        ### 	YELP
				###		
				###
				###
				###		NOTE:  this grabs the first page of results only, which is up to 10 results.   
				###			It would be possible to grab another page or more of results with a loop. 
				###			Pretty Straight forward xpath queries to get the data we require
				###
				
				
				### profile_names <- html_text(html_nodes(doc,xpath='//*[@class="regular-search-result"]/div/div/div[1]/div/div[2]/h3/span/a'))
				### profile_urls <- html_attr(html_nodes(doc,xpath='//*[@class="regular-search-result"]/div/div/div[1]/div/div[2]/h3/span/a'),'href')
				### profile_specialties <- html_text(html_nodes(doc,xpath='//*[@class="regular-search-result"]/div/div/div[1]/div/div[2]/div[@class="price-category"]/span/a'))
				###  params for search url:  find_desc=doctors&find_loc=Philadelphia,+PA&start=0&cflt=familydr
				
				
				###		Setup additional_search_params
				returnObj$additional_search_params <- paste0("find_desc=",gsub(" ", "+", trimws(search_term)),"&find_loc=",gsub(" ", "+", trimws(location)))
				
				htmldoc <- getHTML(paste0(site_url, returnObj$additional_search_params))
				
				nodes <- html_nodes(htmldoc,xpath='//*[@class="regular-search-result"]')
				
				profile_names <- c()
				profile_urls <- c()
				profile_imgs <- c()
				profile_specialties <- c()				
				
				if(length(nodes) > 0){
					for (d in 1:length(nodes)){
						profile_names[d] <- html_text(html_nodes(nodes[d],xpath="div/div/div[1]/div/div[2]/h3/span/a"))
						profile_urls[d] <- html_attr(html_nodes(nodes[d],xpath='div/div/div[1]/div/div[2]/h3/span/a'),'href')
						profile_imgs[d] <- ""
						
						specialty <- ""
						specialties <- html_text(html_nodes(nodes[d],xpath='div/div/div[1]/div/div[2]/div[@class="price-category"]/span/a'))
						if(length(specialties) > 0){
							for(a in 1:length(specialties)){
								specialty <- paste0(specialty, ", ", specialties[a])
							}
							specialty <- substr(specialty, 3, nchar(specialty))
						}		
						profile_specialties[d] <- specialty
					}
				}
								
				returnObj$data <- data.frame(
					profileName = profile_names,
					profileSpecialty = profile_specialties,
					profileUrl  = profile_urls,
					profileImg  = profile_imgs,
					stringsAsFactors = FALSE
				)				
	        },
			
			
			
	        "ratemds"={
		        ###
		        ### 	RATEMDS
				###		
				###		RateMDs is a straight forward load/dice/loop type of scrape;  There is no 
				###		ajax call loading data after the page loads
				###
				###
				###		NOTE:  this grabs the first page of results only, which is up to 10 results.   
				###			It would be possible to grab another page or more of results with a loop. 
				###			Pretty Straight forward xpath queries to get the data we require
				###
				
				
				###		Setup additional_search_params
				location_parts <- tolower(trimws(strsplit(location, ",")[[1]]))
				location_parts[1] <- gsub(" ","-",location_parts[1])
				returnObj$additional_search_params <- unbox(URLencode(paste0(location_parts[2], "/", location_parts[1], "/?text=", search_term)))
				
				htmldoc <- getHTML(paste0(site_url, returnObj$additional_search_params))
				
				profile_names <- html_text(html_nodes(htmldoc,xpath='//*[@id="doctor-list"]/div/div/h2/a'))

				profile_urls <- html_attr(html_nodes(htmldoc,xpath='//*[@id="doctor-list"]/div/div/h2/a'),'href')
				
				profile_imgs <- gsub("//","",html_attr(html_nodes(htmldoc,xpath='//*[@id="doctor-list"]/div/div/img'),'src'))
				
				profile_specialties <- html_text(html_nodes(htmldoc,xpath='//*[@id="doctor-list"]/div/div/div/a'))
			
				returnObj$data <- data.frame(
					profileName = profile_names,
					profileSpecialty = profile_specialties,
					profileUrl  = profile_urls,
					profileImg  = profile_imgs,
					stringsAsFactors = FALSE
				)				
	        },
	        
	        "vitals"={
		        ###
		        ### 	VITALS:
		        ###
		        ###		NOTE:  this will return the first 10 results.  easy to change
		        ###		NOTE:  vitals loads data from an ajax call after the page loads.
		        ###			The server requires the request be a POST request with 
		        ###			a payload of json.  we must use the httr::POST().  The
		        ###			response is a Response object with the body being a json
		        ###			string that needs to be "parsed"
		        ###
				
				
				###		Setup the additional_params_str.  

				
				
				location_parts <- tolower(trimws(strsplit(location, ",")[[1]]))
				geocode_data <- geocode(location)

				returnObj$additional_search_params <- paste0('{"requests":[{"indexName":"vitals_search_v2_swap_prs2","params":"query=', gsub(' ', '%20',search_term), '&hitsPerPage=24&maxValuesPerFacet=1000&page=0&replaceSynonymsInHighlight=false&highlightPreTag=%3Cem%3E&getRankingInfo=true&aroundLatLng=', geocode_data$lat, '%2C', geocode_data$lon, '&aroundLatLngViaIP=false&aroundRadius=all"}]}')
				
			
				
				postResult <- POST(site_url, body= returnObj$additional_search_params, encode="form")
				
				#debug(postResult)
				
				content <- content(postResult, "parsed")
				
				#debug("CONTENT:")
				#debug(content)				
				
				docs <- content$results[[1]]$hits
				
				#debug(docs)
				docCount <- length(docs)
				
				profile_names <- c()
				profile_urls <- c()
				profile_imgs <- c()
				profile_specialties <- c()				
				
			
				
				if(docCount > 0){
					for (d in 1:docCount){
						profile_names[d] <- docs[[d]]$display_name
						profile_urls[d] <- docs[[d]]$url
						profile_imgs[d] <- ""
						###  Error Checking:  if no specialy exists, add ""  think docs[[d]]$specialties[[1]] was causing an error
						specialty <- "";
						
						
						if(length(docs[[d]]$specialty) > 0){
							for(a in 1:length(docs[[d]]$specialty)){
								specialty <- paste0(docs[[d]]$specialty[[a]], " ")
							}
						}
						profile_specialties[d] <- specialty
					}
				}
				
				
				#debug("NAMES:")
				#debug(profile_names)
				#debug(profile_urls)
				
				
				returnObj$data <- data.frame(
					profileName = profile_names,
					profileSpecialty = profile_specialties,
					profileUrl  = profile_urls,
					profileImg  = profile_imgs,
					stringsAsFactors = FALSE
				)				
								
	        },
	        "healthgrades"={
		        ###
		        ### 	HEALTHGRADES
		        ###
		        ###		NOTE:  no longer using the geolocation param.  Left it here 
		        ###			for future use:
		        ### 		geoInfo <- geocode(location)
		        ###
		        ###		NOTE:  this grabs the first 10 results.  We can change the # if needed
		        ###
		        ###		NOTE:  healthgrades loads data after the initial search page 
		        ###			has loaded.  The server requires a GET request with the 
		        ###			necessary params.  THe response is JSON. We will use
		        ###			jsonlite::fromJSON() 
		        ###						        

		        returnObj$additional_search_params <- unbox(URLencode(paste0("where=", location, "&what=", search_term)))
		        
		        
		        ### Need to put in some error checking.  If results dont exist, add ""
								
				json <- fromJSON(paste0(site_url, returnObj$additional_search_params))
				

				
				df <- json$search$searchResults$provider$results;
				if(is.data.frame(df) && nrow(df) > 0){

					profile_names <- df[,"displayName"]
	
					profile_urls <- df[,"providerUrl"]
	
					profile_imgs <- gsub("//","",df[,"imagePaths"])
	
					profile_specialties <- df[,"specialty"]		
					
					returnObj$data <- data.frame(
						profileName = profile_names,
						profileSpecialty = profile_specialties,
						profileUrl  = profile_urls,
						profileImg  = profile_imgs,
						stringsAsFactors = FALSE
					)
				}
	        },
	        "google"={
		        ###
		        ### 	GOOGLE
				###		
				###

				
				
				### profile_names <- html_text(html_nodes(doc,xpath='//*[@class="regular-search-result"]/div/div/div[1]/div/div[2]/h3/span/a'))
				### profile_urls <- html_attr(html_nodes(doc,xpath='//*[@class="regular-search-result"]/div/div/div[1]/div/div[2]/h3/span/a'),'href')
				### profile_specialties <- html_text(html_nodes(doc,xpath='//*[@class="regular-search-result"]/div/div/div[1]/div/div[2]/div[@class="price-category"]/span/a'))
				###  params for search url:  find_desc=doctors&find_loc=Philadelphia,+PA&start=0&cflt=familydr
				
				
				###  get the latitude and longitude of the city, state provided
				latLngObj <- geocode(location)
				lat <- latLngObj[1,"lat"]
				lng <- latLngObj[1,"lon"]
				
				debug("Google LAT:")
				debug(lat)
				debug ("GOOGLE:  LNG:")
				debug(lng)
				
				
				###  Modified Location for link to profile
				locationStr <- gsub(" ", "+", trimws(location))
				
				debug("Modified Location Str:  ")
				debug(locationStr)
				
				
				### Modified SearchTerm for Parameters
				searchTermStr <- gsub(" ", "+", trimws(search_term))
				
				debug("Modified SearchTerm:")
				debug(searchTermStr)
			
				###		Setup additional_search_params
				returnObj$additional_search_params <- paste0("keyword=",searchTermStr,"&location=",lat,",",lng)
				
				searchReturnObj <- fromJSON(paste0(site_url, returnObj$additional_search_params))

				profile_names <- c()
				profile_urls <- c()
				profile_imgs <- c()
				profile_specialties <- c()		
				
				debug("SEARCH RETURN OBJECT:")
				debug(searchReturnObj)
				
				if(searchReturnObj$status == "OK"){
					results <- searchReturnObj$results
					resultsCount <- nrow(results)
					
					if(resultsCount >0){
						profile_names <- results[,"name"]
						profile_specialties <- sapply(results[,"types"],function(x) paste0(x, collapse=", "))
						profile_imgs <- replicate(resultsCount, "")
						profile_urls <- sapply(results[,"place_id"], function(x) paste0("#q=", searchTermStr, "+", locationStr, "&place_id=", x))
									
						#q=jones+fort+collins,co&place_id=xxxxx
					
					}
					
					#if(length(nodes) > 0){
					#	for (d in 1:length(nodes)){
					#		profile_names[d] <- html_text(html_nodes(nodes[d],xpath="div/div/div[1]/div/div[2]/h3/span/a"))
					#		profile_urls[d] <- html_attr(html_nodes(nodes[d],xpath='div/div/div[1]/div/div[2]/h3/span/a'),'href')
					#		profile_imgs[d] <- ""
					#		
					#		specialty <- ""
					#		specialties <- html_text(html_nodes(nodes[d],xpath='div/div/div[1]/div/div[2]/div[@class="price-category"]/span/a'))
					#		if(length(specialties) > 0){
					#			for(a in 1:length(specialties)){
					#				specialty <- paste0(specialty, ", ", specialties[a])
					#			}
					#			specialty <- substr(specialty, 3, nchar(specialty))
					#		}		
					#		profile_specialties[d] <- specialty
					#	}
					#}
				}
								
				returnObj$data <- data.frame(
					profileName = profile_names,
					profileSpecialty = profile_specialties,
					profileUrl  = profile_urls,
					profileImg  = profile_imgs,
					stringsAsFactors = FALSE
				)	        
			},
	        "facebook"={
		        if(FALSE){
			        ####
			        #	I have disabled the facebook search for now due to issues with captcha/security type pages being 
			        #	served up when trying to access public pages.  This is suspected to be happening because  FB 
			        #	doesn't want us getting to the data in this manner.
			        #	
			        #	Potential solution:
			        #	Go back to using the FB graph api.  This would require a few days of testing to make sure it is 
			        #	even possible.
			        #		(1) use the "search" endpoint in the api to look for pages matching names submitted
			        #		(2) use the pageid of returned items to find url of facebook page so we can show in search results
			        #		(3) MIGHT be able to use this page id and the scraper may work at this point.
			        #		(4) If not, then we need to look into how to automatically ask for a page access_token so that we can access the "ratings" endpoint of the api for the page.  
			        #	Read this:  https://stackoverflow.com/questions/17315839/get-facebook-graph-api-page-review/20797173#20797173
			        #	NOTE:  It doesn't seem like i will be able to get page access tokens for OTHER pages.  Hopefully the search 
			        #   solution mentioned above will work (item #1) using the search endpoint to find the pages.
			        #
			        #	Get a Facebook app access token:
			        #   https://smashballoon.com/custom-facebook-feed/access-token/
			        #
			        #	NOTE:  FB Scrape still works.  If we can find the pageids for FB either through
			        #	screen scrape of search api, then we can still scrape FB data.
			        #   see fb_scrape_test_pinballjones and fb_scrape_test_cei in working directory
			        #	on local machine.
			        
			        
			        
			        ####
			        ###
			        ### 	FACEBOOK
					###		
					###
	
					# sample URL:  
					#https://www.facebook.com/public?query=st+elizabeth+healthcare+edgewood%2C+ky&type=pages
					#https://www.facebook.com/search/top/?q=pinball+jones+fort+collins%2C+colorado&opensearch=1
					
					debug("Facebook Location:")
					debug(location)
				
					#  if the location has a comma, split the location and trim both parts
					#  if the second part is 2 characters, then call the getStateFull() function
					#  if not, then use the location as is
					location_parts <- tolower(trimws(strsplit(location, ",")[[1]]))
					if(length(location_parts) == 2 & nchar(location_parts[2]) == 2){
						locationStr <- paste0(location_parts[1],", ",getStateFull(location_parts[2]))
					}else{
						locationStr <- location
					}
					
					debug("Location Str:")
					debug(locationStr)
					
					searchTermStr <- gsub(" ", "+", trimws(search_term))
					
					
					#/search/top/?q=pinball+jones+fort+collins%2C+colorado&opensearch=1				
					#returnObj$additional_search_params <- gsub(" ","+",paste0("query=",trimws(search_term)," ",locationStr,"&type=pages"))
					
					
					returnObj$additional_search_params <- gsub(" ","+",paste0("q=",trimws(search_term)," ",locationStr,"&opensearch=1"))
		
					fb_search_url <-paste0(site_url, returnObj$additional_search_params)
					
					debug("Facebook search url")
					debug(fb_search_url)
				
					profile_names <- c()
					profile_urls <- c()
					profile_imgs <- c()
					profile_specialties <- c()		
					
					#NEW 
					pageCode <- paste(readLines(fb_search_url, warn=FALSE), collapse="\n")
	
					codeTagMatch <- regexpr("<code[^>]*><!-- <div",pageCode)	
					pageCode <- substr(pageCode, codeTagMatch[1] + attr(codeTagMatch, "match.length") - 5, nchar(pageCode))
					
					endCodeTagMatch <- regexpr("--></code>", pageCode)
					pageCode <- substr(pageCode, 1, endCodeTagMatch[1] - 1)
						
					debug("Page Code:")
					debug(pageCode)	
					stop()
									
					fb_doc <- getHTML(pageCode)
					
					debug("Facebook Doc:")
					debug(fb_doc)
				
					
					################################
					## PROFILE NAMES:
					################################
					profile_names <- html_text(html_nodes(fb_doc,xpath="//*[@id='all_search_results']/div/div/div/div/div[1]/div/div/div[2]/div/a/div"))
					###################
					##  Profile URLS
					###################
					profile_urls <- html_attr(html_nodes(fb_doc,xpath="//*[@id='all_search_results']/div/div/div/div/div[1]/div/div/div[2]/div/a"), "href")
					profile_urls <- gsub("https://www.facebook.com", "", profile_urls)
					###################
					##  FB Page IDS
					####################
					pageids <- html_attr(html_nodes(fb_doc,xpath="//*[@id='all_search_results']/div/div"), "data-bt")	
					beginPageIDs <- regexpr("\"id\":",pageids)				
					pageids <- substr(pageids, beginPageIDs + attr(beginPageIDs, "match.length"), nchar(pageids))
					endPageIDs <- regexpr(",", pageids)
					pageids <- substr(pageids, 1, endPageIDs - 1)
					
	
					##  Add pageids to end of profile_urls	
					profile_urls <- paste0(profile_urls,"?pageid=",pageids)
									
					debug("Profile URLS:")
					debug(profile_urls)				
									
					returnObj$data <- data.frame(
						profileName = profile_names,
						profileSpecialty = replicate(length(profile_names), ""),
						profileUrl  = profile_urls,
						profileImg  = replicate(length(profile_names), ""),
						stringsAsFactors = FALSE
					)
				}
			}
		)
		
		return(
			returnObj
		)	
	}
	

####################################################
###
###		getHTML(url)
### 
###		retrieve html from a url
###		
###
####################################################
	getHTML <- function(url){
		doc <- read_html(url, verbose=FALSE)
		return(doc)
	}




####################################################
###
###		getSearchItem()
### 
###		 
###		
###
####################################################	
	getSearchItem <- function(search_for,location){
		return (
			list(
				search_term = unbox(search_for),
				location = unbox(location),
				site_results = list()
			)	
		)
	}
	
	
####################################################
###
###		getSearchItemResult()
### 
###		
###		
###
####################################################	
	getSearchItemResult <- function(){
		return (
			list(
				site_key = "",
				additional_search_params = "",
				data = data.frame(
					profileName = character(), 
					profileSpecialty=character(), 
					profileUrl=character(), 
					profileImg=character(),
					stringsAsFactors=FALSE
				)
			)
		)
		
		
	}
	
	
	
#	getSites <- function(){
#		
#		
#		#return(
#		#	data.frame(
#		#		site_key = c (
#		#			"vitals", 
#		#			"ratemds", 
#		#			"healthgrades",
#		#			"yelp",
#		#			"google",
#		#			"facebook"
#		#		),
#		#		site_title = c (
#		#			"Vitals", 
#		#			"RateMDs", 
#		#			"HealthGrades",
#		#			"Yelp",
#		#			"Google",
#		#			"Facebook"
#		#		),
#		#		search_url = c (
#		#			"http://592dc5anbt-dsn.algolia.net/1/indexes/*/queries?x-algolia-agent=Algolia%20for%20vanilla%20JavaScript%203.18.1&x-algolia-application-id=592DC5ANBT&x-algolia-api-key=3abbd60cc696b3a9d83ee2fcae88e351", 
#		#			"https://www.ratemds.com/best-doctors/", 
#		#			"https://www.healthgrades.com/api3/usearch?distances=National&sort.provider=bestmatch&categories=1&pageSize.provider=10&pageNum=1&isFirstRequest=true&",
#		#			"https://www.yelp.com/search?",
#		#			"https://maps.googleapis.com/maps/api/place/nearbysearch/json?radius=50000&key=AIzaSyDWmQOAoJj3B6-IwCrgbNqEhCgVjzwilNU&",
#		#			""
#		#		),
#		#		site_home = c (
#		#			"http://www.vitals.com", 
#		#			"https://www.ratemds.com", 
#		#			"https://www.healthgrades.com",
#		#			"https://www.yelp.com",
#		#			"http://google.com",
#		#			"http://facebook.com"
#		#		),
#		#		stringsAsFactors = FALSE							
#		#	)
#		#)
#	}

####################################################
###		END:   FUNCTIONS
####################################################


####################################################
###		BEGIN:   REQUIRED PACKAGES
####################################################

	if (! require(xml2, quietly = TRUE)){ 
	    install.packages(c("xml2"), repos='http://cran.us.r-project.org')
		library("xml2")
	}
	
	if (! require(stringr, quietly = TRUE)){
	    install.packages("stringr", repos='http://cran.us.r-project.org')
		library("stringr")
	}
	
	if (! require(rvest, quietly = TRUE)){ 
	    install.packages("rvest", repos='http://cran.us.r-project.org')
		library("rvest")
	}

	if (! require(jsonlite, quietly = TRUE)){ 
	    install.packages("jsonlite", repos='http://cran.us.r-project.org')
		library("jsonlite")
	}
	
	if (! require(ggmap, quietly = TRUE)){ 
	    install.packages("ggmap", repos='http://cran.us.r-project.org')
		library("ggmap")
	}	
	
	
	if (! require(httr, quietly = TRUE)){ 
	    install.packages("httr", repos='http://cran.us.r-project.org')
		library("httr")
	}			
	
	
	if (! require(RMySQL, quietly = TRUE)){ 
	  install.packages("RMySQL", repos='http://cran.us.r-project.org')
	  library("RMySQL")
	}
	
####################################################
###		END:   REQUIRED PACKAGES
####################################################




####################################################
###		BEGIN:   VARS
####################################################
	
	###
	###  	Turn debug prints on/off
	###		
	testing <- TRUE
	
	### Set up database connection
	
	###  Default values for production site:  (dev_setting file will overwrite these values if exists)
	phantomjs_version <- "phantomjs-2.1.1-linux-x86_64"
	db_name <- "xld-connectedmd"
	db_user <- "root"
	db_pwd <- "Nn1yhwz4dnq3"
	db_host <- "127.0.0.1"
	
	# Load the dev settings file if needed
	if(file.exists("../dev-environment.txt")){
	  dev_settings <- readLines("../dev-environment.txt", warn=FALSE)
	  for (i in 1:length(dev_settings)) {
	    temp <- strsplit(dev_settings[i],"=")		
	    assign(temp[[1]][1],temp[[1]][2])	
	  }	
	}
	
	
	### Set up database connection
	db <- dbConnect(MySQL(), user=db_user, password=db_pwd, dbname=db_name, host=db_host)


	
	###
	### 	Setup the "searchObj" object.  This is the structure that will be turned into json
	### 	and written to the output file
	###
	searchObj =  list(
		location = "", 
		doctors_str = "",
		doctors = "",
		searchDir = "",
		inputfile = unbox("search.txt"),
		outputfile = unbox("search_results.txt"),
		sites = "",
		results = list()		
	)
	
####################################################
###		END:   VARS
####################################################


####################################################
###
###		BEGIN:  CORE CODE
###
####################################################

	###
	### 	Get the input and output filenames
	###
	args <- commandArgs(TRUE)
	searchObj$searchDir <- unbox(args[1])
	

	###
	### 	Set the working directory
	###
	workingDir <- paste0(getwd(),"/r_working_dir/",args[1])
	setwd(workingDir)
	
	
		###  Load in the Sites.csv
###  Note:  no longer reading site information from a csv file.  Data is stored in the
###  search_sites table
#	searchSiteInfo <- read.csv("Sites.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)
	searchSiteInfo <- dbReadTable(db, "search_sites")
	searchObj$sites = searchSiteInfo
	
	sink("search_debug.txt", append=FALSE, split=TRUE)	

	###
	### 	Open input file and get "location" and process delimited "doctor" string
	###
	if (file.exists(searchObj$inputfile)){
		inFile <- file(searchObj$inputfile,open="r")
		inLines <-readLines(inFile)
		
		searchObj$location = unbox(inLines[1])
		searchObj$doctors_str = unbox(inLines[2])
		searchObj$doctors = strsplit(inLines[2],"~")[[1]]
	
		numDoctors <- length(searchObj$doctors)
		numSites <- nrow(searchObj$sites)
		if(numDoctors > 0){
			for (d in 1:numDoctors){
				searchItem = getSearchItem(searchObj$doctors[d], searchObj$location)
				for(s in 1:numSites){
					searchItem_results = search_site(searchItem, searchObj$sites[s,])
					searchItem$site_results[[length(searchItem$site_results)+1]] = searchItem_results
				}
				searchObj$results[[length(searchObj$results)+1]] = searchItem
			}
		}	
	} 

	
	###
	### 	Write doctorData to file using jsonlite
	###
	json <- toJSON(searchObj)
	fileConn<-file(searchObj$outputfile)
	writeLines(json, fileConn)
	close(fileConn)

####################################################
###
###		END:  CORE CODE
###
####################################################



