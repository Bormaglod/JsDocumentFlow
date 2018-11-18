<?php
	session_start();
	
	require('connection.php');
	
	$stmt = $dbh->prepare('select * from get_command(:command)');
	$stmt->bindParam(':command', $_GET['id']);
	$stmt->execute();
	
	$result = $stmt->fetch(PDO::FETCH_ASSOC);
	$result['schema_data'] = json_decode($result['schema_data']);

	header('Content-Type: application/json');
	echo json_encode($result);
?>