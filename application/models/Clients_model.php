<?php
	class Clients_model extends CI_Model{
		public function __construct(){
			$this->load->database();
		}	
		
		public function get_clients_like($q){
	    	$this->db->select('name');
			$this->db->like('name', $q);
			$query = $this->db->get('clients');
			$returnArray = array();
			if($query->num_rows() > 0){
		      	foreach ($query->result_array() as $row){
			      	$returnArray[] = $row["name"];
				}
		    }
		  	return $returnArray;
	  	}
	}
?>