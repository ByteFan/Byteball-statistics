<?php

include_once '/var/www/chart-functions.php';
include_once '/var/www/where_are_your_mysql_credentials/mysql.php';

?><!DOCTYPE html>
<html>
<head>
<title>Byteball HeartBeat</title>
<link rel="stylesheet" type="text/css" href="mystyle.css">
<meta name="Description" CONTENT="byteball hub and redistributive witness service">
<meta name="keywords" content="byteball, witness, hub, relay, statistics" />
<link rel="icon" href="./icon_16x16@2x.png">

	
<table>
<tr>
<td><a href="https://byteball.fr"><img src="icon-white-outline-1024.png" height="100" width="100"></a><img src="HeartBeat.png" height="100" width="100"></td>
<td><center><h1>Byteball HeartBeat</h1></center></td>
</tr>
</table>

<br><br>


<?php
$query = "SELECT * FROM bb_stats order by id DESC LIMIT 1";

	$q = mysqli_query($mysqli, $query);    
	  if ( ! $q ) {
     
        echo "Problem here..."; 
        exit;
        
    }



        if(mysqli_num_rows ( $q )==1){
							while( $row = mysqli_fetch_assoc ( $q ) ){


echo "
</center>
<table border=\"0\">
<tr>
<td></td>
<td><center><h2>Current 12 hours snapshot:</h2></center></td>
</tr>
</table>
		

<table border=\"0\">
	<tr>
		<td width=\"300\"><b>Total active Witnesses</b></td><td><a href=\"https://byteball.fr/stats.php\">".$row[ 'total_active_witnesses' ]."</a></td><td width=\"10\"></td><td></td>
	</tr>
	<tr>
		<td width=\"250\"><b>Total units posted</b></td><td>".$row[ 'total_units' ]."</td><td width=\"10\"></td><td></td>
	</tr>
	<tr>
		<td width=\"250\"><b>Total stables units</b></td><td>".$row[ 'total_stables_units' ]."</font></td><td></td><td></td>
	</tr>
	<tr>
		<td width=\"250\"><b>Total users units </b><font size=\"-2\">(Witnesses posts excluded)</font></td><td>".$row[ 'total_units_witnesses_excluded' ]."</td><td></td><td></td>
	</tr>
	<tr>
	<td width=\"250\"><b>Multisigned addresses units</font></b></td><td>".$row[ 'multisigned_units' ]."</td><td></td><td></td>
	</tr>
	<tr>
			<td width=\"250\"><b>Smart Contracts units</b></td><td>".$row[ 'smart_contract_units' ]."</td><td></td><td></td>
	</tr>
	<tr>
			<td width=\"250\"><b>Total users payload <font size=\"-2\">(in bytes)</font></b></td><td>".number_format ( $row[ 'total_payload' ] , 0 , "." , "," )."</td><td></td><td></td>
	</tr>
	
			<tr>
			<td width=\"250\"><b></b></td><td></td><td></td><td></td>
	</tr>
			<tr>
			<td width=\"250\"><b></b></td><td></td><td></td><td></td>
	</tr>
</table><br>
<i>Updated hourly. Last update: ".$row[ 'UTC_datetime' ]." UTC<br>
<br><br></i>
";
if(0){//deprecated
	echo "
			<tr>
			<td width=\"250\"><h2>Some All times data:</h2></td><td></td><td></td><td></td>
	</tr>
		<tr>
			<td width=\"250\"><b>All time Verified Users (KYC) <font size=\"-2\">(at jumio.com)</font></b></td><td>".$row[ 'registered_users' ]."</td><td></td><td></td>
	</tr>
			<tr>
			<td width=\"250\"><b>All time Non US Verified Users (KYC)</b></td><td>".$row[ 'non_US' ]."</td><td></td><td></td>
	</tr>
		</tr>
			<tr>
			<td width=\"250\"><b>All time Accredited investors <font size=\"-2\">(US compliant)</font></b></td><td>".$row[ 'accredited_investors' ]."</td><td></td><td></td>
	</tr>
</table><br>
<i>Updated hourly. Last update: ".$row[ 'UTC_datetime' ]." UTC<br>
<br><br></i>
";
}



							}
      }else{
      	echo "Not found.";
      }


?>




<table>
<tr>
<td></td>
<td><center><h2>Recent trend: 12 hours sliding window snapshots history</h2></center></td>
</tr>
</table>

<script src="https://byteball.fr/graph_framework/jquery-3.2.1.min.js"></script>
<script src="https://byteball.fr/graph_framework/code/highstock.js"></script>
<script src="https://byteball.fr/graph_framework/code/modules/exporting.js"></script>


<?php


$params = array(
    array(
        'name' => 'Total units',
        'json_id' => 'a',
    ),
    array(
        'name' => 'Total stable units',
        'json_id' => 'b',
    ),
    array(
        'name' => 'Sliding stability ratio',
        'json_id' => 'c',
    ),
    array(
        'name' => 'Excluding Witnesses units',
        'json_id' => 'd',
    ),
    array(
        'name' => 'Multisigned units',
        'json_id' => 'e',
    ),
    array(
        'name' => 'Smart contract units',
        'json_id' => 'f',
    ),
    array(
        'name' => 'Users payload',
        'json_id' => 'g',
    )
);

$args = array(
    'title' => 'Recent Byteball trend',
    'subtitle' => '12 hours sliding window snapshots - updated hourly',
    'container_id' => 'container_units_2',
    'params' => $params,
    'json' => 'bb_stats',
    'tooltip_pointFormat' => '<span style="color:{series.color}">{series.name}</span>: <b>{point.y}</b> ({point.change}%)<br/>',
    'tooltip_valueDecimals' => 0,
    'tooltip_split' => 'false',
    'plotOptions_compare' => 'percent',
);




show_chart( $args );

?>
<br>
<table>
<tr>
<td></td>
<td><center><h2>Historical data since January 2017:</h2></center></td>
</tr>
</table>

<?php

/*
 * units
 */
 
$params = array(
    array(
        'name' => 'Witnesses units',
        'json_id' => 'units_w',
    ),
    array(
        'name' => 'Users units',
        'json_id' => 'units_nw',
    ),
);

$args = array(
    'title' => 'Units',
    'subtitle' => 'Posted units - updated daily',
    'container_id' => 'container_units',
    'params' => $params,
    'json' => 'daily_stats',
    'tooltip_pointFormat' => '<span style="color:{series.color}">{series.name}</span>: <b>{point.y} units</b><br/>',
    'tooltip_valueDecimals' => 0,
    'tooltip_split' => 'true',
    'plotOptions_compare' => '',
);

show_chart( $args );


/*
 * payload
 */
 
$params = array(
    array(
        'name' => 'by others',
        'json_id' => 'payload_nw',
    ),
    array(
        'name' => 'by Witnesses',
        'json_id' => 'payload_w',
    ),
);

$args = array(
    'title' => 'Payload',
    'subtitle' => 'Posted load (in bytes) - updated daily',
    'container_id' => 'container_payload',
    'params' => $params,
    'json' => 'daily_stats',
    'tooltip_pointFormat' => '<span style="color:{series.color}">{series.name}</span>: <b>{point.y} bytes</b><br/>',
    'tooltip_valueDecimals' => 0,
    'tooltip_split' => 'true',
    'plotOptions_compare' => '',
);

show_chart( $args );


/*
 * sidechain
 */
 
$params = array(
    array(
        'name' => 'side chain units rate',
        'json_id' => 'sidechain_units',
    ),
);

$args = array(
    'title' => 'Side chain rate',
    'subtitle' => 'Percent of units out of the main chain - updated daily',
    'container_id' => 'container_sc_units',
    'params' => $params,
    'json' => 'daily_stats',
    'tooltip_pointFormat' => '<span style="color:{series.color}">{series.name}</span>: <b>{point.y}% of total units</b><br/>',
    'tooltip_valueDecimals' => 0,
    'tooltip_split' => 'false',
    'plotOptions_compare' => '',
);

show_chart( $args );



/*
 * addresses
 */
 
$params = array(
    array(
        'name' => 'Total addresses',
        'json_id' => 'addresses',
    ),
    array(
        'name' => 'New addresses',
        'json_id' => 'new_addresses',
    ),
);

$args = array(
    'title' => 'Addresses',
    'subtitle' => 'Unique addresses proportion (new addresses vs total addresses) - updated daily',
    'container_id' => 'container_address',
    'params' => $params,
    'json' => 'daily_stats',
    'tooltip_pointFormat' => '<span style="color:{series.color}">{series.name}</span>: <b>{point.y} addresses</b><br/>',
    'tooltip_valueDecimals' => 0,
    'tooltip_split' => 'false',
    'plotOptions_compare' => '',
);

show_chart( $args );

?>

<font size="-1">

<br><br>
<?php
	include '/var/www/html/footer.php';
?>

