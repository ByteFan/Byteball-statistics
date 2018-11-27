#!/usr/bin/perl
  use strict;
	use warnings;
	use DateTime;
	use Date::Parse;
	use JSON;
	use Data::Dumper;
	
	binmode STDOUT, ":utf8";
	use utf8;
 
 #this script is to be triggered each hour from cron
	
	use DBI;
	my $dbh;
	my $sth;
	my $sth2;
	my $sth3;
	
	my $Mysql_dbh=connect_Mysql_base();
	my $Mysql_sth;
	my $Mysql_rv;
	
	my $dbfile="/root/.config/byteball-hub/byteball.sqlite";
	
	$dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","") or die $DBI::errstr;
	my $total_value=0;
	my $others_value=0;
	my $diversity_index=0;
	
	my @defaul_witnesses=("BVVJ2K7ENPZZ3VYZFWQWK7ISPCATFIW3",
"DJMMI5JYA5BWQYSXDPRZJVLW3UGL3GJS",
"FOPUBEUPBC6YLIQDLKL6EW775BMV7YOH",
"GFK3RDAPQLLNCMQEVGGD2KCPZTLSG3HN",
"H5EZTQE7ABFH27AUDTQFMZIALANK6RBG",
"I2ADHGP4HL6J37NQAD73J7E5SKFIXJOT",
"JPQKPRI5FMTQRJF4ZZMYZYDQVRD55OTC",
"OYW2XTDKSNKGSEZ27LMGNOPJSYIXHBHC",
"S7N5FE42F6ONPNDQLCF64E2MGFYKQR2I",
"UENJPVZ7HVHM6QGVGT6MWOJGGRTUTJXQ",
"JEDZYC2HMGDBIDQKG3XSTXUSHMCBK725",
"TKT4UESIKTTRALRRLWS4SENSTJX6ODCW");
	
	my $HTML;
	my $witnesses_stats=undef;
	my $stats_range=1000;
	
	#get latest mci
	$sth = $dbh->prepare("SELECT max(main_chain_index) AS max_index FROM units");
	$sth->execute();
	my $query_result = $sth->fetchrow_hashref;
	my $last_mci=$query_result->{max_index};

	my $start_mci=$last_mci-$stats_range;

	#who are all actives witnesses?
	my @array_of_serial_posting_witnesses;
	my $our_witness_count=0;
	$sth = $dbh->prepare("select address, count(*) as total_count from witnessing_outputs where main_chain_index > $start_mci and main_chain_index <=$last_mci group by address order by total_count DESC");
	  $sth->execute();
	  while ($query_result = $sth->fetchrow_hashref){
	  	push @array_of_serial_posting_witnesses, $query_result->{address};
	  	$witnesses_stats->{$query_result->{address}}->{text}="Unknown: contact us to be listed here";
	  	$witnesses_stats->{$query_result->{address}}->{status}="Unknown";
	  	$witnesses_stats->{$query_result->{address}}->{arrow}="";
	  }

#witnesses "market share"
my @array_of_witnesses;
my $witnesses_market;
$sth = $dbh->prepare("select count(distinct units.unit) as total_seen, unit_witnesses_1.address, max(units.main_chain_index) as max_mci, max(units.creation_date) as max_creation_date, min(units.creation_date) as min_creation_date from units left join unit_witnesses as unit_witnesses_1 on ( unit_witnesses_1.unit = units.witness_list_unit or unit_witnesses_1.unit = units.unit ) left join unit_authors on unit_authors.unit = units.unit left join unit_witnesses as unit_witnesses_2 on unit_witnesses_2.address = unit_authors.address where 1 and units.sequence='good' and (julianday('now') - julianday(units.creation_date))* 24 * 60 * 60  < 3600*12 and unit_witnesses_2.address is NULL group by unit_witnesses_1.address order by total_seen desc");

	  $sth->execute();
	  while ($query_result = $sth->fetchrow_hashref){
	  	push @array_of_witnesses, $query_result->{address};

	  	$witnesses_market->{$query_result->{address}}->{total_seen}=$query_result->{total_seen};
	  	$witnesses_market->{$query_result->{address}}->{last_mci}=$query_result->{max_mci};
	  	$witnesses_market->{$query_result->{address}}->{last_seen}=$query_result->{max_creation_date};

	  }

#fill also @array_of_witnesses with posting (but non used by any en user) witness
foreach (@array_of_serial_posting_witnesses){
	my $buff=$_;
	my $is_found=0;
		foreach (@array_of_witnesses){
			$is_found=1 if($buff eq $_);
		}
	push @array_of_witnesses,$_ if (!$is_found);
}

my $buff_html_array="";
my $i=1;
my $max_end_users_seen_units=0;
	foreach (@array_of_witnesses)#last timestamp
	{
#how many time have we seen this witness except on its own posted units?
		$witnesses_stats->{$_}->{validations_count}=0;
	  $witnesses_stats->{$_}->{validations_count}=$witnesses_market->{$_}->{total_seen} if (defined $witnesses_market->{$_}->{total_seen});  
	 	$max_end_users_seen_units=$witnesses_market->{$_}->{total_seen} if (defined $witnesses_market->{$_}->{total_seen} && $witnesses_market->{$_}->{total_seen}>$max_end_users_seen_units);
	 	$witnesses_stats->{$_}->{last_seen_mci_timestamp}="<center>> 12h</center>";
	  $witnesses_stats->{$_}->{last_seen_mci_timestamp}=$witnesses_market->{$_}->{last_seen} if ($witnesses_market->{$_}->{last_seen});
	  $witnesses_stats->{$_}->{last_seen_mci}="<center>> 12h</center>";
	  $witnesses_stats->{$_}->{last_seen_mci}=$witnesses_market->{$_}->{last_mci} if(defined $witnesses_market->{$_}->{last_mci});
	  
	  $total_value+=$witnesses_stats->{$_}->{validations_count};
	  
	  if($_ eq 'MEJGDND55XNON7UU3ZKERJIZMMXJTVCV'){
	  	$witnesses_stats->{$_}->{text}="byteball-cashback-witness.com";
	  	$witnesses_stats->{$_}->{status}="Independant Witness";
	  	$others_value+=$witnesses_stats->{$_}->{validations_count};
	  }
	  if($_ eq '4GDZSXHEFVFMHCUCSHZVXBVF5T2LJHMU'){
	  	$witnesses_stats->{$_}->{text}="Rogier Eijkelhof";
	  	$witnesses_stats->{$_}->{status}="Independant Witness";
	  	$others_value+=$witnesses_stats->{$_}->{validations_count};
	  }
	  if($_ eq '7ULGTPFB72TOYA67YNGMX2Y445FSTL7O'){
	  	$witnesses_stats->{$_}->{text}="Portabella (slack user)";
	  	$witnesses_stats->{$_}->{status}="Independant Witness";
	  	$others_value+=$witnesses_stats->{$_}->{validations_count};
	  }
	  if($_ eq 'Z65GI4TTOZ6KOXDX7LQN4AVOFI6DLSJG'){
	  	$witnesses_stats->{$_}->{text}="rubbish0815 (slack user)";
	  	$witnesses_stats->{$_}->{status}="Independant Witness";
	  	$others_value+=$witnesses_stats->{$_}->{validations_count};
	  }
	  if($_ eq 'D3FLI2E6SQS437P57DKBYIBL3EZTZXCQ'){
	  	$witnesses_stats->{$_}->{text}="Piiper (slack user)";
	  	$witnesses_stats->{$_}->{status}="Independant Witness";
	  	$others_value+=$witnesses_stats->{$_}->{validations_count};
	  }
	  my $buff=$_;
	  $witnesses_stats->{$_}->{text}="Tonych" if grep( /^$buff$/, @defaul_witnesses );
	  $witnesses_stats->{$_}->{status}="Founder's Witness" if grep( /^$buff$/, @defaul_witnesses );
	  
	  $stats_range=$max_end_users_seen_units;
	  my $percentage=calculate_percent($witnesses_stats->{$_}->{validations_count});
	  $buff_html_array.="<tr><td><font color=\"green\" valign=\"top\">".$witnesses_stats->{$_}->{arrow}."</font></td><td><b>#".$i."</b></td><td><a href=\"http://explorer.byteball.org/#".$_."\" target=\"_blank\">".$_."</a></td><td><center>".$witnesses_stats->{$_}->{validations_count}."</center></td><td>".$percentage."</td><td><center>".$witnesses_stats->{$_}->{last_seen_mci}."<center></td><td>".$witnesses_stats->{$_}->{last_seen_mci_timestamp}."</td><td>".$witnesses_stats->{$_}->{status}."</td><td>".$witnesses_stats->{$_}->{text}."</td></tr>\n";
	
	  if(0){
	  print "$_ nbre validation : $witnesses_stats->{$_}->{validations_count}\n";
	  print "last seen mci timestamp $witnesses_stats->{$_}->{last_seen_mci_timestamp}\n";
	  print "last seen mci: $witnesses_stats->{$_}->{last_seen_mci}\n";
	 }
	  $i++;
	  #insert if needed in table seen_witnesses
	  $Mysql_sth=$Mysql_dbh->prepare("SELECT count(*) as total_count FROM seen_witnesses where address='$_'");
		$Mysql_sth->execute();
	  my $query_result2 = $Mysql_sth->fetchrow_hashref;
	  if($query_result2->{total_count}==0){
	  		$Mysql_sth=$Mysql_dbh->prepare("INSERT INTO seen_witnesses (address, first_seen) values('$_',now())");
				$Mysql_sth->execute();
	  }
	 
	}#end of foreach arrayofwitnesses
	

	

	$buff_html_array.="";


my $update=DateTime->now();
my $total_active_witnesses=$i-1;

$HTML->{Array}=$buff_html_array;
$HTML->{update}=$update;
$HTML->{total_active}=$total_active_witnesses;
#open the stat template and output the stats.php public php script
		my $template='/var/www/html/templates/witnesses_template.html';
		my $new_stats=get_content($template,$HTML);
		my $filename = '/var/www/html/stats.php';
		open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
		print $fh $new_stats;
		close $fh;


#pass 2: top 100
	
	#save the richests in table buff_richests_list
		$Mysql_sth=$Mysql_dbh->prepare ("TRUNCATE buff_richests_list");
		$Mysql_rv = $Mysql_sth->execute;
		
		$sth = $dbh->prepare("SELECT sum(amount) as amount,address FROM 'outputs' where is_spent='0' and asset is null group by address order by amount desc");
		$sth->execute();
		my $total_add_with_balance=0;
		while ($query_result = $sth->fetchrow_hashref){
			#problematics addresses
			next if $query_result->{address} eq 'mtdc7zuhmdu3ph2rrmhcmm4plc2xkhtj';#yes, lowercase
			next if $query_result->{address} eq 'GVVHBOGQFAZJW54m37LPSHZOYWZ2Z47T';
			next if $query_result->{address} eq 'ZQ4NJ2YZGUGIPU2F2DOAIIH67MBY4AHG';
				$total_add_with_balance++;
				$Mysql_sth=$Mysql_dbh->prepare ("INSERT INTO buff_richests_list (amount,address) values('$query_result->{amount}','$query_result->{address}')");
				$Mysql_rv = $Mysql_sth->execute;
		}
	
		$Mysql_sth=$Mysql_dbh->prepare ("RENAME TABLE richests_list TO tmp_richests_list");
		$Mysql_rv = $Mysql_sth->execute;
		$Mysql_sth=$Mysql_dbh->prepare ("RENAME TABLE buff_richests_list TO richests_list");
		$Mysql_rv = $Mysql_sth->execute;		
		$Mysql_sth=$Mysql_dbh->prepare ("RENAME TABLE tmp_richests_list TO buff_richests_list");
		$Mysql_rv = $Mysql_sth->execute;		
		$Mysql_sth=$Mysql_dbh->prepare ("TRUNCATE buff_richests_list");
		$Mysql_rv = $Mysql_sth->execute;


		
#pass 3: trafic
#All trafic within the last 12 hours

	$sth = $dbh->prepare("select count(*) as total from units where (julianday('now') - julianday(creation_date))* 24 * 60 * 60  < 3600*12");
	$sth->execute();
	$query_result = $sth->fetchrow_hashref;
	my $total_units=$query_result->{total};
	
	#all stables units
	$sth = $dbh->prepare("select count(*) as total from units where (julianday('now') - julianday(creation_date))* 24 * 60 * 60  < 3600*12 AND is_stable='1'");
	$sth->execute();
	$query_result = $sth->fetchrow_hashref;
	my $total_stables_units=$query_result->{total};
	
	my $percent=5;#little alarm system to Tonych
	if($total_stables_units < $total_units*(1-$percent/100)){
		my $alerte_subject  = "Alert! Too many non stable units in the Byteball network!";
		my $body="My current alert trigger is non stable vs total units less than ".$percent." %.\n\nHowever, over the last 12 hours I see:\nTotal units posted: ".$total_units."\nTotal stables units: ".$total_stables_units."\n";
		send_email ('noreply@byteball.fr','byteball@byteball.org',$body, $alerte_subject);
		
	}
	
	#all units out of main chain
	$sth = $dbh->prepare("select count(*) as total from units where (julianday('now') - julianday(creation_date))* 24 * 60 * 60  < 3600*12 AND is_stable='1' AND is_on_main_chain='0'");
	$sth->execute();
	$query_result = $sth->fetchrow_hashref;
	my $total_stables_units_sidechain=$query_result->{total};
	
	#all units but witnesses units
	$sth = $dbh->prepare("select units.* from units left join unit_authors on unit_authors.unit = units.unit left join unit_witnesses on unit_witnesses.address = unit_authors.address where ( julianday('now') - julianday(units.creation_date) )* 24 * 60 * 60  < 3600*12 and unit_witnesses.address is NULL group by units.unit");
	$sth->execute();
	$query_result = $sth->fetchrow_hashref;
	my $total_sidechain_units_witnesses_excluded=0;
	my $total_units_witnesses_excluded=0;
	my $total_payload=0;
	my $single_sig_count=0;
	my $multisig_count=0;
	my $smart_contract_count=0;

	my $latest_definition_cash="";

	while ($query_result = $sth->fetchrow_hashref){
		$total_payload+=$query_result->{payload_commission};
		$total_units_witnesses_excluded++;
		$total_sidechain_units_witnesses_excluded+=1 if($query_result->{is_on_main_chain}==0);

		#smart addresses
		$sth2=$dbh->prepare("SELECT * FROM unit_authors where unit='$query_result->{unit}'");
		$sth2->execute();
		while (my $query_result2 = $sth2->fetchrow_hashref){
		
		$sth3=$dbh->prepare("SELECT definition_chash FROM address_definition_changes CROSS JOIN units USING(unit) WHERE address='$query_result2->{address}' AND is_stable=1 AND sequence='good' ORDER BY level DESC LIMIT 1");
		$sth3->execute();
		my $query_result3=$sth3->fetchrow_hashref;
		my $rv3=$sth3->rows;
			if ($rv3 == 0){
				$latest_definition_cash=$query_result2->{address};# definition_cash is the address itself
			} else{
				$latest_definition_cash=$query_result3->{definition_chash};
			}
		my $sth4=$dbh->prepare("SELECT definition FROM definitions where definition_chash='$latest_definition_cash'");
		$sth4->execute();
		my $query_result4=$sth4->fetchrow_hashref;
		my $buff=$query_result4->{definition};
		my @eclated_result=split/\,/,$buff;
		if($eclated_result[0] =~ /^\[\"sig\"$/) {
			$single_sig_count++;
	 	}elsif($eclated_result[0] =~ /^\[\"r of set\"$/){
	 		$multisig_count++;
	 	}else{
	 		$smart_contract_count++;
	 	}
		}
	
	}
	
		my $ratio=sprintf("%.2f",($total_stables_units/$total_units)*100);
		my $total_payload_for_mysql=$total_payload;
		$total_payload=set_coma_separators($total_payload);

#how many hubs and wallets
		$Mysql_sth=$Mysql_dbh->prepare ("select count(*) as total_count from geomap where type='hub'");
		$Mysql_rv = $Mysql_sth->execute;
		$query_result = $Mysql_sth->fetchrow_hashref();
		my $total_hubs=$query_result->{total_count};
		
		$Mysql_sth=$Mysql_dbh->prepare ("select count(*) as total_count from geomap where type='full_wallet'");
		$Mysql_rv = $Mysql_sth->execute;
		$query_result = $Mysql_sth->fetchrow_hashref();
		my $total_full_wallets=$query_result->{total_count};


#registered profile (deprecated)
	$sth = $dbh->prepare("SELECT count(*) as registered_profiles 
 FROM attestations 
 left join messages on messages.unit=attestations.unit
 where 1
 and messages.app='attestation'
 and messages.payload like '%profile_hash%'");
	$sth->execute();
	$query_result = $sth->fetchrow_hashref;
	my $registered_profiles_count=$query_result->{registered_profiles};

#non US
		$sth = $dbh->prepare("SELECT count(*) as non_US 
 FROM attestations  
 left join messages on messages.unit=attestations.unit
 where 1
 and messages.app='attestation'
 and messages.payload like '%nonus%'");
	$sth->execute();
	$query_result = $sth->fetchrow_hashref;
	my $non_US_count=$query_result->{non_US};

#accredited investors
$sth = $dbh->prepare("SELECT count(*) as accredited
 FROM messages where app='attestation' and payload like '%accredited\":1%'");
	$sth->execute();
	$query_result = $sth->fetchrow_hashref;
	my $accredited=$query_result->{accredited};

#all that into bb_stats table...

		$Mysql_sth=$Mysql_dbh->prepare ("INSERT INTO bb_stats ( total_active_witnesses, multisigned_units, smart_contract_units, total_units, total_stables_units, total_units_witnesses_excluded, stable_ratio, total_payload, total_add_with_balance, UTC_datetime, total_stables_units_sidechain, total_sidechain_units_WE, total_full_wallets, total_hubs, registered_users, non_US, accredited_investors) values 
		('$total_active_witnesses','$multisig_count','$smart_contract_count','$total_units','$total_stables_units','$total_units_witnesses_excluded','$ratio','$total_payload_for_mysql','$total_add_with_balance',UTC_TIMESTAMP(),'$total_stables_units_sidechain','$total_sidechain_units_witnesses_excluded','$total_full_wallets','$total_hubs','$registered_profiles_count','$non_US_count','$accredited')");
		$Mysql_rv = $Mysql_sth->execute;

#json dump
dump_json("/var/www/xfiles/json/bb_stats.json","bb_stats","UTC_datetime","total_units","total_stables_units","stable_ratio",
"total_units_witnesses_excluded","multisigned_units","smart_contract_units","total_payload","registered_users", "non_US");
		

		$sth->finish() if defined $sth;
		$sth2->finish() if defined $sth2;
		$sth3->finish() if defined $sth;
		$dbh->disconnect;
		
		$Mysql_sth->finish();
		$Mysql_dbh->disconnect;

		
sub dump_json{

	my @fields=@_;
	my $filename=$fields[0];
	my $table=$fields[1];
		
	open(my $fh2, '>', $filename) or die "Could not open file '$filename' $!";
		my $buff="[\n";
		$Mysql_sth=$Mysql_dbh->prepare ("select * from $table ORDER BY id ASC");
		$Mysql_rv = $Mysql_sth->execute;
		my $row_numbers = $Mysql_sth->rows;
		my $i=1;
		while (my $query_result = $Mysql_sth->fetchrow_hashref){
			my $timestamp=convert_to_unix_timestamp($query_result->{$fields[2]});
			$timestamp=($timestamp+7200)*1000;
			if($i<$row_numbers){
				$buff.="{\"t\":".$timestamp.",\"a\":".$query_result->{$fields[3]}.",\"b\":".$query_result->{$fields[4]}.",\"c\":".$query_result->{$fields[5]}.",\"d\":".$query_result->{$fields[6]}.",\"e\":".$query_result->{$fields[7]}.",\"f\":".$query_result->{$fields[8]}.",\"g\":".$query_result->{$fields[9]}.",\"h\":".$query_result->{$fields[10]}.",\"i\":".$query_result->{$fields[11]}."},";	
			 }else{
				$buff.="{\"t\":".$timestamp.",\"a\":".$query_result->{$fields[3]}.",\"b\":".$query_result->{$fields[4]}.",\"c\":".$query_result->{$fields[5]}.",\"d\":".$query_result->{$fields[6]}.",\"e\":".$query_result->{$fields[7]}.",\"f\":".$query_result->{$fields[8]}.",\"g\":".$query_result->{$fields[9]}.",\"h\":".$query_result->{$fields[10]}.",\"i\":".$query_result->{$fields[11]}."}";	
				}		
			$i++;
		}
		$buff.="]";
	
	
		print $fh2 $buff;
		close $fh2;

}

sub convert_to_unix_timestamp {
	my $time=shift;
	return str2time($time);
}

sub Indols{
	my $amount=shift;
	my $rate=shift;
	return(set_coma_separators(sprintf "%.2f",($amount/1000000000)*$rate));
	
}

sub set_coma_separators {
	my $input_string=shift;
	$input_string =~ s/(\d)(?=(\d{3})+(\D|$))/$1\,/g;
	return($input_string);
}

sub get_content {
    
    my $content;
    
    my ($template,$HTML) = @_;
    open (FILE, "<$template") or die "Couldn't open $template: $!\n";
    while (<FILE>) {
		s/{{(.*?)}}/$HTML->{$1}/g;
		$content .= $_;
    	} 
    close FILE;
    
    return $content;
    
}

sub calculate_percent {
	my $value=shift;

	my $output=($value/$stats_range)*100;
	
	return sprintf("%.2f",$output);
	
}


sub connect_Mysql_base {
	my $local_dbh;
	my $host="localhost";
	my $database="byteball";
	my $USER="root";
	my $PASSWORD="your Mysql password";
	eval {$local_dbh = DBI->connect("DBI:mysql:database=$database;host=$host",
                            $USER, $PASSWORD, {RaiseError => 1})};
	if ($@) {
		exit;
	} else {return $local_dbh;}
}

sub send_email {
    my ($mailfrom, $mailto, $message, $subject) = @_;
    my $MAILLER = '/usr/sbin/sendmail -t -oi -oem';

	my $buff="";
	$buff.= "To: ";
	$buff.= "$mailto\n";
	$buff.= "From: ";
	$buff.= "$mailfrom\n";
	$buff.= "Subject: ";
	$buff.= "$subject\n\n";
	$buff.= "$message";

    open (MAIL, "|$MAILLER") or die "Can't open $MAILLER: $!\n";
    print MAIL $buff;
    close MAIL or return undef;

    return 1;
}
