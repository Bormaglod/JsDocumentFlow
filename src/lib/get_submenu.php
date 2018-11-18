<?php
	session_start();
	
	require('connection.php');
	
	
	$stmt = $dbh->prepare('select * from select_menu()');
	$stmt->execute();
	
	$menu = $stmt->fetchAll(PDO::FETCH_ASSOC);

	$result = generate_menu($menu, null);

	header('Content-Type: application/json');
	echo json_encode($result);
	
	function generate_menu($menu, $parent_id)
	{
		$result = array_select($menu, $parent_id);
		for($i = 0; $i < count($result); $i++) 
		{
			$submenu = generate_menu($menu, $result[$i]['id']);
			$result[$i]['nodes'] = $submenu;
		}
		
		return $result;
	}
	
	function array_select($menu, $parent_id)
	{
		$result = array();
		foreach($menu as $item) 
		{ 
			if (is_null($parent_id))
			{
				if (is_null($item['parent_id']))
					$result[] = $item;
			}
			else
			{
				if ($item['parent_id'] == $parent_id)
					$result[] = $item;
			}
		}
		
		return $result;
	}
?>