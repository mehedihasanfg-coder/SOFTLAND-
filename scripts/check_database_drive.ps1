Add-Type -AssemblyName System.Windows.Forms

$letters = [char[]](68..90)
foreach ($letter in $letters) {
    $folder = ('{0}:\SOFTLAND' -f $letter)
    try {
        New-Item -ItemType Directory -Path $folder -Force -ErrorAction Stop | Out-Null
        $probe = Join-Path $folder (".softland_setup_probe_" + [guid]::NewGuid().ToString("N") + ".tmp")
        [System.IO.File]::WriteAllText($probe, "SOFTLAND")
        Remove-Item -LiteralPath $probe -Force -ErrorAction Stop
        Write-Output $folder
        exit 0
    }
    catch {
        continue
    }
}

$message = "Don't found database location drive (without C:\) so, can't store your necessary record"
[System.Windows.Forms.MessageBox]::Show(
    $message,
    "SOFTLAND Setup",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Error
) | Out-Null
exit 1
