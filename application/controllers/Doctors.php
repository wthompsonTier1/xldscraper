<?php
	class Doctors extends CI_Controller{
        public function __construct()
        {
                parent::__construct();
                $this->load->model('Searchsites_model');
                $this->load->model('ScrapeResults_model');
                $this->load->model("Help_model");
                $this->load->helper('url');
				$this->output->delete_cache();
                
        }

        
        public function bulkadd(){
	       	if ( ! file_exists(APPPATH.'views/doctors/bulkadd.php'))
	        {
	                // Whoops, we don't have a page for that!
	                show_404();
	        }	        
	        $this->load->helper('form');
			$this->load->library('form_validation');
				        
			$data['title'] = "Search Doctors";
			$data['sitetitle'] = "XLD Data Mining";
			$data['helpitems'] = $this->Help_model->get_help_items();

	        
	        $this->load->view('templates/header', $data);
	        $this->load->view('templates/navigation', $data);
	        	        
		    //$this->form_validation->set_rules('location', 'Location', 'required');
		    //$this->form_validation->set_rules('doctors', 'Doctors', 'required');

		    //if ($this->form_validation->run() === FALSE)
      
		    $this->load->view('doctors/bulkadd',$data);
		    /*
			  -need to create a text file with the city, state and doctors names in the R working directory
			  -need to kick off the r exe file and pass the filename 
			  -R needs to read in the file and search.  Maybe initially have it create a simple json string and
			  write to a file  so the we can test the review page
			    
			    
			*/
	        //$this->news_model->set_news();        
		    $this->load->view('templates/footer',$data);
        }		
        
        public function ajax(){
	        $data = $this->input->post();
	        switch($data['mode']){
		        case 'get-google-place':
		        	$url = "https://maps.googleapis.com/maps/api/place/details/json?placeid=".$data['place_id']."&key=AIzaSyDWmQOAoJj3B6-IwCrgbNqEhCgVjzwilNU";
		        	error_log("PLACE_ID URL:  ".$url);
		        	$json = file_get_contents($url);
					//$obj = json_decode($json);
		        	
		        	echo $json;
		        	break;
		        case 'rename_directory':
		        	if(file_exists("r_working_dir/".$data['newval'])){
		        		echo "FAIL";
		        	}else{
			        	if(rename("r_working_dir/".$data['oldval'], "r_working_dir/".$data['newval'])){
				        	echo "SUCCESS";
			        	}else{
				        	echo "FAIL";
			        	}
		        	}
		        	break;
		    	case 'get_previous_scrapes':
		    		$scrape_dirs = scandir("r_working_dir");
		    		echo(json_encode($scrape_dirs));
		    		break;
		      case 'search_doctors':
		      		$searchDir = "xld_scrape_".date("Ymd-His");
			  		$inputFile = "r_working_dir/".$searchDir."/search.txt";
		      		if(!file_exists(dirname($inputFile)))
			  			mkdir(dirname($inputFile), 0777, true);		      		
			  			
			  		$file = fopen($inputFile,"w");
			  		fwrite($file,$data['location']."\n");
			  		fwrite($file,implode("~",explode("\n",$data['doctors']))."\n");
			  		fclose($file);
			  		
			  		/*  create the Sites.csv file in the working directory */
			  		
			  		$this->Searchsites_model->createCSV("r_working_dir/".$searchDir);
			  		
			  		
			  		
			  		// execute R script from shell
			  		// this will save a plot at temp.png to the filesystem
			  		//exec("Rscript r_applications/search_doctors.R ".$filename." ".$results_filename, $output);
			  		exec("Rscript r_applications/search_doctors.r ".$searchDir, $output);
			  		
			  		/*
			  		error_log("After Rscript");
			  		if(!file_exists("r_working_dir/".$searchDir."/results.txt"))
			  			error_log("Does Not Exist");
			  		else
			  			error_log("Exists");
			  			
			  		error_log(file_get_contents("r_working_dir/".$searchDir."/results.txt"));
			  		*/
			  		echo file_get_contents("r_working_dir/".$searchDir."/search_results.txt");	

			  		//echo $filename." ". $results_filename;
		      	break;
		      	
		      case 'create-csv-files':
		      		//error_log("Inside create-csv-files");
		      		$csvfiles = array();
		
		      		$obj = new stdClass;
		      		$obj->sites = $data['sites'];
		      		$obj->profiles = $data['profiles'];
		      		$obj->searchDir = $data['searchDir'];
		      		
		      		$working_dir = "r_working_dir/".$obj->searchDir;
		      		
		      		//Write profile information to file for future use
		      		$fp = fopen($working_dir.'/profiles-to-scrape.txt', 'w');
		      		fwrite($fp, json_encode($obj));
		      		fclose($fp);
		      		
			  		/*  Create the Sites.csv  */
			  		$this->Searchsites_model->createCSV($working_dir);			            
					
				  	
				  	/* Create the Subject_Site_Identifiers.csv   and Subjects.csv*/
				  	$ssi_fp = fopen($working_dir.'/Subject_Site_Identifiers.csv', 'w');
				  	fputcsv($ssi_fp, array("subject_key","site_key","site_subject_ident"));					
				  	
				  	$s_fp = fopen($working_dir.'/Subjects.csv', 'w');
				  	fputcsv($s_fp, array("subject_key","subject_name"));
				  	
				  	foreach($obj->profiles as $subject){
						fputcsv($s_fp, array(
							$this->createSubjectId($subject['search_item_num'],$subject['search_term']),
							$subject['search_term']
							)
						);
						
						foreach($subject['healthgrades'] as $profile){
							$this->addToCsv($ssi_fp, $subject, "healthgrades", $profile);	
					  	}
						foreach($subject['vitals'] as $profile){
							$this->addToCsv($ssi_fp, $subject, "vitals", $profile);	
					  	}
						foreach($subject['ratemds'] as $profile){
							$this->addToCsv($ssi_fp, $subject, "ratemds", $profile);	
					  	}
						foreach($subject['yelp'] as $profile){
							$this->addToCsv($ssi_fp, $subject, "yelp", $profile);	
					  	}
						foreach($subject['google'] as $profile){
							/*  only add the place_id portion of profile string */
							//error_log("PLACE_ID: ".explode("place_id=", $profile)[1]);
							$parts = explode("place_id=", $profile);
							if(count($parts) == 2){
								$profile = trim($parts[1]);
							}
							$this->addToCsv($ssi_fp, $subject, "google", $profile);	
					  	}
						foreach($subject['facebook'] as $profile){
							/*  only add the pageid portion of profile string */
							$parts = explode("pageid=", $profile);
							if(count($parts) == 2){
								$profile = trim($parts[1]);
							}
							$this->addToCsv($ssi_fp, $subject, "facebook", $profile);		
					  	}		
					}
					fclose($s_fp);
					fclose($ssi_fp);
				
				  	/*   Kick off data scrape application  */				  	
				  	$scrapeFileReturn = exec("Rscript r_applications/scrape_connectmd.r ".$obj->searchDir, $output);
				  	
				  	

				  	

		      		$scrapeResultsModel = $this->ScrapeResults_model->get_results($working_dir, $scrapeFileReturn);
	
		      		
		      		echo json_encode($scrapeResultsModel);
		      		exit();
		      	break;
	        }
        }
        
        private function createSubjectId($itemnum, $val){
	        /*  replace anything that is not a-z with a "-" */
	         $val = strtolower(preg_replace("/[^a-zA-Z]/", "-", $val));
	         $val .= "-". $itemnum;
			 return $val;
        }
               
        private function addToCsv($filepointer, $subject, $site_key, $profile){
	    	fputcsv($filepointer, array(
		    	$this->createSubjectId($subject['search_item_num'], $subject['search_term']),
		    	$site_key,
		    	$profile
			));	        
        }       
               
	}

?>