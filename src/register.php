<!DOCTYPE html>
<html lang="en">
	<head>
		<meta http-equiv="content-type" content="text/html; charset=utf-8"/>
		<title>Регистрация</title>
		<link type="text/css" href="css/main.css" media="screen" rel="stylesheet"/>
		<script type="text/javascript" src="js/main.js"></script>
	</head>
	<body>
		<div class="container" style="padding-top:30px">
			<div class="row">
				<div class="col-3">
				</div>
				<div class="col-6 align-self-center">
					<div class="card">
						<div class="card-header">
							Регистрация
						</div>
						<div class="card-body">
							<form>
								<div class="form-group">
									<label for="user_name">Имя пользователя</label>
									<input type="text" class="form-control" id="user_name" placeholder="Введите имя пользователя">
								</div>
								<div class="form-group">
									<label for="alias">Псевдоним</label>
									<input type="text" class="form-control" id="alias" placeholder="Введите псевдоним">
								</div>
								<div class="form-group">
									<label for="user_pass">Пароль</label>
									<input type="password" class="form-control" id="user_pass" placeholder="Введите пароль">
								</div>
								<div class="form-group">
									<label for="user_pass_confirm">Повторите пароль</label>
									<input type="password" class="form-control" id="user_pass_confirm" placeholder="Введите пароль еще раз">
								</div>
								<p>Уже зарегистрированы? <a href= "login.php">Введите имя пользователя</a></p>
							</form>
						</div>
						<div class="card-footer">
							<button type="submit" class="btn btn-primary btn-block">Регистрация</button>
						</div>
					</div>
				</div>
				<div class="col-3">
				</div>
			</div>
		</div>
	</body>
</html>