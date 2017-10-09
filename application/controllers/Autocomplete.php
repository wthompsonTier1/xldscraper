<?php

	class Autocomplete extends CI_Controller{
	    
	    function __construct() {
	        parent::__construct();
	    }
	    
	    public function GetClientName(){
	        $this->load->model('Clients_model');
	        $keyword=$this->input->get('term');
	        $data=$this->Clients_model->get_clients_like($keyword);        
	        echo json_encode($data);
	    }
	}

?>