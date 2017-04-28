<?php
	class ScrapeResults_model extends CI_Model {
		public function __construct(){
			$this->load->database();
		}
		
		public function get_results($working_dir, $scrapeFileReturn){
			error_log("ScrapeResults_model:  get_results");
			error_log("scrapeFileReturn:  ". $scrapeFileReturn);
			
			
		  	$scrapeFileReturn = str_replace('"','',str_replace('[1] "', '', $scrapeFileReturn));
			list($scrapeFile, $reviewFile) = explode("~",$scrapeFileReturn);			
			
	    	$csvfiles = array();		      		

			$csvObj = new stdClass;
			$csvObj->title = $scrapeFile;
			$csvObj->file_location = "/".$working_dir."/".$scrapeFile;
		  	$csvfiles[] = $csvObj;	

			$csvObj = new stdClass;
			$csvObj->title = $reviewFile;
			$csvObj->file_location = "/".$working_dir."/".$reviewFile;
		  	$csvfiles[] = $csvObj;	

			$csvObj = new stdClass;
			$csvObj->title = "Profile Report";
			$csvObj->file_location = "/".$working_dir."/profileReport.csv";
		  	$csvfiles[] = $csvObj;


			$csvObj = new stdClass;
			$csvObj->title = "Subjects.csv";
			$csvObj->file_location = "/".$working_dir."/Subjects.csv";
		  	$csvfiles[] = $csvObj;

			$csvObj = new stdClass;
			$csvObj->title = "Subject_Site_Identifiers.csv";
			$csvObj->file_location = "/".$working_dir."/Subject_Site_Identifiers.csv";
		  	$csvfiles[] = $csvObj;

			$csvObj = new stdClass;
			$csvObj->title = "Sites.csv";
			$csvObj->file_location = "/".$working_dir."/Sites.csv";
		  	$csvfiles[] = $csvObj;
				  	
			$csvObj = new stdClass;
			$csvObj->title = "scrape_debug.txt";
			$csvObj->file_location = "/".$working_dir."/scrape_debug.txt";
		  	$csvfiles[] = $csvObj;					 
		 
		 
		 
	  				  	
				  	
		  	return $csvfiles;
		}
	}
?>