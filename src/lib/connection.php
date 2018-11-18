<?php
	$user = 'guest';
	$password = 'guest';
	
	if (!isset($guest))
	{
		$user = $_SESSION['user_name'];
		$password = $_SESSION['user_password'];
	}
	else
		unset($guest);
	
	$dbh = new PDO('pgsql:host=localhost;port=5432;dbname=workflow_enterprise', $user, $password, array(PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION));
?>