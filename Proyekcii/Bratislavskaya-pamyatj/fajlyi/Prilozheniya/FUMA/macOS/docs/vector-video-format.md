# Vektornyij videomontazh FUM

`*.fumcut.json` — redaktiruyemyij dokument montazha, a ne gotovyij videofajl.
On khranit ssyilki na iskhodnyiye media i nabor operacij: dorozhki, klipyi, obrezki,
pozicii na tajmlajne, gromkostj, transformyi, effektyi, perekhodyi, podpisi i
markeryi. Takoj dokument mozhno peresobiratj, menyatj i proigryivatj kak live-
kompoziciyu bez eksporta MP4/MOV.

## Principyi

- Iskhodniki ne kopiruyutsya i ne perekodiruyutsya: dokument ispoljzuyet URI so skhemoj
  `file`, `https`, `fum` ili drugoj skhemoj.
- Montazh nerazrushayusjhij: `sourceRange` opisyivayet fragment iskhodnika, a
  `timeRange` — mesto etogo fragmenta v kompozicii.
- Video, audio, subtitryi, HTML-scenyi, vektornyiye elementyi i sgenerirovannyiye
  assetyi predstavlenyi yedinyim spiskom `sources`.
- Vizualjnyiye izmeneniya zhivut kak parametryi: `transform`, `crop`, `opacity`,
  `effects`, `transitions`, `text`.
- Render v fajl ne yavlyayetsya chastjyu formata. Yesli pozzhe ponadobitsya eksport,
  on dolzhen chitatj etot dokument kak iskhodnyij vektornyij graf.

## Svyazj s pamyatjyu i prezentaciyami

`*.fumcut.json` — vyikhodnaya storona pamyati FUM. Yesli RAG-zametka khranit
ssyilku na istochnik, lokaljnyij putj, subtitryi i tajmkodyi, to vektornyij montazh
dolzhen umetj prevrasjhatj etu ssyilku v pokazyivayemyij fragment: citatu,
videovstavku, titr, poyasnyayusjhij overlay ili chastj prezentacionnogo rasskaza.

Eto nuzhno dlya dvunapravlennoj pamyati: istochnik prevrasjhayetsya v zametku, a
zametka mozhet vernutjsya v rasskaz o FUM s proveryayemoj ssyilkoj na pervichnyij
material i nerazrushayusjhim videomontazhom.

## Verkhnij urovenj

```json
{
  "schema": "fum.video.vector-cut",
  "version": 1,
  "title": "Example",
  "canvas": { "width": 1920, "height": 1080, "backgroundColor": "#000000" },
  "playback": { "frameRate": 30, "duration": 120, "previewTime": 42 },
  "sources": [],
  "timeline": { "tracks": [] },
  "markers": [],
  "notes": {}
}
```

## Istochniki

Kazhdyij istochnik imeyet stabiljnyij `id`, tip `kind`, chelovekochitayemoye imya i URI.
Podderzhivayemyiye `kind`: `video`, `audio`, `subtitle`, `image`, `vector`, `html`,
`text`, `generated`, `remote`.

```json
{
  "id": "video-...",
  "kind": "video",
  "uri": "https://media.example.invalid/example.mp4",
  "displayName": "example",
  "role": "embedded video",
  "language": null,
  "mediaType": "mp4",
  "duration": 120,
  "fileSize": 123456789
}
```

## Tajmlajn

Tajmlajn sostoit iz dorozhek. Dorozhka zadayet sloj/rolj, a klipyi vnutri neye
zadayut konkretnyiye fragmentyi.

```json
{
  "id": "track-video-main",
  "kind": "visual",
  "name": "Main video",
  "muted": false,
  "locked": false,
  "clips": [
    {
      "id": "clip-video-main",
      "kind": "media",
      "sourceID": "video-...",
      "timeRange": { "start": 0, "duration": 12 },
      "sourceRange": { "start": 35, "duration": 12 },
      "speed": 1,
      "opacity": 1,
      "transform": {
        "x": 0,
        "y": 0,
        "scaleX": 1,
        "scaleY": 1,
        "rotation": 0,
        "anchorX": 0.5,
        "anchorY": 0.5
      },
      "effects": [],
      "transitions": []
    }
  ]
}
```

## Pervyij runtime-kontur

Vo vkladke Video FUM uzhe umeyet:

- sokhranitj tekusjhij vyibrannyij rolik, audiodorozhku i subtitryi kak
  `<name>.fumcut.json` v vyibrannom kataloge videodokumentov;
- otkryitj susjhestvuyusjhij `*.fumcut.json` kak aktivnyij dokument;
- raskryitj aktivnyij dokument v Finder;
- logirovatj operacii v `video-player/events.jsonl` vnutri vneshnego `FUM_MEMORY_ROOT`.

Sleduyusjhij sloj — live-proigryivaniye dokumenta celikom: neskoljko klipov,
neskoljko istochnikov, overlay-dorozhki, titryi i perekhodyi bez eksporta
videofajla.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 02:32:08 MSK -->
<!-- content-sha256: sha256:7176e9d2eb4d7cd7ae9a759284d9bc446042e88f0047103de1780ec7a38c7f63 -->
<!-- FUM-MD-RECENCY:END -->
