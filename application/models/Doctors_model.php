<?php
	class Doctors_model extends CI_Model {
		public function __construct(){
			$this->load->database();
		}
		
		public function get_doctors($doctor_id = false){
			if($doctor_id === false){
				$query = $this->db->get("subjects");
				return $query->result_array();
			}
			$query = $this->db->get_where("subjects",array("id" => $doctor_id));
			return $query->result_array();
		}
	}
?>