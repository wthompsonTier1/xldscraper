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
<?php
	
	$output = "<div class='container'>";
	$output .= "<div class='row'>";
	$output .= "<div class='col col-sm-12'>";
	$output .= "<p>CSV Files:</p>";
	$output .= "<ul>";
	foreach($results as $file){
		$output .= "<li><a href='".$file->file_location."' target='csvFile'>".$file->title."</a></li>";
	}
	$output .= "</ul></div></div></div>";
	echo $output;
?>		
		</div>	
	</section>
	<script type="text/javascript">		
		$(function(){

		});
	</script>