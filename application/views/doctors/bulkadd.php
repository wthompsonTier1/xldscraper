	<link rel="stylesheet" href="https://ajax.googleapis.com/ajax/libs/jqueryui/1.12.1/themes/smoothness/jquery-ui.css">
	<script src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.12.1/jquery-ui.min.js"></script>   
   
    <style>	    
	    #form-section textarea {
		    height: 200px;
	    }
	    .help-block {display: none}
	    
	    #results-section {
		    display:none;   
		}
	    
		#form-section { padding-top:20px}
		
	    .spinner {
		    color: rgb(24,188,156);
		    display: flex;
			justify-content: center;		    
	    }
	    
	    .doctor-container{
		    background-color: #DCDCDC;
		    margin-bottom: 10px;
		    margin-top: 10px;
		    padding: 20px;
	    }
	    
	    .site-row {
		    background-color: rgb(24,188,156);
		    padding:10px
	    }
	    
	    .no-profile-row,.profile-row{
		    margin-top: 4px;
		    padding-top: 4px;
		    padding-bottom: 4px;
	    }
	    .profile-row{
		    border-bottom: 1px dashed rgb(24,188,156);
	    }
	    
	    .hidden-data {display: none}
	    
	    
	    
	    #previous-scrapes{
			height: 300px;
			overflow: auto;    
		    
	    }
	    
	    .static-scrape-name{
			background-color:rgba(238, 10, 10, 0.5);
			margin-bottom: 4px;
			padding: 5px;
	    }
	    .edit-scrape-name{
		    display:none;
	    }
	    
	    .edit-scrape-name input{
		    width: 100%;
		    background-color:  gray;
		    padding:4px;
	    }
	    
	    .google-profile-link span {
		    color: #18BC9C;
		    font-size: 20px;
		    cursor: pointer;
	    }
	    #mapContainer{
		    width: 450px;
		    height: 450px;
	    }
	</style>
	<script>
		var _sites;
		var _data;
		var _searchDir;
		
		$(function(){
			/*  Get listing of previous searches/scrapes and list */
	
			
			/*  Previous Scrapes Feature:  in progress */
			//_getPreviousScrapes();
			//Autocomplete for client names
		    

			$("#btn-find-doctors").click(function(){
				_clearFormErrors();
				if(_validateForm()){
					_submitData();
				}
			});		
		});
		
		function _getPreviousScrapes(){
			$.ajax({
				type: "POST",
				url: "<?php base_url();?>ajax",
				dataType: 'json',
				data: { 
					mode:'get_previous_scrapes',
				},
				success: function(prev_scrapes) {
					var str = "";
					$.each(prev_scrapes, function(i, scrape){
						//console.log("Char At 0:  '"+scrape.charAt(0)+"'");
						if(scrape.charAt(0) != "."){
							str += "<div class='scrape-container'>";
							str += "<div class='static-scrape-name'>"+scrape+"</div>";
							str += "<div class='edit-scrape-name'><input name=newValue type=text/><input type=hidden name=previousValue value='"+scrape+"'/></div>";
							str += "</div>";
						}
					});
					$("#previous-scrapes").html(str);
					
					
					$(".edit-scrape-name input").blur(function(){
						var scrapeObj = $(this).parent().parent();
						var editObj = $(this).parent();
						var staticObj = $(".static-scrape-name",$(scrapeObj));
						
						var newval = $.trim($(this).val());
						var oldval = $("input[name='previousValue']",$(editObj)).val();
						
						if(newval == ""){
							newval == oldval;
						}
						
						$(editObj).hide();
						$(this).val("");
						$(staticObj).html(newval);
						$(staticObj).show();
						console.log("New:  "+newval);
						console.log("OLD:  "+oldval);
						
						
						if(newval != oldval){
							/* need to rename the directory  and refresh */
							$.ajax({
								type: "POST",
								url: "<?php base_url();?>ajax",
								data: { 
									mode:'rename_directory',
									oldval: oldval,
									newval: newval
								},
								success: function(returnVal) {
									if(returnVal == "FAIL"){
										alert("Directory Already Exists.")										
										$(staticObj).html(oldval);
									}else{
										$("input[name='previousValue']",editObj).val(newval);
									}
								}
							});
						}
						
					});
					
					$(".static-scrape-name").dblclick(function(){
						$(".edit-scrape-name input[name='newValue']",$(this).parent()).val($(this).text());
						$(this).hide();
						$(".edit-scrape-name",$(this).parent()).show();						
						$(".edit-scrape-name input",$(this).parent()).focus();
					});
				}
			});				
		}
		
		function showSpinner(){
			$("#results-content").html('<div class="col-sm-12 text-center"><p>This may take a few minutes...</p></div><div class="col-sm-12 text-center"><i class="fa fa-spinner fa-spin fa-5x spinner"></i></div>');
		}
		
		function getSiteInfo(searchData, key){
			//console.log("Site Key:  "+ key);
			var siteToReturn;
			$.each(searchData.sites, function(i,site){
				//console.log("SITE Obj:");
				//console.log(site)
				if(site.site_key == key){
					siteToReturn = site;
					return false;
				}
			});
			return siteToReturn;
		}
		
		
		function _processSearchResults(data){
			var output = "";
			var profile_count = 0;
			$.each( data.results, function( d, doctor ) {
				output += "<div class='container doctor-container'>";
					output += "<div class='hidden-data'>";
						output += "<div class='subject_item_num'>"+(d+1)+"</div>";
						output += "<div class='subject_search_term'>"+doctor.search_term+"</div>";
					output += "</div>";				
				
					
					/*  create row with #, doctor name, and search location  */
					output += "<div class='row name-location-row'>";
						output += "<div class='col col-sm-12'>";
							output += "<p>( " + (d+1) + " ) " + doctor.search_term + " &mdash; " + data.location + "</p>";
						output += "</div>";	
					output += "</div>";
					
					
					/*  create row with site name  (ratemds, vitals, healthgrades)  */
					$.each(doctor.site_results, function(sr,site_result){
						var siteinfo = getSiteInfo(data, site_result.site_key);
						
						output += "<div class='row site-row'>";
							output += "<div class='col col-sm-12'>";
								output += "<p>"+siteinfo.site_title+"</p>";
							output += "</div>";	
						output += "</div>";
						
						
						/*   Draw Profile Rows */
						if(site_result.data.length > 0){
							$.each(site_result.data, function(p,profile){
								profile_count++;
								output += "<div class='row profile-row'>";
									
									/* hidden div with profile data */
									output += "<div class='hidden-data'>";
										output += "<div class='search_item_num'>"+(d+1)+"</div>";
										output += "<div class='search_term'>"+doctor.search_term+"</div>";
										output += "<div class='site_key'>"+site_result.site_key+"</div>";
										output += "<div class='url'>"+profile.profileUrl+"</div>";
									output += "</div>";
									
									/*  Button Column  */
									output += "<div class='col col-sm-1'></div>";
									output += "<div class='col col-sm-1'>";
										output += "<button class='btn btn-primary btn-sm remove_btn'>Remove</button>";
									output += "</div>";	

									/*  Profile Data Column  */

									output += "<div class='col col-sm-9'>";
										output += "<p>"+profile.profileName+"</p>";
										
										/* NOTE:  linking to images doesnt seem to work */  
										//if(profile.profileImg != ""){
										//	output += "<img src='"+profile.profileImg+"'/>"
										//}
										output += "<p>"+profile.profileSpecialty+"</p>";
										
										if(site_result.site_key == "google"){
											output += "<p><div class='google-profile-link'><span>Profile Link</span><input type=hidden value='"+profile.profileUrl+"'/></div></p>";
										}else{
											output += "<p> <a href='"+siteinfo.site_home+profile.profileUrl+"' target='_blank'> Profile Link </a></p>";
										}		

									output += "</div>";	
									output += "<div class='col col-sm-1'></div>";

									
								output += "</div>";									
							});
						}else{
							output += "<div class='row no-profile-row'>";
								output += "<div class='col col-sm-1'></div>";
								output += "<div class='col col-sm-11'>";
									output += "<p>No Profiles were found.</p>";
								output += "</div>";	
							output += "</div>";						
						}
						
						
						
						
					})
					
					
					
					
					
					
					
					//$.each (doctor.site_results, function(s,site_result){
					//	output += "<div class='row'>";
					//	output += "<div class='col col-sm-2'>"
					//});
					
					
					
					
					
					
				output += "</div>";	
			});			

			return {
					output: output,
					profileCount: profile_count
				}
		}
		
		
		
		
		
		
		
		
		
		
		function getCSVButton(){
			return "<button class='btn btn-primary btn-md create-csv'>Scrape Profiles</button>";
		}
		
		
		function _clearFormErrors(){
			$(".form-group").removeClass("has-error");
			$(".form-group span").hide();			
		}
		
		function _clearForm(){
			$("#location-form-group input").val("");
			$("#doctors-form-group textarea").val("");
				
		}		
		
		function _formError(group){
			$("#"+group).addClass("has-error");
			$("#"+group+" span").show();
		}
		
		function _validateForm(){
			var formIsValid = true;
			if( $.trim($("#location-form-group input").val()) == ""){
				_formError("location-form-group");
				formIsValid = false;
			}
			if( $.trim($("#doctors-form-group textarea").val()) == ""){
				_formError("doctors-form-group");
				formIsValid = false;
			}			
			return formIsValid;
		}
		
		function initMap(){
			
		}
		
		function displayMap(data){
			/*
			console.log("PLACE DATA:");
			console.log(data);
			var mapProp= {
				center: data.result.geometry.location,
				zoom:5
			};
			mapDialog.dialog("open");
			var map=new google.maps.Map(document.getElementById("mapContainer"),mapProp);
			*/
			window.open(data.result.url, "_blank");			
		}
		
		
		function _submitData(){
			var location = $.trim($("#location-form-group input").val());
			var doctors = $.trim($("#doctors-form-group textarea").val());
			_clearForm();
			$("#form-section").hide();
			showSpinner();
			$("#results-section").show();			
			$.ajax({
				type: "POST",
				url: "<?php base_url();?>ajax",
				dataType: 'json',
				data: { 
					mode:'search_doctors',
					location: location,
					doctors: doctors
				},
				success: function(data) {
					console.log(data);
					_data = data;
					_sites = data.sites;
					_processedResults = _processSearchResults(data);
					_searchDir = data.searchDir;

					var output = "";
					output += "<div class='text-center'>"+getCSVButton()+"</div>";
					output += "<div class='container'>";
					output += "<div class='row'>";
					output += "<div class='col col-sm-3'><p>Total Profiles: <span class='total-profiles-found'></span></p></div>";
					output += "<div class='col col-sm-6'></div>";
					output += "<div class='col col-sm-3'><p>Total Profiles to CSV: <span class='total-to-csv'></span></p></div>";
					output += "</div>";
					
					
					/*  Add in client name field with autocomplete */
					output += "<div class='col-xs-12'>";
					output += "<h4>Choose a Client:</h4>";
					output += "<input type='input' id='clientname' name='clientname' class='form-control' placeholder='Choose a Client' />";
					output += "</div>";					
					
					output += "</div>";
					

										
					
					
					if(data['results'].length > 0){
						output += _processedResults.output;
					}else{
						output = "<h2>No Results Found</h2>";
					}
					
					output += "<div class='text-center'>"+getCSVButton()+"</div>";

					$("#results-content").html(output);
					
					/*  client name autocomplete  */
					$( "#clientname" ).autocomplete({
						source: "/Autocomplete/GetClientName"
					});	
					
					
					/*  Google Profile Links */
					
					$(".google-profile-link").click(function(){
						var linkdata = $("input",$(this)).val();
						var place_id = linkdata.substr(linkdata.indexOf("place_id=")+9);
						console.log(linkdata);
						console.log(place_id);
						$.ajax({
							type: "POST",
							url: "<?php base_url();?>ajax",
							dataType: 'json',
							data: { 
								mode:'get-google-place',
								place_id:  place_id
							},
							success: function(data){
								displayMap(data);
							}
						});
					});
					
					$(".total-profiles-found").html(_processedResults.profileCount);
					$(".total-to-csv").html(_processedResults.profileCount);
					
					/*  init buttons */
					$(".remove_btn").click(function(){
						$(".total-to-csv").html($(".total-to-csv").html() - 1);
						$(this).parent().parent().hide();
					});
					
					$(".create-csv").click(function(){
						
						var clientName = $("#clientname").val();
						var profile_data = [];
						
						$(".doctor-container").each(function(index, docObj){
							var subject = {};
							subject.search_item_num = $(".subject_item_num",docObj).text(); 
							subject.search_term = $(".subject_search_term",docObj).text(); 
							
							subject.healthgrades = [];
							subject.ratemds = [];
							subject.vitals = [];
							subject.yelp = [];
							subject.google = [];
							subject.facebook = [];
							
							
							/*  get healthgrade profiles */
							var nodes = $(".profile-row:visible .hidden-data .site_key:contains('healthgrades')",docObj).parent().parent();
							if(nodes.length > 0 ){
								nodes.each(function(index){
									subject.healthgrades.push($(".hidden-data .url", this).text());
								});
							}else{
								subject.healthgrades.push("");
							}		
							/*  get ratemds profiles */
							var nodes = $(".profile-row:visible .hidden-data .site_key:contains('ratemds')",docObj).parent().parent();
							if(nodes.length > 0 ){
								nodes.each(function(index){
									subject.ratemds.push($(".hidden-data .url", this).text());
								});
							}else{
								subject.ratemds.push("");
							}
							/*  get vitals profiles */
							var nodes = $(".profile-row:visible .hidden-data .site_key:contains('vitals')",docObj).parent().parent();
							if(nodes.length > 0 ){
								nodes.each(function(index){
									subject.vitals.push($(".hidden-data .url", this).text());
								});
							}else{
								subject.vitals.push("");
							}
							/*  get yelp profiles */
							var nodes = $(".profile-row:visible .hidden-data .site_key:contains('yelp')",docObj).parent().parent();
							if(nodes.length > 0 ){
								nodes.each(function(index){
									subject.yelp.push($(".hidden-data .url", this).text());
								});
							}else{
								subject.yelp.push("");
							}
							/*  get google profiles */
							var nodes = $(".profile-row:visible .hidden-data .site_key:contains('google')",docObj).parent().parent();
							if(nodes.length > 0 ){
								nodes.each(function(index){
									subject.google.push($(".hidden-data .url", this).text());
								});
							}else{
								subject.google.push("");
							}
							/*  get facebook profiles */
							var nodes = $(".profile-row:visible .hidden-data .site_key:contains('facebook')",docObj).parent().parent();
							if(nodes.length > 0 ){
								nodes.each(function(index){
									subject.facebook.push($(".hidden-data .url", this).text());
								});
							}else{
								subject.facebook.push("");
							}																																			
							
							
							
							
												
							profile_data.push(subject);
						});
						

						/*
						var profileRows = $(".profile-row:visible");
						
						$.each(profileRows, function(i,row){
							var p = {
								search_item_num: $(".hidden-data .search_item_num",row).text(),
								site_key: $(".hidden-data .site_key",row).text(),
								search_term: $(".hidden-data .search_term",row).text(),
								url: $(".hidden-data .url",row).text()	
							}
							profile_data.push(p);
						});
						
						*/
						
						
						showSpinner();	
						
						$.ajax({
							type: "POST",
							url: "<?php base_url();?>ajax",
							dataType: 'json',
							data: { 
								mode:'create-csv-files',
								sites: _sites,
								profiles: profile_data,
								searchDir: _searchDir,
								clientname: clientName
							},
							success: function(obj) {
								console.log(obj);
								var output = "<div class='container'>";
								output += "<div class='row'>";
								output += "<div class='col col-sm-12'>";
								output += "<p>"+obj.output_files_title+"</p>";
								output += "<ul>"
								$.each(obj.output_files, function(i,file){
									output += "<li><a href='"+file.file_location+"' target='csvFile'>"+file.title+"</a></li>"
								});
								output += "</ul></div></div></div>";
								
								output += "<div class='container'>";
								output += "<div class='row'>";
								output += "<div class='col col-sm-12'>";
								output += "<p>"+obj.source_files_title+"</p>";
								output += "<ul>"
								$.each(obj.source_files, function(i,file){
									output += "<li><a href='"+file.file_location+"' target='csvFile'>"+file.title+"</a></li>"
								});
								output += "</ul></div></div></div>";
								
								output += "<div class='container'>";
								output += "<div class='row'>";
								output += "<div class='col col-sm-12'>";
								output += "<p>"+obj.debug_files_title+"</p>";
								output += "<ul>"
								$.each(obj.debug_files, function(i,file){
									output += "<li><a href='"+file.file_location+"' target='csvFile'>"+file.title+"</a></li>"
								});
								output += "</ul></div></div></div>";
								
																
								$("#results-content").html(output);
														
							}
						});	
					});
				}
			});			
		}
		
	</script>
    <header>
        <div class="container" style="padding-top: 120px; padding-bottom: 10px">
            <div class="row">
                <div class="col-xs-12">
	                <h2><?php echo $title ?></h2>
                </div>
            </div>
        </div>
    </header> 
	<section id="form-section">
		<div class="container">
			<div class="row">
				<!--  Previous Scrapes Feature -->
				<!--
			    <div id="previous-scrapes" class="col-xs-7">
				    
			    </div> 				
				-->
				<div class="col-xs-3"></div>
				<div class="col-xs-6">
					<?php echo form_open(); ?>
						<div id="location-form-group" class="form-group">
						    <label for="location">Location</label>
						    <input type="input" name="location" class="form-control" placeholder="City/State" />
						    <span class="help-block">Must provide a location.</span>
						</div>
					
						<div id="doctors-form-group" class="form-group">
						    <label for="doctors">Doctors</label>
						    <textarea name="doctors" class="form-control" placeholder="list of doctors"></textarea>
						    <span class="help-block">Must provide a list of doctors.</span>
						</div>
					<?php echo form_close(); ?>
					<button id="btn-find-doctors" class="btn btn-primary btn-md">Find Doctors</button>
				</div>
			</div>
		</div>
	</section>
		
	<section id="results-section">
		<div class="container">
			<div class="row">
					<div id="results-content" class="col-xs-12"></div>	
			</div>	
		</div>			
	</section>
	
		
	
	