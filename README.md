# granite-embedding-97m-multilingual-r2 — paquete local

Espejo del modelo [`ibm-granite/granite-embedding-97m-multilingual-r2`](https://huggingface.co/ibm-granite/granite-embedding-97m-multilingual-r2)
preparado para usarlo en entornos donde Hugging Face está bloqueado.

- **Revisión fijada:** `835ad14087e140460703cf0fae09f97d469d65c2`
- **Licencia:** Apache-2.0 (incluida en el paquete)
- **Sin Git LFS a propósito:** un `git clone` trae los pesos reales, nunca un puntero LFS.

## Uso rápido

Lo único que necesitas para la búsqueda semántica en CPU es la carpeta
`granite-embedding-97m-multilingual-r2-cpu-onnx-avx2/`. Cópiala a su destino:

```
workspace\models\granite-embedding-97m-multilingual-r2\
```

O descomprime el ZIP equivalente, que trae exactamente lo mismo.

## Contenido

### `granite-embedding-97m-multilingual-r2-cpu-onnx-avx2/` — paquete principal

```
onnx/model_quint8_avx2.onnx          93,7 MiB   ONNX cuantizado para CPU con AVX2
1_Pooling/config.json                           configuración de pooling (CLS)
config.json                                     arquitectura ModernBERT
config_sentence_transformers.json
modules.json
sentence_bert_config.json
special_tokens_map.json
tokenizer.json                       24,1 MiB
tokenizer_config.json
README.md                                       tarjeta del modelo original
LICENSE                                         Apache-2.0
MODEL-PACKAGE.json                              metadatos del paquete
SHA256SUMS                                      SHA-256 de todos los ficheros
```

También disponible como
`granite-embedding-97m-multilingual-r2-cpu-onnx-avx2.zip` (69 MB), con su
SHA-256 externo en el fichero `.sha256` adjunto.

### `extra/` — variantes no necesarias para CPU/ONNX

| Fichero | Tamaño | Estado |
|---|---|---|
| `openvino/openvino_model_qint8_quantized.{bin,xml}` | 94 MB | entero |
| `openvino_model.xml` | 0,4 MB | entero (su `.bin` está troceado) |
| `model.sig` | 12 KB | entero |
| `split/model.safetensors.part*` | 186 MB | **troceado en 3 partes** |
| `split/model.onnx.part*` | 372 MB | **troceado en 5 partes** |
| `split/openvino_model.bin.part*` | 372 MB | **troceado en 5 partes** |

GitHub rechaza ficheros de más de 100 MiB, así que esos tres van divididos en
partes de 90 MiB dentro de `extra/split/`. Para recomponerlos:

```bash
bash extra/join.sh
```

```powershell
pwsh -File extra/join.ps1
```

Cualquiera de los dos concatena las partes en orden, verifica el SHA-256 de
cada fichero completo contra `extra/split/SHA256SUMS.originals` y deja el
resultado en `extra/joined/`. Si un hash no cuadra, el script falla en vez de
dejarte un fichero corrupto.

## Verificar la integridad

Los hashes del paquete principal coinciden con los oid LFS oficiales de
Hugging Face. Para comprobarlo tú mismo:

```bash
cd granite-embedding-97m-multilingual-r2-cpu-onnx-avx2 && sha256sum -c SHA256SUMS
```

El `.gitattributes` del repo desactiva toda conversión de fin de línea
(`* -text`). Es imprescindible: sin eso, al clonar en Windows los `.json` se
convertirían a CRLF y los hashes dejarían de cuadrar.

## Validación realizada

Comprobado con ONNX Runtime 1.30 sobre el ONNX cuantizado:

| Comprobación | Resultado |
|---|---|
| Carga del modelo | correcta, no es HTML ni un puntero LFS |
| Entradas | `input_ids`, `attention_mask` |
| Salida | `last_hidden_state`, dimensión 384 |
| Pooling CLS + normalización L2 | correctos, normas = 1,0 |
| Tokenizador | devuelve tokens válidos |
| SHA-256 del ONNX | coincide con el oficial de Hugging Face |
| Latencia en CPU | ~5 ms una consulta, ~13 ms lote de 4 |
| Semántica es/en/pt | 0,84–0,88 entre paráfrasis, 0,57–0,65 con texto no relacionado |

## Detalles del modelo

| | |
|---|---|
| Arquitectura | ModernBERT (`ModernBertModel`) |
| Dimensión del embedding | 384 |
| Longitud máxima de secuencia | 32 768 tokens |
| Pooling | CLS |
| Normalización | L2 |
| Vocabulario | 180 000 |
| Capas / cabezas | 12 / 12 |

## Notas

- El repositorio original **no incluye un fichero `LICENSE`**; la Apache-2.0
  consta solo como etiqueta y en la tarjeta del modelo. El `LICENSE` del
  paquete es el texto canónico de
  [apache.org](https://www.apache.org/licenses/LICENSE-2.0.txt).
- `modules.json` referencia un módulo `2_Normalize` cuyo directorio no existe
  en el repositorio original. Es normal en `sentence-transformers` (no lleva
  configuración), pero si cargas el paquete con esa librería en lugar de ONNX
  Runtime directo, **la normalización L2 hay que aplicarla en código**.
- Dependencias mínimas para usarlo: `onnxruntime`, `tokenizers`, `numpy`.
  No hace falta `torch`, `sentence-transformers` ni una base vectorial externa.
