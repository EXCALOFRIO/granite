#!/usr/bin/env bash
# Recompone los ficheros troceados y verifica su integridad.
#
#   bash extra/join.sh
#
# Los ficheros de mas de 100 MiB no se pueden subir a GitHub enteros, asi que
# estan divididos en partes de 90 MiB dentro de extra/split/. Este script las
# concatena en el orden correcto y comprueba el SHA-256 del fichero completo
# contra SHA256SUMS.originals.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
split="$here/split"
dest="$here/joined"

# flat:ruta-original
targets="model.safetensors:model.safetensors model.onnx:onnx/model.onnx openvino_model.bin:openvino_model.bin"

failed=0
for t in $targets; do
    flat="${t%%:*}"
    rel="${t#*:}"
    out="$dest/$rel"
    mkdir -p "$(dirname "$out")"

    parts=$(ls "$split/$flat".part* 2>/dev/null | sort)
    [ -n "$parts" ] || { echo "No se encontraron partes para $flat" >&2; exit 1; }

    echo "Recomponiendo $rel desde $(echo "$parts" | wc -l) partes..."
    cat $parts > "$out"

    expected=$(grep "  $rel\$" "$split/SHA256SUMS.originals" | cut -d' ' -f1)
    actual=$(sha256sum "$out" | cut -d' ' -f1)
    if [ "$actual" = "$expected" ]; then
        echo "  OK  $rel  ($(stat -c%s "$out") bytes)"
    else
        echo "  FALLO $rel"
        echo "    esperado: $expected"
        echo "    obtenido: $actual"
        failed=1
    fi
done

if [ "$failed" -ne 0 ]; then
    echo
    echo "Alguna verificacion fallo: no uses esos ficheros." >&2
    exit 1
fi
echo
echo "Todo correcto. Ficheros en: $dest"
