# Granica integracii 0177 i nativnoj priyomki 0154

Read-only-razbor celevogo dereva postoyannoj FUMA v nachale i konce podtverdil HEAD `406c6ba1d0b3373403fefd14d5f7faf8e0665b7d`, polnyij ref `refs/heads/master` i otsutstviye izmenenij otslezhivayemyikh fajlov. Proveryayusjhij ne zapuskal guard, adapter, testyi ili runtime i ne pisal v celevoye derevo. Sobstvennyij korenj zatem izmeryal kod prinyatogo 6b186059 s etimi dannyimi otdeljno; dva vida nablyudeniya ne podmenyayut drug druga.

## Soglasovannoye izmeneniye koda

Celj soderzhit prezhnyuyu paru guard/adapter s vneshnim wire v1/v2 bez obyazateljnogo `--исходник` i podgotovitelj komplekta versii 2 iz vosjmi fajlov. Perenos prinyatogo `6b1860591deb1d669f5f5ae1bd03336170fb8fce` dolzhen soglasovatj sleduyusjhiye puti vnutri `Инструменты/fum-svyaznostj-rabochej-sessii/`:

- `scripts/проверить-продолжение-задачи.py`: strogij vneshnij `fum.решение-продолжения.3`, obyazateljstva i ostatok soobsjhenij bez zapisi, zaklyuchiteljnaya sverka.
- `scripts/перехватить-завершение.py`: novyij wire i yavnyij JSONL dochernego guard.
- `scripts/обязательства_задачи_v2.py`: zaklyuchiteljnaya proverka fajlov, katalogov dopuska i Git-granicyi.
- Otsutstvuyusjhiye v celi `scripts/обработка_сообщений.py` i `scripts/сообщения_задачи.py`.
- `scripts/подготовить-комплект-завершения.py` i `шаблоны/Stop.hooks.шаблон.json`: soglasovannyiye vkhod, zakryitaya konfiguraciya i zagruzchik versii 3.

Shestj iz odinnadcati iskhodnikov uzhe sovpadayut s 6b186059: `обязательства_задачи.py`, `история_пути_гита.py`, tri modulya otchyotnoj obyortki i klassifikator `Инструменты/fum-snimki-indeksa/scripts/происхождение_сообщений.py`. Odnoimyonnyij klassifikator vnutri navyika svyaznosti ne zamenyayet poslednij. Polnyij inventarj i SHA sokhranenyi v [profile](kvalifikaciya-dopisi.json).

## Vse obnaruzhennyiye mesta vyizova

Puti nizhe otnosyatsya k `Инструменты/fum-svyaznostj-rabochej-sessii/`. Yavnyij `--исходник` provoditsya soglasovanno cherez:

- `scripts/перехватить-завершение.py` — komandu dochernego guard.
- `scripts/подготовить-комплект-завершения.py` — CLI, manifest i argv zagruzchika.
- `шаблоны/Stop.hooks.шаблон.json` — primer komandyi adaptera.
- `scripts/проверить-интеграцию-перехвата.py` — neposredstvennyiye vyizovyi guard i adaptera.
- `scripts/проверить-комплект-завершения.py` — podgotovitelj i izvlechyonnyij guard.
- `tests/test_продолжение_задачи.py` i `tests/test_обязательства_задачи_v2.py` — fabriki CLI.
- `tests/test_перехват_завершения.py` — fabriku adaptera s sokhraneniyem namerenno otricateljnyikh sluchayev bez istochnika.
- `tests/test_комплект_завершения.py` — CLI-fabriku i pryamoj `argparse.Namespace` podgotovitelya.
- `tests/test_смешанная_история_обязательств.py` — skopirovannyij guard i podmenyayemyij `sys.argv` pozdnego perekhoda.

`tests/профиль_обязательств.py` poluchayet argv cherez fiksturu, no trebuyet rasshireniya svoyego inventarya zavisimostej. `scripts/измерить-перехват-завершения.py` poluchayet istochnik cherez fabriku adaptera. Vmeste perenosyatsya `tests/исходник_проверки.py`, testyi dopuska, obrabotki i chitatelya, fiksturyi i prinyatyiye profilirovochnyiye scenarii. Ozhidaniya starogo vneshnego wire obnovlyayutsya soglasovanno. Poisk isklyuchal istoricheskij Zhurnal, syiryiye istochniki, proyekciyu i nastrojki; absolyutnaya polnota lyubyikh vneshnikh sokhranyonnyikh komand ne utverzhdayetsya.

## Pravila i dannyiye

Normativnyij perenos vklyuchayet `AGENTS.md`, `Правила/агентов/журнал-и-происхождение.md`, `Правила/агентов/инвентарь-правил.json`, validator i testyi `Инструменты/fum-dekompoziciya-pravil-agentov/`, rukovodstva i CLI navyika svyaznosti. V celi pravilo 0177 poka sokhranyayet vremennuyu ruchnuyu sverku, a pravilo 000062 pokazyivayet vyizov bez istochnika. Prinyatyij validator proveryayet obyazateljnyiye `--перед-завершением`, `--исходник` i `остаток --без-записи`. Istoricheskiye zapisi i proyekciya ne ispravlyayutsya vruchnuyu radi perenosa.

Reyestr `Планирование/задачи/01a07d3d-d376-7ad2-aafc-67e4c25a67eb/обязательства.json` imeyet skhemu v3, chastichnoye pokryitiye i semj obyazateljstv, vklyuchaya `FUM-ПРОДОЛЖЕНИЕ-СИСТЕМА`. Yedinstvennaya zapisannaya rabota — prinyatyij `FUM-ОСТАТОК-РЕЕСТР`; konkretnaya sleduyusjhaya rabota nativnogo Stop otsutstvuyet. V otslezhivayemom kataloge zadachi net `обработка-сообщений.jsonl`. Novyij guard ne sozdayot soderzhateljnogo sleduyusjhego dejstviya i ne pogashayet staryiye soobsjheniya faktom chteniya.

Reyestr vyibran konkretnyim vkhodom progress kandidata. Pered vklyucheniyem kornyu nuzhno soglasovatj realjnuyu sleduyusjhuyu rabotu, yeyo rezuljtatyi i otnositeljnyiye fajlyi progress s osnovaniyami. Proizvoljnyij khyesh vsej perepiski ili obsjhego Zhurnala ne dokazyivayet progress. Predel povtorov, vozvrat prezhnego otpechatka, ostanovka cheloveka i otsutstviye effektov dlya chuzhogo sobyitiya sokhranyayutsya.

## Dostup i priyomka

Oficialjnoye `read_thread` podtverdilo celevoj UUID i cwd aktivnoj zadachi «🎻 FUMA». Sobstvennyij UUID ispolnitelya — `01a08d6a-4df0-7cb3-9bc4-ebd730a44882`, celevoj — `01a07d3d-d376-7ad2-aafc-67e4c25a67eb`; istochnik koda i derevo dannyikh guard razlichayutsya. Tochnyiye puti i JSON oficialjnogo nablyudeniya sokhranenyi privatno.

Katalog callable-instrumentov tekusjhej zadachi ne predostavlyayet hooks/list ili chteniye aktivnogo sloya hooks. Eto granica dostupa, a ne dokazateljstvo otsutstviya hooks v Desktop. Dejstvuyusjhiye handlers i Trust ne podtverzhdenyi. Drugoj app-server, CUA Codex, sluzhebnyiye bazyi i nastrojki ne ispoljzovalisj.

Privatnyij komplekt izvlekayet kod 6b186059 bez zapisi v aktivnuyu celj. On zakreplyayet UUID, yavnyij JSONL, cwd, derevo dannyikh, progress i otdeljnoye sostoyaniye. Podgotovka ne integriruyet pravila, ne obnovlyayet sokhranyonnyiye zagruzchiki, ne ustanavlivayet hooks i ne dokazyivayet nativnyij block ili sleduyusjheye razreshyonnoye dejstviye. FUM-STEP-0154 ostayotsya active do otdeljnoj nablyudayemoj nativnoj priyomki i sleduyusjhego razreshyonnogo dejstviya toj zhe zadachi bez novoj chelovecheskoj komandyi.

## Istochnik

- [Iskhodnyiye komandyi, porucheniye i granica etapa](../zapros.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 08:51:54 MSK -->
<!-- content-sha256: sha256:6415eefcabc16a2d2ae199dc409a2ece46aa5b23aa59452ecc5308389527580b -->
<!-- FUM-MD-RECENCY:END -->
