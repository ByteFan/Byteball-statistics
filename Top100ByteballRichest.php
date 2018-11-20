<?php

include_once '/var/www/where_are_your_mysql_credentials/mysql.php';

?>
<!DOCTYPE html>
<html>
<head>
<title>Byteball Top 100 richest list</title>
<link rel="stylesheet" type="text/css" href="mystyle.css">
<meta name="Description" CONTENT="byteball hub and redistributive witness service">
<meta name="keywords" content="byteball, witness, hub, relay, statistics" />
<link rel="icon" href="./icon_16x16@2x.png">


<script src="https://byteball.fr/graph_framework/jquery-3.2.1.min.js" type="text/javascript"></script>
<script type="text/javascript">
    $(document).ready(function(){      
         function search(){
              var address=$("#search").val();
              if(address!=""){
                $("#result").html("<img src='ajax-loader.gif'/>");
                 $.ajax({
                    type:"post",
                    url:"findrichest.php",
                    data:"address="+address,
                    success:function(data){
                        $("#result").html(data);
                        $("#search").val("");
                     }
                  });
              }
         }

          $("#button").click(function(){
          	 search();
          });

          $('#search').keyup(function(e) {
             if(e.keyCode == 13) {
                search();
              }
          });
    });
</script>

</head>
<body>
	<table>
<tr>
<td><a href="https://byteball.fr"><img src="icon-white-outline-1024.png" height="100" width="100"></a></td>
<td><center><h1>Byteball Top 100 richest list</h1></center></td>
</tr>
</table>
<br><br>

        <div id="container" style="position: relative">
        		<font size="+1">Find yourself among the richests!</font>
             <input type="text" id="search" placeholder="Your Byteball address here."/>
             
             <table>
             	<tr>
             <td><input type="button" id="button" value="Search" /></td><td width="10"></td><td id="result" value=""></td>
             </tr>
             </table>

        </div>
<br>
<table border="0">
	<tr>

		<td width="50"><b>Rank</b></td>
		<td width="180"><b>Amount (in bytes)</b></td>



<?php
$rate_url="https://api.coinmarketcap.com/v1/ticker/byteball/";

$json_array= json_decode(make_443_get ($rate_url), true);
if(!defined($json_array['0']['price_usd'])){
$dollar_value=round($json_array['0']['price_usd'],2);
} else {
	$dollar_value="rate missing";
}

echo "
		<td width=\"180\"><b>USD <font size=\"-2\">(at 1GB=$".$dollar_value.")</font></b></td>
		<td width=\"200\"><b><center>Address</center></b></td>
	</tr>
";


$query = "SELECT * FROM richests_list order by amount DESC LIMIT 100";

	$q = mysqli_query($mysqli, $query);    
	  if ( ! $q ) {
     
        echo "Problem here..."; 
        exit;
        
    }
$i=1;
							while( $row = mysqli_fetch_assoc ( $q ) ){
								echo "<tr><td><b>#".$i."</b></td><td>".number_format ($row[ 'amount' ])."</td><td>$".number_format (($row[ 'amount' ]/1000000000)*$dollar_value)."</td><td><a href=\"https://explorer.byteball.org/#".$row[ 'address' ]."\">".$row[ 'address' ]."</a></td></tr><tr>";
							$i++;
							}

?>

</table>
<br>
<font size="-1">

#1 MZ4GUQC7WUKZKKLGAS3H3FSDKLHI7HFO holds the remaining disribution amount.<br>
Rate powered by <a href="https://coinmarketcap.com/currencies/byteball/" target="_blank">CoinMarketCap</a><br><br></i>


<?php
function make_443_get ($url) {
				$url=$url;
				$timeout = 10;// Le temps maximum d'exécution de la fonction cURL (en secondes)


				// create curl resource 
				$ch = curl_init(); 

				// curl_setopt
				curl_setopt($ch, CURLOPT_URL, $url); 
				curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1); 
				curl_setopt($ch, CURLOPT_PORT, 443);
				curl_setopt($ch, CURLOPT_TIMEOUT, $timeout); 
				curl_setopt($ch, CURLOPT_FAILONERROR,true);
				curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
				curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
				curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);

				if($output = curl_exec($ch)){ 

				return $output;

				} else {

				//echo 'errore here:' . curl_error($ch);

				$buff_code = array('error' => 1, 'error_code' => curl_getinfo($ch, CURLINFO_HTTP_CODE));
				curl_close($ch);
				return json_encode($buff_code); //426

				}

				// close curl resource to free up system resources 
				
	
	
}   
?>
