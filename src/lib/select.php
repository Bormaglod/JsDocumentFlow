<?php
    session_start();
	
    require('connection.php');
    
    $stmt = $dbh->prepare($_POST['select_sql']);

    // получение всех параметров запоса вида ':параметр'
    preg_match_all('/(?<!:):([a-zA-Z]{1}[a-zA-Z_0-9]*)/', $_POST['select_sql'], $params, PREG_SET_ORDER);
    foreach ($params as $value) 
    {
        $param_type = array_key_exists($value[1], $_POST) ? PDO::PARAM_STR : PDO::PARAM_NULL;
        $stmt->bindParam($value[0], $_POST[$value[1]], $param_type);
    }

    $stmt->execute();
    $total_rows = $stmt->rowCount();
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $data = [ 'total_rows' => $total_rows, 'rows' => $rows ];

	header('Content-Type: application/json');
	echo json_encode($data);
?>