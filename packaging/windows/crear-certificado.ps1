# Creates the GreyStoreChile self-signed code signing certificate. Run once, on your own PC:
#
#   powershell -ExecutionPolicy Bypass -File crear-certificado.ps1
#
# Output folder (Desktop\GreyStoreChile-certificado):
#   GreyStoreChile.pfx   certificate + PRIVATE KEY. Keep it safe: anyone holding it and its password can
#                        sign programs that client PCs trusting this certificate will accept as yours.
#   password.txt         the PFX password
#   pfx-base64.txt       the PFX encoded for the GitHub secret WINDOWS_SIGNING_PFX_BASE64
#   GreyStoreChile.cer   public part only, safe to share
#
# The certificate is restricted to code signing (EKU 1.3.6.1.5.5.7.3.3) and marked as not being a CA
# (basic constraints, empty SEQUENCE = hex 3000), so trusting it on a client PC lets it vouch for
# signed programs only: it cannot issue website certificates or other certificates.

$ErrorActionPreference = 'Stop'

$outDir = Join-Path ([Environment]::GetFolderPath('Desktop')) 'GreyStoreChile-certificado'
if (Test-Path (Join-Path $outDir 'GreyStoreChile.pfx')) {
    throw "Ya existe un certificado en $outDir. Bórralo o muévelo antes de crear uno nuevo."
}
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# Alphanumeric only: the password is passed on the Inno Setup command line in the build.
$alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789'.ToCharArray()
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$bytes = New-Object byte[] 32
$rng.GetBytes($bytes)
$password = -join ($bytes | ForEach-Object { $alphabet[$_ % $alphabet.Length] })

$cert = New-SelfSignedCertificate `
    -Type Custom `
    -Subject 'CN=GreyStoreChile, O=GreyStoreChile, L=Puerto Varas, C=CL' `
    -FriendlyName 'GreyStoreChile - firma de programas' `
    -KeyAlgorithm RSA -KeyLength 3072 -HashAlgorithm SHA256 `
    -KeyUsage DigitalSignature `
    -KeyExportPolicy Exportable `
    -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={critical}{hex}3000') `
    -NotAfter (Get-Date).AddYears(10) `
    -CertStoreLocation 'Cert:\CurrentUser\My'

$basic = $cert.Extensions | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509BasicConstraintsExtension] }
$eku = $cert.Extensions | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension] }
if (-not $basic -or $basic.CertificateAuthority) { throw 'El certificado no quedó marcado como "no CA".' }
if (-not $eku -or ($eku.EnhancedKeyUsages | ForEach-Object Value) -notcontains '1.3.6.1.5.5.7.3.3') {
    throw 'El certificado no quedó limitado a firma de código.'
}

$pfxPath = Join-Path $outDir 'GreyStoreChile.pfx'
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $securePassword | Out-Null
Export-Certificate -Cert $cert -FilePath (Join-Path $outDir 'GreyStoreChile.cer') | Out-Null
Set-Content -Path (Join-Path $outDir 'password.txt') -Value $password -NoNewline
Set-Content -Path (Join-Path $outDir 'pfx-base64.txt') -Value ([Convert]::ToBase64String([IO.File]::ReadAllBytes($pfxPath))) -NoNewline

# The PFX file is the only copy that should exist; drop the one left in the user's certificate store.
Remove-Item -Path ("Cert:\CurrentUser\My\" + $cert.Thumbprint) -DeleteKey

Write-Host ''
Write-Host 'Certificado creado en:' $outDir -ForegroundColor Green
Write-Host 'Huella (thumbprint):' $cert.Thumbprint
Write-Host 'Válido hasta:' $cert.NotAfter.ToString('yyyy-MM-dd')
Write-Host ''
Write-Host 'Ahora crea en GitHub (Settings > Secrets and variables > Actions) estos dos secretos:'
Write-Host '  WINDOWS_SIGNING_PFX_BASE64   = contenido de pfx-base64.txt'
Write-Host '  WINDOWS_SIGNING_PFX_PASSWORD = contenido de password.txt'
Write-Host ''
Write-Host 'Después borra pfx-base64.txt y guarda GreyStoreChile.pfx + password.txt en un lugar seguro.'
