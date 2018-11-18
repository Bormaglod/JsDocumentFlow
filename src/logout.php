<?php
	session_start();
	
	require("lib/connection.php");
	$stmt = $dbh->prepare('select logout();');
	$stmt->execute();
	
	unset($_SESSION['user_name']);
	unset($_SESSION['user_password']);
		
	header('Location: login.php');
?>