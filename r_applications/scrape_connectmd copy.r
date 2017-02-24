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

{if (require(xml2, quietly = TRUE)) 
    0 
else 
    install.packages(c("xml2"), repos='http://cran.us.r-project.org')}
library("xml2")
{if (require(stringr, quietly = TRUE)) 
    0 
else 
    install.packages("stringr", repos='http://cran.us.r-project.org')}
library("stringr")
{if (require(rvest, quietly = TRUE)) 
    0 
else 
    install.packages("rvest", repos='http://cran.us.r-project.org')}
library("rvest")
{if (require(lsa, quietly = TRUE)) 
    0 
else 
    install.packages(c("lsa"), repos='http://cran.us.r-project.org')}
library("lsa")

### Get the command line argument value (should be a file name.
### arg <- c("https://www.healthgrades.com/physician/dr-ross-mchenry-2csp9", "xpath", "regex",
###             "http://www.vitals.com/doctors/Dr_Ross_Mchenry.html", "xpath", "regex")
### https://www.ratemds.com/doctor-ratings/2259229/Dr-ROSS-MCHENRY-CRESTVIEW+HILLS-KY.html#ratings 
### https://www.healthgrades.com/physician/dr-ross-mchenry-2csp9 
### https://www.ratemds.com/doctor-ratings/2259255/Dr-DANIEL+G.-FAGEL-Crestview+Hills-KY.html 
### url <- "https://www.google.com/?gws_rd=ssl#q=Gregory+L.+Salzman%2C+MD"
### url <- "https://www.healthgrades.com/physician/dr-daniel-fagel-3fxtn"
### url <- "https://www.healthgrades.com/physician/dr-gregory-salzman-2p9yd"
### url <- "https://www.healthgrades.com/physician/dr-alan-safdi-y7c2w"  ### 	Ohio GI and Liver Institute
### url <- "http://www.imdb.com/title/tt1490017/"
### aURL <- "https://www.ratemds.com/doctor-ratings/37408/Dr-Franklin+D.-Richards-BETHESDA-MD.html"
### html_doc <- read_html(url, verbose=TRUE)
### xpath01 <- "//text()"
### xpath01 <- '//*[@id="sdaon"]/div[1]/div/div/div/div[1]/div/div/div/div[2]'  ### xpath to average rating
### xpath02 <- '//*[@id="ng-app"]/body/div[2]/div[1]/div/div/div/div[2]/div[3]/span'  ### to rating
### xpath03 <- '//*[@id="left-content"]/span/div/span/span[2]/span/span'
### nodes <- html_nodes(html_doc, xpath=xpath01)
### length(nodes)
### str(nodes[[1]])
### nodes <- html_nodes(html_doc, xpath=xpath03)
###      kids <- html_children(nodes)
###  
### tmp_result <- html_attr(nodes, "title")
### xpath03 <- '//*[@id="left-content"]/span/div/span/span[2]/span/span' ### the ratings span on ratemds
### //*[@id="left-content"]/span/div/span/span[2]/span/span/span[6]/div[1]/div[1]/div[2]/span/span
### xpath03 <- '/div/div[1]/div[2]/span/span'  ### the individual rating on each page
### xpath03 <- '//*[@id="rating-3164875"]/div[1]/div[2]/span/span'
### xpath04 <- 'div[1]/div[1]/div[2]/span/span'
### kids <- html_children(nodes)
### ratingSpans <- html_nodes(kids, xpath=xpath04)
###    html_attr(ratingSpans , "title")

### Start here for demo of current capability for ConnectMD
### Set working directory and load needed functions
setwd("C:/Users/Public/Documents/R/connectMD/")
source("scrapeFunctions.R")

### Read subject, site, xpath expression, and other needed data
report_colnames <- readLines("col_names.txt", warn = FALSE, encoding = "UTF-8")  ### column names for results report
dataids <- read.csv("data_xpath_elements.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)  ### data item identifiers, xpath, and html elements 
sites <- read.csv("Sites.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)  ### site names and urls
subjects <- read.csv("Subjects.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)  ### subject names and ids
subj_site_id <- read.csv("Subject_Site_Identifiers.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)  ### subject ids and url differentiators


### Create an empty matrix
### Doc's name, data label, data value, site
### results <- matrix(data=NA_character_, nrow=0, ncol=88) 
results <- matrix(data="", nrow=0, ncol=88) 
colnames(results) <- report_colnames
### Loop through all data and grab the data elements from the sites with the corresponding xpath expression
for (i in 1:length(subjects[["subject_key"]])) {  ### loop over docs  i <- 14  j <- 1 k <- 7
   aSubjKey <- subjects[i,"subject_key"]
   siteList <- subj_site_id[subj_site_id[["subject_key"]]==aSubjKey,]
   aDocName <- subjects[i,"subject_name"]
   temp <- matrix(data="", nrow=1, ncol=88)   ### is.na(temp[1,1]) 
   colnames(temp) <- report_colnames
   temp[1,"name"] <- aDocName 
   for (j in 1:length(siteList[["site_key"]])) {   ### Loop over sites j <- 1
      aSiteKey <- siteList[j,"site_key"]
      aURL <- paste0(sites[sites[["site_key"]]==aSiteKey,"site_base_url"], siteList[j,"site_subject_ident"])
      html_doc <- read_html(aURL, verbose=FALSE)
      dataItemList <- dataids[dataids[["site_key"]]==siteList[j,"site_key"],]   
      for (k in 1:length(dataItemList[["data_id"]])) {
         if (dataItemList[k,"element"]=="exist") {
            temp[1,dataItemList[k,"data_id"]] <- getExistance(html_doc, xp=dataItemList[k,"xpath"])
         }
         if (dataItemList[k,"element"]=="text") {
            temp[1,dataItemList[k,"data_id"]] <- getTextContent(html_doc, xp=dataItemList[k,"xpath"])
         }
         if (dataItemList[k,"element"]=="attribute") {
            temp[1,dataItemList[k,"data_id"]] <- getAttributeValue(html_doc, xp=dataItemList[k,"xpath"], element_id=dataItemList[k,"element_id"])
         }
      }
      ### Handle special case data elements without the loop
      if (aSiteKey == "ratemds") {
         temp[1,"r_num_reviews"] <- temp[1,"r_num_ratings"] 
         tmpRatsRvws <- getRMDSRatingsReviews(temp[1,"r_num_ratings"], aURL)
         print(paste0("doctor: ", aDocName ))
         print(paste0("str tmpRatsRvws: ", str(tmpRatsRvws)))
         print(paste0("tmpRatsRvwsRatings: ", tmpRatsRvws$ratings))
         print(paste0("tempRatings4: ", tmpRatsRvws$ratings[4], " tempRatings5: ", tmpRatsRvws$ratings[5], "\n"))
         if (is.null(tmpRatsRvws)) tmpRatsRvws <- list(ratings=c(0,0,0,0,0), reviews="") 
         temp[1,"r_pos_ratings"] <- tmpRatsRvws$ratings[4] +  tmpRatsRvws$ratings[5] 
         temp[1,"r_neut_ratings"] <- tmpRatsRvws$ratings[3] 
         temp[1,"r_neg_ratings"] <- tmpRatsRvws$ratings[1] +  tmpRatsRvws$ratings[2] 
         temp[1,"r_pos_reviews"] <- ""
         temp[1,"r_neut_reviews"] <- ""
         temp[1,"r_neg_reviews"] <- ""
         temp[1,"r_neg_addressed"] <- ""
      }   ### temp[1,"r_num_ratings"] <- 1
      if (aSiteKey == "vitals") {
         if (temp[1,"v_num_ratings"] > 0) {
            tmpRatsRvws <- getVitalsRatingsReviews(temp[1,"r_num_ratings"], temp[1,"r_num_reviews"], aURL)
            temp[1,"v_pos_ratings"] <- tmpRatsRvws$ratings[4] +  tmpRatsRvws$ratings[5] 
            temp[1,"v_neut_ratings"] <- tmpRatsRvws$ratings[3] 
            temp[1,"v_neg_ratings"] <- tmpRatsRvws$ratings[1] +  tmpRatsRvws$ratings[2] 
            temp[1,"v_pos_reviews"] <- ""
            temp[1,"v_neut_reviews"] <- ""
            temp[1,"v_neg_reviews"] <- ""
            temp[1,"v_neg_addressed"] <- ""
         } else { ### else, number of reviews was zero
            temp[1,"v_pos_ratings"] <- temp[1,"v_neut_ratings"] <- temp[1,"v_neg_ratings"] <- 0
            temp[1,"v_pos_reviews"] <- temp[1,"v_neut_reviews"] <- temp[1,"v_neg_reviews"] <- 0
            temp[1,"v_neg_addressed"] <- 0
         }
      }
      if (aSiteKey == "healthgrades") {
         if (temp[1,"h_num_ratings"] > 0) {
            temp[1,"h_own_prof"] <- hg_GetOwned(html_doc)
###            temp[1,"h_text_reviews"] <- hg_GetReviews(html_doc)
            tmpRats <- as.numeric(hg_GetRatings(html_doc))
            temp[1,"h_pos_ratings"] <- tmpRats[4] +  tmpRats[5] 
            temp[1,"h_neut_ratings"] <- tmpRats[3] 
            temp[1,"h_neg_ratings"] <- tmpRats[1] +  tmpRats[2] 
            temp[1,"h_pos_reviews"] <- ""
            temp[1,"h_neut_reviews"] <- ""
            temp[1,"h_neg_reviews"] <- ""
            temp[1,"h_neg_addressed"] <- ""
         }
      }
         ###      print(c(i, j, docData[j,"site"],aURL, docData[j,"xpath"] ))
   }
   results <- rbind(results, temp)
}
### Write results to a CSV spreadsheet
filename <- paste0("result", format(Sys.time(), format="%Y%m%d"), ".csv")
write.table(results, file=filename, quote = TRUE, sep = ",", row.names = FALSE, col.names = TRUE)

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

