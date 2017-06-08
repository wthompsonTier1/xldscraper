    <!-- Navigation -->
    <nav id="mainNav" class="navbar navbar-default navbar-fixed-top navbar-custom">
        <div class="container">
            <!-- Brand and toggle get grouped for better mobile display -->
            <div class="navbar-header page-scroll">
                <button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1">
                    <span class="sr-only">Toggle navigation</span> Menu <i class="fa fa-bars"></i>
                </button>
                <a class="navbar-brand" href="#page-top"><?php echo $sitetitle ?></a>
            </div>

            <!-- Collect the nav links, forms, and other content for toggling -->
            <div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
                <ul class="nav navbar-nav navbar-right">                      
                    <li class="page-scroll">
                        <a href="<?php echo base_url(); ?>home">Home</a>
                    </li>	                        
                    <li class="page-scroll">
                        <a href="<?php echo base_url(); ?>doctors/bulkadd">Search</a>
                    </li>
                    <li class="page-scroll">
                        <a href="<?php echo base_url(); ?>uploadcsv/index">Upload CSV Files</a>
                    </li>
                    <li class="dropdown">
						  <a data-toggle="dropdown">Help<span class="caret"></span></a>
						  <ul class="dropdown-menu">
							  <?php
								foreach($helpitems as $hi){
									echo "<li><a style='color:#18BC9C' href='".$hi[1]."'>".$hi[0]."</a></li>";
								}  
							  ?>
						  </ul>
                    </li>	                   
                </ul>
            </div>
            <!-- /.navbar-collapse -->
        </div>
        <!-- /.container-fluid -->
    </nav>