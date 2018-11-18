<?php
    session_start();
	
    require('connection.php');
    
    $stmt = $dbh->prepare('select * from get_command(:command)');
	$stmt->bindParam(':command', $_GET['id']);
    $stmt->execute();
    
    $cmd = $stmt->fetch(PDO::FETCH_ASSOC);

    $rows = array();
    $total_rows = 0;
    if ($cmd['command_type'] == 'view_table')
    {
        $schema_data = json_decode($cmd['schema_data']);

	    foreach($schema_data->viewer->datasets as $db) 
	    {
		    if ($schema_data->viewer->master == $db->name) 
		    {
			    $select = $db->select;
			    break;
		    }
	    }

        if (isset($select))
        {
            /*$pagenum = $_GET['pagenum'];
            $pagesize = $_GET['pagesize'];
            $start = $pagenum * $pagesize;*/

            $stmt = $dbh->prepare($select);
            $stmt->execute();
            $total_rows = $stmt->rowCount();
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        } 
    }

    $data = [ 'total_rows' => $total_rows, 'rows' => $rows, 'schema_data' => $schema_data ];

	header('Content-Type: application/json');
	echo json_encode($data);
?>