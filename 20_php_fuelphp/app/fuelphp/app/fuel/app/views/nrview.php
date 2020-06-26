<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>Function 1</title>
</head>
<body>
  <?php echo $comment; ?>
  <ul>
    <li><a href="/nrctrl">Index</a></li>
    <li><a href="/nrctrl/function1">Function1</a></li>
    <li><a href="/nrctrl/function2">Function2</a></li>
    <li><a href="/nrctrl/function3">Function3</a></li>
    <li><a href="/">Home</a></li>
  </ul>
  <form action="/nrctrl/post" method="post">
				<input type="hidden" name="hidden_key1" value="hidden_value1"/>
				<input type="hidden" name="hidden_key2" value="hidden_value2"/>
				<input type="hidden" name="hidden_key3" value="hidden_value3"/>
				<input type="submit" name="submit" value="送信" />
	</form>
</body>
</html>

