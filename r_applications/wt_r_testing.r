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
	