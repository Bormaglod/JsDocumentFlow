<?php
	session_start();
	
	$guest = true;
	require("lib/connection.php");
		
	$stmt = $dbh->prepare('select pg_name from client where name = :name');
	$stmt->bindParam(':name', $_POST['name']);
	$stmt->execute();
		
	$_SESSION['user_name'] = $stmt->fetchColumn();
	$_SESSION['user_password'] = $_POST['password'];
		
	try
	{
		require("lib/connection.php");
		$stmt = $dbh->prepare('select login();');
		$stmt->execute();
		
		header('Location: main.html');
	}
	catch (PDOException $e) 
	{
		$state = $e->getMessage();
		if (!strstr($state, 'SQLSTATE['))
			$state = $e->getCode();
		if (strstr($state, 'SQLSTATE['))
		{
			preg_match('/SQLSTATE\[(\w+)\] \[(\w+)\] (.*)/', $state, $matches);
			$code = ($matches[1] == 'HT000' ? $matches[2] : $matches[1]);
			$message = $matches[3];
     }
		
		$_SESSION['sqlcode'] = $code;
		$_SESSION['sql_message'] = $message;
		header('Location: login.php');
	}
?>