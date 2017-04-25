<?php
	class SearchSites_model extends CI_Model {
		public function __construct(){
			$this->load->database();
		}
		
		public function get_sites(){
			$query = $this->db->get("search_sites");
			return $query->result_array();
		}
		
		public function createCSV($working_dir){
			/*  Create the Sites.csv  */
			if(!file_exists($working_dir."/Sites.csv")){
				$fp = fopen($working_dir.'/Sites.csv', 'w');
				fputcsv($fp, array("site_key","site_title","search_url", "site_home"));
				
				foreach ($this->get_sites() as $site) {
				    fputcsv($fp, array($site['site_key'],$site['site_title'],$site['search_url'],$site['site_home']));
				}
				fclose($fp);
			}			
		}
	}
?>