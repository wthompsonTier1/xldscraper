<?php
	class Doctors extends CI_Controller{
        public function __construct()
        {
                parent::__construct();
                $this->load->model('doctors_model');
                $this->load->helper('url');
				$this->output->delete_cache();
                
        }

        public function index()
        {
	       	if ( ! file_exists(APPPATH.'views/doctors/index.php'))
	        {
	                // Whoops, we don't have a page for that!
	                show_404();
	        }
	        $data['sitetitle'] = "XLD Data Mining";
            $data['doctors'] = $this->doctors_model->get_doctors();
            $data['title'] = "Doctors Index";
            $this->load->view("templates/header",$data);
            $this->load->view("templates/navigation",$data);
            $this->load->view("doctors/index",$data);
            $this->load->view("templates/footer",$data);
        }


		/*  NOT HOOKED UP YET! 
		
        public function view($slug = NULL)
        {
                $data['doctors_item'] = $this->doctors_model->get_doctors($slug);
        }
        
        */
        
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
		      case 'search_doctors':
		      		$searchDir = "search_".date("Ymd-His");
			  		$inputFile = "r_working_dir/".$searchDir."/search.txt";
		      		if(!file_exists(dirname($inputFile)))
			  			mkdir(dirname($inputFile), 0777, true);		      		
			  			
			  		$file = fopen($inputFile,"w");
			  		fwrite($file,$data['location']."\n");
			  		fwrite($file,implode("~",explode("\n",$data['doctors']))."\n");
			  		fclose($file);
			  		
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
		      		//$csvfiles[] = "temp1.csv";
		      		//$csvfiles[] = "temp2.csv";
		      		//$csvfiles[] = "temp3.csv";
		      		
		      		$obj = new stdClass;
		      		$obj->sites = $data['sites'];
		      		$obj->profiles = $data['profiles'];
		      		$obj->searchDir = $data['searchDir'];
		      		
		      		//Write profile information to file for future use
		      		$fp = fopen('r_working_dir/'.$obj->searchDir.'/profiles-to-scrape.txt', 'w');
		      		fwrite($fp, json_encode($obj));
		      		fclose($fp);

		      		
		      		
		      		
		      		
			  		/*  Create the Sites.csv  */
		      		/*  
			      		site_key	site_title	site_base_url
				  		vitals	Vitals.com	http://vitals.com/doctors/
				  	*/
				  	$fp = fopen('r_working_dir/'.$obj->searchDir.'/Sites.csv', 'w');
				  	fputcsv($fp, array("site_key","site_title","site_base_url"));
					foreach ($obj->sites as $site) {
					    fputcsv($fp, array($site['site_key'],$site['site_title'],$site['site_home']));
					}
					fclose($fp);
					$csvObj = new stdClass;
					$csvObj->title = "Site.csv";
					$csvObj->file_location = "/r_working_dir/".$obj->searchDir."/Sites.csv";
				  	$csvfiles[] = $csvObj;
				  	
				  	/* Create the Subject_Site_Identifiers.csv */
				  	$fp = fopen('r_working_dir/'.$obj->searchDir.'/Subject_Site_Identifiers.csv', 'w');
				  	fputcsv($fp, array("subject_key","site_key","site_subject_ident"));
					
					foreach ($obj->profiles as $profile) {
					    fputcsv($fp, array(
					    	$this->createSubjectId($profile['search_item_num'], $profile['search_term']),
					    	$profile['site_key'],
					    	$profile['url']
					    ));
					}
					fclose($fp);
					$csvObj = new stdClass;
					$csvObj->title = "Subject_Site_Identifiers.csv";
					$csvObj->file_location = "/r_working_dir/".$obj->searchDir."/Subject_Site_Identifiers.csv";
				  	$csvfiles[] = $csvObj;
				  	
				  	
				  	
				  	
				  	/*
				  	subject_key	site_key	site_subject_ident
				  	daniel-g-fagel	ratemds	2259255/Dr-DANIEL+G.-FAGEL-Crestview+Hills-KY.html
				  	daniel-g-fagel	healthgrades	dr-daniel-fagel-3fxtn
				  	daniel-g-fagel	vitals	Dr_Daniel_Fagel.html
				  	*/
				  	
				  	/*  Create the Subjects.csv */
				  	/*
				  	subject_key	subject_name
				  	daniel-g-fagel	Daniel G. Fagel M.D.
				  	
				  	
				  				site_key: $(".hidden-data .site_key",row).text(),
								search_term: $(".hidden-data .search_term",row).text(),
								url: $(".hidden-data .url",row).text()
				  	
				  	*/
				  	$subjectIdList = array();
				  	$fp = fopen('r_working_dir/'.$obj->searchDir.'/Subjects.csv', 'w');
				  	fputcsv($fp, array("subject_key","subject_name"));
					
					foreach ($obj->profiles as $profile) {
						$subjectId = $this->createSubjectId($profile['search_item_num'],$profile['search_term']);
						if(!in_array($subjectId, $subjectIdList)){
							$subjectIdList[] = $subjectId;
							fputcsv($fp, array($subjectId,$profile['search_term']));
						}
					}
					fclose($fp);
					$csvObj = new stdClass;
					$csvObj->title = "Subjects.csv";
					$csvObj->file_location = "/r_working_dir/".$obj->searchDir."/Subjects.csv";
				  	$csvfiles[] = $csvObj;		
				  	
				  	
				  	
				  	/*   Kick off data scrape application  */				  	
				  	$scrapeFileReturn = exec("Rscript r_applications/scrape_connectmd.r ".$obj->searchDir, $output);
				  	$scrapeFileReturn = str_replace('"','',str_replace('[1] "', '', $scrapeFileReturn));
				  	list($scrapeFile, $reviewFile) = explode("~",$scrapeFileReturn);
				 
					$csvObj = new stdClass;
					$csvObj->title = "scrape_debug.txt";
					$csvObj->file_location = "/r_working_dir/".$obj->searchDir."/scrape_debug.txt";
				  	$csvfiles[] = $csvObj;					 
				 
				 
					$csvObj = new stdClass;
					$csvObj->title = $scrapeFile;
					$csvObj->file_location = "/r_working_dir/".$obj->searchDir."/".$scrapeFile;
				  	$csvfiles[] = $csvObj;	

					$csvObj = new stdClass;
					$csvObj->title = $reviewFile;
					$csvObj->file_location = "/r_working_dir/".$obj->searchDir."/".$reviewFile;
				  	$csvfiles[] = $csvObj;


		      		echo json_encode($csvfiles);
		      	break;
		      	
		      	
	        }
	        //echo json_encode($data);
        }
        
        private function createSubjectId($itemnum, $val){
	        /*  replace anything that is not a-z with a "-" */
	         $val = strtolower(preg_replace("/[^a-zA-Z]/", "-", $val));
	         $val .= "-". $itemnum;
			 return $val;
        }
               
	}

?>