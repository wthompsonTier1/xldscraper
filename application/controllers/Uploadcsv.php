<?php
	class Uploadcsv extends CI_Controller{
		private $data = array();
	
        public function __construct()
        {
                parent::__construct();
                $this->load->model('Searchsites_model');
                $this->load->model('ScrapeResults_model');
                $this->load->helper(array('url','form'));
				$this->output->delete_cache();
				$this->data['sitetitle'] = "XLD Data Mining";
				$this->data['title'] = "Upload CSV and Run Scraper";
				$this->data['error'] = " ";		
				//error_log("DATA:::>>>");
				//error_log(json_encode($this->data));	
        }

        public function index()
        {
	       	if ( ! file_exists(APPPATH.'views/uploadcsv/upload_form.php'))
	        {
	                // Whoops, we don't have a page for that!
	                show_404();
	        }

			$this->data['error'] = " ";
            $this->load->view("templates/header", $this->data);
            $this->load->view("templates/navigation", $this->data);
			$this->load->view('uploadcsv/upload_form', $this->data);     
            $this->load->view("templates/footer", $this->data);
            
        }
        
        
        public function do_upload()
        {
	        	/* create working directory */
	        	$search_dir = "search_".date("Ymd-Gis");
	        	$working_dir = "./r_working_dir/".$search_dir;
	        	if(mkdir($working_dir)){
	                $config['upload_path']          = $working_dir;
	                $config['allowed_types']        = 'csv';
	                $config['max_size']             = 100;
	                $config['max_width']            = 1024;
	                $config['max_height']           = 768;
	
	                $this->load->library('upload', $config);
	                
	                $subjectUpload = true;
	                $subjectSiteIdentUpload = true;
					$this->data['error'] = "";

					$config['file_name'] = "Subjects.csv";
					$this->upload->initialize($config);
	                if ( ! $this->upload->do_upload('subjectCSV'))
	                {
		                	$subjectUpload = false;
		                	$this->data['error'] .= "You failed to upload the Subjects.csv file.<br>";
	                }
	                
	                $config['file_name'] = "Subject_Site_Identifiers.csv";
	         		$this->upload->initialize($config);
	                if ( ! $this->upload->do_upload('ssiCSV'))
	                {
		                	$subjectSiteIdentUpload = false;
		                	$this->data['error'] .= "You failed to upload the Subject_Site_Identifiers.csv file.<br>";
	                }                
	                
	                
	                
	                
	                if($subjectUpload && $subjectSiteIdentUpload){
		                /*  The files uploaded, so now add the Sites.csv file to the 
			                working directory 
			            
			            */
						$this->Searchsites_model->createCSV($working_dir);			            

		                /*   Kick off data scrape application  */				  	
						$scrapeFileReturn = exec("Rscript r_applications/scrape_connectmd.r ".$search_dir, $output);
						$this->data['results'] = json_encode($this->ScrapeResults_model->get_results($working_dir, $scrapeFileReturn));
						$this->load->view("templates/header",$this->data);
			            $this->load->view("templates/navigation",$this->data);
			            $this->load->view("uploadcsv/upload_form_success",$this->data);
			            $this->load->view("templates/footer",$this->data);
	                }
	                else
	                {
			            $this->load->view("templates/header",$this->data);
			            $this->load->view("templates/navigation",$this->data);
			            $this->load->view("uploadcsv/upload_form",$this->data);
			            $this->load->view("templates/footer",$this->data);
	                }
            	}else{
	            	/* need to add some sort of error response */  
	            	
            	}
        }        
               
	}

?>