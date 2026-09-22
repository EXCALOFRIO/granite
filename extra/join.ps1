# Recompone los ficheros troceados y verifica su integridad.
#
#   pwsh -File extra/join.ps1
#
# Los ficheros de mas de 100 MiB no se pueden subir a GitHub enteros, asi que
# estan divididos en partes de 90 MiB dentro de extra/split/. Este script las
# concatena en el orden correcto y comprueba el SHA-256 del fichero completo
# contra SHA256SUMS.originals.

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$split = Join-Path $here 'split'
$dest = Join-Path $here 'joined'

$targets = @{
    'model.safetensors'  = 'model.safetensors'
    'model.onnx'         = 'onnx/model.onnx'
    'openvino_model.bin' = 'openvino_model.bin'
}

# SHA-256 esperado de cada fichero completo, indexado por su ruta original.
$expected = @{}
foreach ($line in Get-Content (Join-Path $split 'SHA256SUMS.originals')) {
    if ($line -match '^([0-9a-f]{64})\s+(.+)$') { $expected[$Matches[2]] = $Matches[1] }
}

$failed = $false
foreach ($flat in $targets.Keys) {
    $rel = $targets[$flat]
    $out = Join-Path $dest $rel
    New-Item -ItemType Directory -Force (Split-Path -Parent $out) | Out-Null

    $parts = Get-ChildItem $split -Filter "$flat.part*" | Sort-Object Name
    if ($parts.Count -eq 0) { throw "No se encontraron partes para $flat" }

    Write-Host "Recomponiendo $rel desde $($parts.Count) partes..."
    $fs = [System.IO.File]::Create($out)
    try {
        foreach ($p in $parts) {
            $bytes = [System.IO.File]::ReadAllBytes($p.FullName)
            $fs.Write($bytes, 0, $bytes.Length)
        }
    } finally { $fs.Close() }

    $actual = (Get-FileHash $out -Algorithm SHA256).Hash.ToLower()
    if ($actual -eq $expected[$rel]) {
        Write-Host "  OK  $rel  ($((Get-Item $out).Length) bytes)" -ForegroundColor Green
    } else {
        Write-Host "  FALLO $rel" -ForegroundColor Red
        Write-Host "    esperado: $($expected[$rel])"
        Write-Host "    obtenido: $actual"
        $failed = $true
    }
}

if ($failed) {
    Write-Host "`nAlguna verificacion fallo: no uses esos ficheros." -ForegroundColor Red
    exit 1
}
Write-Host "`nTodo correcto. Ficheros en: $dest" -ForegroundColor Green
