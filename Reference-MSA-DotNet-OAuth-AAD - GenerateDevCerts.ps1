$array = @("Health.Monitor", "Svc.A", "Svc.B", "Svc.C")

$slnName = "Reference-MSA-DotNet-OAuth-AAD"

$pfxFile = "$slnName - ContainerDev.pfx"
$crtFile = "$slnName - ContainerDev.crt"
$keyFile = "$slnName - ContainerDev.key"
$certPemFile = "$slnName - ContainerDevCert.pem"
$keyPemFile = "$slnName - ContainerDevKey.pem"
$configFile = "$slnName - OpenSSLConfig.cnf"

$pword = New-Guid

$env:path = $env:path + ";C:\Program Files\Git\usr\bin"

openssl req -x509 -newkey rsa:4096 -days 730 -keyout $keyPemFile -out $certPemFile -nodes -subj "/C=US/ST=TX/L=DFW/O=NullPtrLtd/OU=AppDev/CN=NullPtrLtd" -reqexts "v3_req" -config $configFile
openssl pkcs12 -export -out $pfxFile -inkey $keyPemFile -in $certPemFile -password pass:$pword
openssl pkcs12 -in $pfxFile -nocerts -nodes -out $keyFile -password pass:$pword
openssl pkcs12 -in $pfxFile -clcerts -nokeys -out $crtFile -password pass:$pword

$winPath = "$env:APPDATA\ASP.NET\https\$pfxFile"
$path = "/root/.aspnet/https/$pfxFile"

cp .\$pfxFile $winPath
cp .\$crtFile ..\$slnName\dev_certs

foreach ($element in $array) {
	echo $element
	$proj = $element		
	cd ..\$slnName\$proj
	dotnet user-secrets set Kestrel:Certificates:ContainerDev:Password $pword
	dotnet user-secrets set Kestrel:Certificates:ContainerDev:Path $path
	dotnet user-secrets set Kestrel:Certificates:ContainerDev:WinPath $winPath
	cd $PSScriptRoot
}
