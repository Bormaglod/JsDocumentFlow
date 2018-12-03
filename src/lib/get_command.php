<?php
	session_start();
	
	require('connection.php');
	
	$stmt = $dbh->prepare('select * from get_command(:command)');
	$stmt->bindParam(':command', $_POST['id']);
	$stmt->execute();
	
	$result = $stmt->fetch(PDO::FETCH_ASSOC);

	$schema_data = json_decode($result['schema_data']);;
	foreach($schema_data->viewer->datasets as $db) 
	{
		if ($db->name == $schema_data->viewer->master) 
		{
            $select = $db->select;
                
            $stmt = $dbh->prepare('select * from get_info_table(:code_table)');
            $stmt->bindParam(':code_table', $db->name);
            $stmt->execute();

            $info = $stmt->fetch(PDO::FETCH_ASSOC);
            $db->info = $info;
			break;
		}
	}
	
	$result['schema_data'] = $schema_data;

	header('Content-Type: application/json');
	echo json_encode($result);
?>