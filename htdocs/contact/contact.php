<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html lang="en">
<head>
<meta HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=iso-8859-1">
<title>Contact me</title>
</head>

<body>

<h3>You submitted</h3>

<blockquote>
<?
echo "<b>Name:</b> $name<br>";

if ($epost == '') { 
	echo "<font color=\"red\"><b>E-mail Address:</b></font> ";
}
else {
	echo "<b>E-mail:</b> ";
}
echo "$epost <br>";

echo "<b>Subject:</b> $subject<br>";

if ($message == '') { 
	echo "<font color=\"red\"><b>Message:</b></font>";
}
else {
	echo "<b>Message:</b>";
}
echo "<br>$message";
?>
</blockquote>

<p>

<?
function wraptext($text,$warp) {
	$text = explode(" ", $text);
	$i = 0; $length = 0;
	while ($i <= count($text)) {
		$length += strlen($text[$i]);
		if ($length <= $warp) {
			$output .= $text[$i]." ";
			$i++;
		} else {
			$output .= "\n";
			$length = 0;
		}
	}
	return $output;
}

if ($epost != '' && $message != '') 
{
	$myemail = "vim-latex-devel@lists.sourceforge.net";

	$subject = "[Contact] " . $subject;

	$headers .= "Content-type: text/plain; charset=iso-8859-1\n";
	$headers .= "From: Contact form <vim-latex-devel-form@sourceforge.invalid>\n";
	$headers .= "Reply-To: $name <$epost>, vim-latex-devel@lists.sourceforge.net\n";
	$headers .= "X-Email-From-Web-System: \n";
	$headers .= "X-Mailer: Email From the Web\n";
	$hrefer = getenv("HTTP_REFERER" );
	$ident = getenv("REMOTE_HOST" );
	$agent = getenv("HTTP_USER_AGENT");
	$headers .= "X-Remote-Host-Info: $ident \n";
	$headers .= "X-Http-Referer-Info: $hrefer \n";
	$headers .= "X-Agent-Info: $agent \n";



	$msg = wraptext($message,72); 


	mail($myemail, $subject, $msg, $headers);

	echo "<H3>Mail sent</H3>";
}
else 
{
	echo "<H3><font color=\"red\">Not sent!</font></h3>";
	echo "<H4>Sorry, but you have to fill out the field(s) marked with red colour</h4>";
	echo "Please press the back button and fill out the missing fields";
}
?>
</body>
</html>
