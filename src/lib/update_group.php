<?php
    session_start();
	
    require('connection.php');

    $stmt = $dbh->prepare('select * from group_update(:id, :code, :name)');
    $stmt->bindParam(':id', $_POST['id']);
    $stmt->bindParam(':code', $_POST['code']);
    $stmt->bindParam(':name', $_POST['name']);
    try 
    {
        $stmt->execute();
        $result['code'] = 0;
        $result['result'] = $stmt->fetchAll(PDO::FETCH_ASSOC)[0];
    }
    catch (PDOException $e)
    {
        $result['code'] = $e->getCode();
        $result['message'] = $e->getMessage();
    }

    header('Content-Type: application/json');
    echo json_encode($result);
?>