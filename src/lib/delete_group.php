<?php
    session_start();
	
    require('connection.php');

    $stmt = $dbh->prepare('select * from group_delete(:id)');
    $stmt->bindParam(':id', $_POST['id']);
    
    try
    {
        $stmt->execute();
        $result['code'] = 0;
        $result['result'] = [];
    }
    catch (PDOException $e)
    {
        $result['code'] = $e->getCode();
        $result['message'] = $e->getMessage();
    }

    header('Content-Type: application/json');
    echo json_encode($result);
?>