# Reference-SelfSignedCerts

Due to the limitations in the Visual Studio environment around self signed certificates, I needed a way to generate developer certificates that could be included in docker containers that would allow for SSL communication within a container ochestration environment. There are specific elements that needed to be included in the cfg file that would allow for trusted communication from container to container.

## Configuration File Changes
The version 3 extensions to the x.509 spec need to be provided
```
x509_extensions		= v3_req # The extentions to add to the self signed cert
```
Of the version 3 extensions the following need to be included. 
* Even through this is a self signed certificate we need to mark it as a CA autohority so that it can be trusted on the developer machine
* The Key Usage needs to include keyCertSign and keyEncipherment
* A list of Subject Alternative Names need to be provided. This will include the list of Conatiner names that will be running inside the orchestrator
```
[ v3_req ]
# Extensions to add to a certificate request
authorityKeyIdentifier=keyid,issuer
#basicConstraints = CA:FALSE
basicConstraints=CA:TRUE,pathlen:0
keyUsage = nonRepudiation, digitalSignature, keyCertSign, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
```
The Altername Subject Names will allow this certificate to be used by all containers in an environment. It would be possible to generate a certificate per container but that would add complexity to the trusting steps for the certificates in each container that will be covered later.
```
[alt_names]
DNS.1 = localhost
DNS.2 = health.monitor
DNS.3 = svc.a
DNS.4 = svc.b
DNS.5 = svc.c
DNS.6 = dev
IP.1 = 192.168.1.1
IP.2 = 192.168.0.1
IP.3 = 127.0.0.1
IP.4 = 10.0.75.0
```
## Powershell Script
A script was written to handle the creation of the certificate files. This uses the Git for Windows installation to access the openssl module. This module is expected to be on developer machines as a standard installed tool but if it is not present then the script will need to be pointed to a copy of the OpenSSL.exe file

Since each solution should have its own development certificate the expectaed usage will be a copy of the script and configuration file per solution. This way the end point projects can be uniquely listed and added in as alternative subjects. Currently the script will not add the certificate to the Trusted Root Certificate Authorities store and this needs to be done manually. This will require admin privileges in Windows to accomplish. 

Once the certificate files are created then they will be copied into the location that Visual Studio expects them to be and referenced as the docker container mount point expects to find them. The *.crt file will also be copied into a default location that the dockerfile will expect the file to exist in.
```
$winPath = "$env:APPDATA\ASP.NET\https\$pfxFile"
$path = "/root/.aspnet/https/$pfxFile"

cp .\$pfxFile $winPath
cp .\$crtFile ..\$slnName\dev_certs
```
## Dockerfile
For an application to consume this certificate it will need to be trusted at the container level. For the basic containers that are being used the following lines are added in to the Dockerfile
```
WORKDIR /usr/local/share/ca-certificates
COPY ./dev_certs/*.crt .
RUN update-ca-certificates -v
```
What is happening is that the generated certificate is copied from the project folder as a part of the script generation and then it is copied into the runtime layer in the docker container. Once this is done the Update-CA-Certificate tool is called to add the self signed certificate into the trusted certificate store for the container. Once this is completed and HTTPS end point in the container that is secured with the self signed development certificate can be called. It will prevent the scenario where an untrusted certificate is present.
