
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
	search_site <- function(searchItem, siteinfo){
		location <- searchItem$location
		search_term <- searchItem$search_term
		site_url = siteinfo$search_url
		site_key = siteinfo$site_key
		
		returnObj = getSearchItemResult()
		returnObj$site_key = unbox(site_key)
		
		switch(
			site_key,
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
				returnObj$additional_search_params <- paste0(
					'{"requests":[{"indexName":"vitals_search","params":"query=',
					paste0('%20',location_parts[1],'%2C%20',location_parts[2],'%20',gsub(' ', '%20',search_term)),
					'&aroundLatLngViaIP=false&getRankingInfo=true&hitsPerPage=10&facets=*&page=0&attributesToRetrieve=*&facetFilters=%5B%5B%5D%2C%5B%5D%2C%5B%5D%2C%5B%5D%2C%5B%5D%2C%5B%5D%2C%5B%22status%3Aactive%22%5D%5D&advancedSyntax=true"}]}'
				)
				
				postResult <- POST(site_url, body= returnObj$additional_search_params, encode="form")
				content <- content(postResult, "parsed")
				
				docs <- content$results[[1]]$hits
				docCount <- length(docs)
				
				profile_names <- c()
				profile_urls <- c()
				profile_imgs <- c()
				profile_specialties <- c()				
				
				
				debug ("<-------------- BEGIN VITALS DOCS ----------------------->")
				debug (paste0("site_url:  ",site_url))
				debug (paste0("search term:  ",search_term))
				debug (paste0("doctor count:  ",docCount))
				debug ("<-------------- END VITALS DOCS ----------------------->")
				
				if(docCount > 0){
					for (d in 1:docCount){
						profile_names[d] <- docs[[d]]$display_name
						profile_urls[d] <- docs[[d]]$url
						profile_imgs[d] <- ""
						###  Error Checking:  if no specialy exists, add ""  think docs[[d]]$specialties[[1]] was causing an error
						specialty <- "";
						
						debug("<--------------------- specialty ------------------------>")
						debug(docs[[d]])
						debug("Length:")
						debug(length(docs[[d]]$specialty))
						
						
						if(length(docs[[d]]$specialty) > 0){
							for(a in length(docs[[d]]$specialty)){
								specialty <- paste0(docs[[d]]$specialty[[a]], " ")
							}
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
				
				debug("<<<<<<<-------------- BEGIN HG  ------------>>>>>>>>>")
				##debug(nrow(json$search$searchResults$provider$results))
				##if(json$search$searchResults$provider$results == NULL){
				##	debug("RESULTS ARE NULL")
				##}else{
				##	debug("RESULTS NOT NULL")
				##}
				debug(site_url)
				debug("additional_search_params: ")
				debug(returnObj$additional_search_params)
				debug("search_term:  ")
				debug(search_term)
				debug("<<<<<<<-------------- END HG  ------------>>>>>>>>>")
				
				df <- json$search$searchResults$provider$results;
				if(is.data.frame(df) && nrow(df) > 0){
					##debug("Results length: ")
					##debug(nrow(json$search$searchResults$provider$results))
				
				
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
	
	
	
	getSites <- function(){
		return(
			data.frame(
				site_key = c (
					"vitals", 
					"ratemds", 
					"healthgrades"
				),
				site_title = c (
					"Vitals", 
					"RateMDs", 
					"HealthGrades"
				),
				search_url = c (
					"http://592dc5anbt-dsn.algolia.net/1/indexes/*/queries?x-algolia-agent=Algolia%20for%20vanilla%20JavaScript%203.18.1&x-algolia-application-id=592DC5ANBT&x-algolia-api-key=3abbd60cc696b3a9d83ee2fcae88e351", 
					"https://www.ratemds.com/best-doctors/", 
					"https://www.healthgrades.com/api3/usearch?distances=National&sort.provider=bestmatch&categories=1&pageSize.provider=10&pageNum=1&isFirstRequest=true&"
				),
				site_home = c (
					"http://www.vitals.com", 
					"https://www.ratemds.com", 
					"https://www.healthgrades.com"
				),
				stringsAsFactors = FALSE							
			)
		)
	}

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
		sites = getSites(),
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

	###debug("END:  ")
	###debug(searchObj)
	
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



