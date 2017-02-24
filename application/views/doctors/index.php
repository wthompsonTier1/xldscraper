    <style>
	    .page-content{
		    padding-left: 25%; 
		    padding-right: 25%;
	    }
	</style>
    <header>
        <div class="container">
            <div class="row">
                <div class="col-lg-12">
	                <h2><?php echo $title ?></h2>
                </div>
            </div>
        </div>
    </header>                
	<section>
		<div class="page-content">
			<div>
				<div id="add-doctors" class="btn btn-primary btn-md">Add Doctors</div>
			</div>
			<table class="table table-responsive">
				<thead>
					<tr>
						<th>id</th>
						<th>subject_key</th>
						<th>subject_name</th>
					</tr>
				</thead>
				<tbody>	
		


<?php
		foreach ($doctors as $doc){
			echo "<tr>";
			echo "<td>".$doc['id']."</td>";
			echo "<td>".$doc['subject_key']."</td>";
			echo "<td>".$doc['subject_name']."</td>";
			echo "</tr>";
		}
	
	
?>
			</tbody>
		</table>
	</section>
	<script type="text/javascript">		
		$(function(){
			//alert("HERE");
			$("#add-doctors").click(function(){
				window.location = "<?php echo base_url(); ?>doctors/bulkadd";
			});
		});
	</script>