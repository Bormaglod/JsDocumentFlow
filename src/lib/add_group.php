<?php
    session_start();
	
    require('connection.php');

    $stmt = $dbh->prepare('select * from group_create(:kind, :code, :name, :parent)');
    $stmt->bindParam(':kind', $_POST['kind']);
    $stmt->bindParam(':code', $_POST['code']);
    $stmt->bindParam(':name', $_POST['name']);
    $stmt->bindParam(':parent', $_POST['parent'], ($_POST['parent'] == 'top') ? PDO::PARAM_NULL : PDO::PARAM_STR);

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