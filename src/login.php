<?php
	session_start();
?>
<!DOCTYPE html>
<html lang="ru">
	<head>
		<meta http-equiv="content-type" content="text/html; charset=utf-8"/>
		<title>Вход</title>
		<link href="css/main.css" media="screen" rel="stylesheet"/>
		<script type="text/javascript" src="js/main.js"></script>
		<script>
			$(function()
			{
				$.getJSON('lib/get_clients.php', function(data)
				{
					var items = [];
					$.each(data, function(i, item)
					{
						items.push('<option>' + item.name + '</option>');
					});
		
					$('#client-list').append(items.join(""));
					$('.combobox').editableSelect({ filter: false });
				});
			});
		</script>
	</head> 
	<body>
		<div class="wrapper d-flex flex-column" style="min-height: 100vh;">
			<div class="container d-flex flex-column align-items-center justify-content-center flex-grow-1">
				<div class="row justify-content-center">
					<div class="col-md-auto">
						<div class="card">
							<div class="card-header">
								Вход
							</div>
							<form action="sign_in.php" method="post">
								<div class="card-body">
									<?php
										if (isset($_SESSION['sqlcode']))
										{
									?>
									<div class="alert alert-danger" role="alert">
										<?php 
											if ($_SESSION['sqlcode'] == '08006')
												echo('Неверное имя пользователя или пароль');
											else
												echo($_SESSION['sqlcode'] . ": " . $_SESSION['sql_message']); 
										?>
									</div>
									<?php
											unset($_SESSION['sqlcode']);
											unset($_SESSION['sql_message']);
										}
									?>
									<div class="form-group">
										<label for="user_name">Имя пользователя</label>
										<select id="client-list" name='name' class="form-control combobox"></select>
									</div>
									<div class="form-group">
										<label for="user_pass">Пароль</label>
										<input type="password" class="form-control" id="user_pass" name="password" placeholder="Введите пароль">
									</div>
									<p>Еще не зарегистрированы? <a href= "register.php">Регистрация</a></p>
								</div>
								<div class="card-footer">
									<button type="submit" class="btn btn-primary btn-block">Вход</button>
								</div>
							</form>
						</div>
					</div>
				</div>
			</div>
			<footer class="footer">
				<div class="container-fluid">
					<div class="row">
						<div class="col">
							<p class="text-right">&copy;2018 Тепляшин Сергей Васильевич</p>
						</div>
					</div>
				</div>
			</footer>
		</div>
	</body>
</html>