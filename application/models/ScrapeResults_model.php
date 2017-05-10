<?php
	class ScrapeResults_model extends CI_Model {
		public function __construct(){
			$this->load->database();
		}
		
		public function get_results($working_dir, $scrapeFileReturn){
			error_log("Scrape Output File:  ". $scrapeFileReturn);
			
			$lines = file($working_dir."/".$scrapeFileReturn);
			//error_log(json_encode($lines));
			
			
			
		  	//$scrapeFileReturn = str_replace('"','',str_replace('[1] "', '', $scrapeFileReturn));
			
			//error_log("ScrapeFileReturn after str replace: ".$scrapeFileReturn );
			//list($scrapeFile, $reviewFile) = explode("~",$scrapeFileReturn);	
			
			//error_log("Split Files:");
			//error_log($scrapeFile);
			//error_log($reviewFile);		
			
	    	$fileData = new stdClass;
	    	$fileData->all_files_title = "All Scrape Files";
	    	$fileData->debug_files_title = "Debug Files";
	    	$fileData->source_files_title = "Input Files";
	    	$fileData->output_files_title = "Result Files";
		    $fileData->all_files = array();
		    $fileData->debug_files = array();
		    $fileData->source_files = array();
		    $fileData->output_files = array();		
			foreach($lines as $l){
				//error_log("Line");
				//error_log($l);
				$fileinfo = explode("~", $l);
				$csvObj = new stdClass;
				$csvObj->title = $fileinfo[1];
				$csvObj->file_location = "/".$working_dir."/".$fileinfo[0];
				$csvObj->description = $fileinfo[2];
				$csvObj->type = trim($fileinfo[3]);
								
				switch($csvObj->type){
					case 'debug':
						$fileData->debug_files[] = $csvObj;
						break;
					case 'source':
						$fileData->source_files[] = $csvObj;
						break;						
					case 'output':
						$fileData->output_files[] = $csvObj;
						break;
				}
				$fileData->all_files[] = $csvObj;
			}
			//error_log("csvfile array:");
			//error_log(json_encode($csvfiles));
		  	return $fileData;
		}
	}
?>