<?php
	class Help_model extends CI_Model {
		public function get_help_items(){
			$temp = array();
			$temp[] = array("Find Google Place ID", "/help_files/How-To-Find-Google-Place-Id.pdf");
			$temp[] = array("Find Facebook Page ID", "/help_files/How-To-Find-Facebook-Page-Id.pdf");
			$temp[] = array("Suggested Scrape Process", "/help_files/Suggested-Scrape-Process.pdf");
			
			return $temp;
		}
	}
?>