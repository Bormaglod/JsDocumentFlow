<?php
	$guest = true;
  require("connection.php");

	$clients = array();
  foreach($dbh->query('select * from client where not administrator and parent_id is not null') as $row)
	{
		$clients[] = $row;
	}

	header('Content-Type: application/json');
	echo json_encode($clients);
?>