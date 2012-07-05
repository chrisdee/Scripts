## PowerShell: Simple Function to generate Secure Passwords ##

Function GeneratePassword {
param( 
[int] $len = 10, #Change the length here to reflect the numbe of characters you want your password to be
[string] $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_!@#$%^&*()_"
)
$bytes = new-object "System.Byte[]" $len
$rnd = new-object System.Security.Cryptography.RNGCryptoServiceProvider
$rnd.GetBytes($bytes)
$result = ""
for( $i=0; $i -lt $len; $i++ )
{
$result += $chars[ $bytes[$i] % $chars.Length ]	
}
$result
}

GeneratePassword