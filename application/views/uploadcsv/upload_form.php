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
			<div class="error">
			<?php echo $error;?>
			</div>
			
			<div id="spinner"></div>
			<?php echo form_open_multipart('uploadcsv/do_upload');?>
			
	       <div class="col-xs-12">
	            <h4>Subject CSV:</h4>
	            <div class="input-group">
	                <label class="input-group-btn">
	                    <span class="btn btn-primary">
	                        Browse&hellip; <input type="file" style="display: none;" name="subjectCSV">
	                    </span>
	                </label>
	                <input type="text" class="form-control" readonly>
	            </div>
	            <span class="help-block">
	                Please select a properly formatted Subjects.csv file.  
	            </span>
	        </div>	
        
	       <div class="col-xs-12">
	            <h4>Subject Site Identifier CSV:</h4>
	            <div class="input-group">
	                <label class="input-group-btn">
	                    <span class="btn btn-primary">
	                        Browse&hellip; <input type="file" style="display: none;" name="ssiCSV">
	                    </span>
	                </label>
	                <input type="text" class="form-control" readonly>
	            </div>
	            <span class="help-block">
	                Please select a properly formatted Subject_Site_Identifiers.csv file.  
	            </span>
	        </div>        		
			</form>
			<div class="col-xs-6 col-xs-offset-3">
				<input id="upload-csv-btn" type=button value="Scrape Profiles"/>
			</div>
			<div style="clear:both"></div>
		</div>	
	</section>
	<script type="text/javascript">		
		$(function(){
		  // We can attach the `fileselect` event to all file inputs on the page
		  $(document).on('change', ':file', function() {
		    var input = $(this),
		        numFiles = input.get(0).files ? input.get(0).files.length : 1,
		        label = input.val().replace(/\\/g, '/').replace(/.*\//, '');
		    input.trigger('fileselect', [numFiles, label]);
		  });
		
		  // We can watch for our custom `fileselect` event like this
		  
		  $(document).ready( function() {
		      $(':file').on('fileselect', function(event, numFiles, label) {
		
		          var input = $(this).parents('.input-group').find(':text'),
		              log = numFiles > 1 ? numFiles + ' files selected' : label;
		
		          if( input.length ) {
		              input.val(log);
		          } else {
		              if( log ) alert(log);
		          }
		
		      });
		  });
		  			
			
			
			
			
			
			
			
			$("#upload-csv-btn").click(function(){
				console.log("UPLOAD CSV FILES!!!");
				$("form").hide();	
				$(this).hide();	
				$(".error").hide();		
				showSpinner();
				$("form").submit();
			});

		});
		
		
		function showSpinner(){
			$("#spinner").html('<div class="col-sm-12 text-center"><p>This may take a few minutes...</p></div><div class="col-sm-12 text-center"><i class="fa fa-spinner fa-spin fa-5x spinner"></i></div>');
		}		
	</script>