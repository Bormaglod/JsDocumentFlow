<?php
	session_start();
	
	if (!isset($_SESSION['user_name']))
	{
		if (isset($_COOKIE['user_name']))
		{
			$_SESSION['user_name'] = $_COOKIE['user_name'];
		}
		else
		{
			$_SESSION['user_name'] = '';
		}
	}
	
	if (!isset($_SESSION['user_password']))
	{
		if (isset($_COOKIE['user_password']))
		{
			$_SESSION['user_password'] = $_COOKIE['user_password'];
		}
		else
		{
			$_SESSION['user_password'] = '';
		}
	}
	
	if ($_SESSION['user_name'] == '')
	{
		header('Location: login.php');
	}
	else
	{
		header('Location: main.html');
	}
?>