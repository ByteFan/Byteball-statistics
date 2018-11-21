<?php

//This script should be ran from a periodic cron job once a day.
//Fills the Mysql table daily_stat then dumps daily_stats.json

$time_in = time();
echo "\n<br>script lauched at " . date('Y-m-d H:i:s');

include_once '/var/www/where_are_your_mysql_credentials/.php';
$db = new SQLite3('/root/.config/byteball-hub/byteball.sqlite');



/*
 * create witnesses_tmp
 */

$query = "CREATE TEMPORARY TABLE witnesses_tmp";
$query .= " ( ";
$query .= " address VARCHAR(32) NOT NULL PRIMARY KEY )";

$results = $db->query( $query );

if (! $results) {
    echo "<p>There was an error in query: $query</p>";
    echo $db->lastErrorMsg();
    exit;
}


/*
 * fill witnesses_tmp
 */
 
$results = $db->query( "select address from unit_witnesses where 1 group by address" );

if (! $results) {
    echo "<p>There was an error in query: $query</p>";
    echo $db->lastErrorMsg();
    exit;
}

while ($row = $results->fetchArray(SQLITE3_ASSOC)) {

//     echo "\n<br>" . print_r($row, true);
    $db->query( "insert into witnesses_tmp (address) VALUES ('" . $row[ 'address' ] . "')" );

}

// die('ok');


/*
 * where are we ?
 */


// 

$q = mysqli_query($mysqli, "select max( main_chain_index ) as max_MCI from mci_timestamp where to_days( date ) = to_days( (select max( day ) from daily_stats) )" );

if ( ! $q ) {
     
    die("erreur : " .  mysqli_error( $mysqli ) );
    
}

$row = mysqli_fetch_assoc ( $q );

$max_MCI = $row[ 'max_MCI' ]; 




/*
 * create sqlite mci_timestamp_tmp
 */

$query = "CREATE TEMPORARY TABLE mci_timestamp_tmp";
$query .= " ( ";
$query .= " main_chain_index INT UNSIGNED NOT NULL PRIMARY KEY,";
$query .= " date TIMESTAMP NOT NULL )";

$results = $db->query( $query );

if (! $results) {
    echo "<p>There was an error in query: $query</p>";
    echo $db->lastErrorMsg();
    exit;
}


/*
 * fill sqlite mci_timestamp_tmp from mysql db
 */
 
$q = mysqli_query($mysqli, "select * from mci_timestamp where main_chain_index > '$max_MCI' order by main_chain_index" );

while( $row = mysqli_fetch_assoc ( $q ) ){

    $query =  "insert into mci_timestamp_tmp (main_chain_index, date) VALUES ('" . $row[ 'main_chain_index' ] . "', '" . $row[ 'date' ] . "' )";

    $results = $db->query( $query );
    
    if (! $results) {
        echo "<p>There was an error in query: $query</p>";
        echo $db->lastErrorMsg();
        exit;
    }

}
 

/*
 * counting query
 */
 
$query = "select count(distinct units.unit) as units_count";
$query .= ", count( distinct (CASE WHEN witnesses_tmp.address is NULL THEN units.unit ELSE NULL END) ) as units_nw_count";
$query .= ", count( distinct (CASE WHEN witnesses_tmp.address is NOT NULL THEN units.unit ELSE NULL END) ) as units_w_count";
$query .= ", SUM(CASE WHEN witnesses_tmp.address is NULL THEN units.payload_commission ELSE 0 END) as payload_nw";
$query .= ", SUM(CASE WHEN witnesses_tmp.address is NOT NULL THEN units.payload_commission ELSE 0 END) as payload_w";
$query .= ", SUM( units.payload_commission ) as payload_total";
$query .= ", count( distinct ( CASE WHEN units.is_on_main_chain = '0' THEN units.unit ELSE 0 END ) ) as sidechain_units";
$query .= ", count( distinct unit_authors.address ) as authors";
$query .= ", count( distinct unit_authors.definition_chash ) as new_authors";
$query .= ", date(mci_timestamp_tmp.date) as day";
$query .= " from units";
$query .= " left join unit_authors on unit_authors.unit = units.unit";// va compter plusieurs fois les units multisig ce qui va fausser le comptage des payload
$query .= " left join witnesses_tmp on witnesses_tmp.address = unit_authors.address";
$query .= " left join mci_timestamp_tmp on mci_timestamp_tmp.main_chain_index = units.main_chain_index";
$query .= " where 1";
$query .= " and units.main_chain_index > '$max_MCI'";
$query .= " and date(mci_timestamp_tmp.date) < date('now') ";
$query .= " group by date(mci_timestamp_tmp.date)";
$query .= " order by units.main_chain_index";
// $query .= " limit 0,100";

$results = $db->query( $query );

if (! $results) {
    echo "<p>There was an error in query: $query</p>";
    echo $db->lastErrorMsg();
    exit;
}

while ($row = $results->fetchArray(SQLITE3_ASSOC)) {

    echo "\n<br>" . print_r($row, true);
    
    $query = "insert into daily_stats set day='" . $row[ 'day' ] . "'";
    $query .= ", units_w = '" . $row[ 'units_w_count' ] . "'";
    $query .= ", units_nw = '" . $row[ 'units_nw_count' ] . "'";
    $query .= ", payload_nw = '" . $row[ 'payload_nw' ] . "'";
    $query .= ", payload_w = '" . $row[ 'payload_w' ] . "'";
    $query .= ", sidechain_units  = '" . $row[ 'sidechain_units' ] . "'";
    $query .= ", addresses = '" . $row[ 'authors' ] . "'";
    $query .= ", new_addresses = '" . $row[ 'new_authors' ] . "'";
    
    $q = mysqli_query($mysqli, $query );
    

}



/*
 * make json
 */
 
$res = array();
 
$q = mysqli_query($mysqli, "select (unix_timestamp(day)*1000 + 3600 * 25.9 * 1000 ) as t, units_w, units_nw, payload_nw, payload_w, round(sidechain_units/(units_w+units_nw)*100) as sidechain_units, addresses, new_addresses from daily_stats order by day" );

while( $row = mysqli_fetch_assoc ( $q ) ){

    $res[] = $row;

}

$json = json_encode( $res, JSON_NUMERIC_CHECK );

file_put_contents('/var/www/daily_stats.json', $json);
 


$total_time = time() - $time_in;
echo "\n<br><br>done in " . $total_time . " sec\n";

?>
