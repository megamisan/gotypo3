<html>

<body>

<?php

$dh = opendir("static");
while (false !== ($filename = readdir($dh))) {
   $files[] = $filename;
}
rsort($files);
foreach($files as $filename) {
	if($filename!="." && $filename!="..") {
		echo '<a href="static/'.$filename.'/awstats.${DOMAIN}.html" target="awstats">'.$filename.'</a><br />';
	}
}

?>

</body>

</html>
