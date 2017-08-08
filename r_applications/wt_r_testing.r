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


	testing <- TRUE
	debug <- function(str){
		if(testing == TRUE){
			print(str)
		}
	}	
	working_dir <- paste0(getwd(),"/r_working_dir/wt_r_testing")
	dir.create(working_dir, showWarnings = FALSE)
	setwd(working_dir)
	sink("wt_r_testing_debug.txt", append=FALSE, split=TRUE)
	debug("This is my testing application debug file!")
	
	
	
	
#####################################
#	TEST APPLICATION CODE BELOW	    #
#####################################	




url <- "https://www.google.com/search?q=facebook+cincinnati+eye+institute+cincinnati%2C+oh"
searchText <- paste(readLines(url, warn=FALSE), collapse="\n")

bodyTagStart <- regexpr("<body[^>]*>",searchText)
debug(bodyTagStart)

bodyTagEnd <- regexpr("</body>",searchText)
debug(bodyTagEnd)

searchText <- str_trim(searchText)

bodyText <- substr(searchText, bodyTagStart[1] + attr(bodyTagStart,"match.length"), bodyTagEnd[1] -1)
bodyText <- substr(bodyText, regexpr("^(.*?)<script"))



debug(bodyText)




doc <- read_html(bodyText,verbose=FALSE)
searchResults <- html_nodes(doc, xpath="//*[@class='g']")
debug("SearchResults")
debug(searchResults)
debug(length(searchResults))



