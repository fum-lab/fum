# Voprosyi i otvetyi

Etot katalog khranit korotkiye voprosno-otvetnyiye materialyi neposredstvenno o susjhnosti [FUM](../Glossarij/FUM.md): yego prirode, ustrojstve, svojstvakh, principakh, modeli, arkhitekture, povedenii i granicakh.

Razdel ne zamenyayet [iskhodnyiye zaprosyi](../Glossarij/iskhodnyij-zapros.md), [zhurnal rabot](../Glossarij/zhurnal-rabot.md) ili [otkryityiye voprosyi](../Glossarij/otkryityij-vopros.md). Iskhodnyij poljzovateljskij tekst i khod rabotyi sokhranyayutsya ryadom v [papke zaprosa](../Glossarij/papka-zaprosa.md) v `Журнал/`, a protivorechiya i neodnoznachnosti trebovanij vedutsya v `Вопросы/`.

## Pravila popolneniya

- Dlya kazhdogo doslovno sformulirovannogo poljzovateljskogo voprosa neposredstvenno o susjhnosti FUM, okanchivayusjhegosya znakom `?`, poluchivshego soderzhateljnyij rabochij otvet i poleznogo kak povtorno chitayemaya spravka, obyazateljno sozdayotsya otdeljnyij Markdown-fajl. Iskhodnyij tekst voprosa odnovremenno sokhranyayetsya v `запрос.md` svyazannoj rabochej sessii, a fajl voprosa i otveta ssyilayetsya na etot istochnik.
- Voprosyi o vedenii repozitoriya i rabochej sessii, dokumentacii, redaktorakh i vizualizacii, sistemnyikh prilozheniyakh, instrumentakh, versiyakh ChatGPT ili Codex i inyiye sluzhebnyiye voprosyi v razdel ne vklyuchayutsya.
- Prosjba, komanda, predlozheniye vyipolnitj dejstviye i inoye nevoprositeljnoye vyiskazyivaniye ostayutsya toljko v `запрос.md` i svyazannyikh materialakh rabochej sessii. Proizvodnaya pereformulirovka ili zagolovok `## Вопрос` ne prevrasjhayut takoj zapros v vopros.
- Yesli vopros vyiyavlyayet protivorechiye, nepolnotu trebovanij ili trebuyet daljnejshego resheniya, on otnositsya k `Вопросы/`, a ne k etomu razdelu.
- Yesli fajl voprosa i otveta svyazan s rabochej sessiyej, yego imya po umolchaniyu povtoryayet vremennoj prefiks i korotkoye nazvaniye papki iskhodnogo zaprosa.
- Vnutri fajla sokhranyayutsya sam vopros, otvet i nizhniye spravochnyiye razdelyi s istochnikami trebovanij i opornyimi materialami.

## Poluavtomaticheskij audit pokryitiya

Lokaljnaya avtomatizaciya [fum-audit-pokryitiya-voprosov-i-otvetov](../Instrumentyi/fum-audit-pokryitiya-voprosov-i-otvetov/SKILL.md) izvlekayet voprositeljnyiye predlozheniya iz doslovnyikh blokov `## Текст запроса`, sopostavlyayet ikh so ssyilkami razdelov `## Источники требований` susjhestvuyusjhikh kartochek i vyivodit kandidatyi s tochnyimi koordinatami. Audit zapuskayetsya bez seti i nichego ne menyayet:

```bash
python3 Инструменты/fum-audit-pokryitiya-voprosov-i-otvetov/scripts/audit-question-answer-coverage.py --repo-root .
```

V otchyot vkhodyat i pokryityiye, i nepokryityiye voprosyi. Ssyilka kartochki podtverzhdayet toljko svyazj s iskhodnyim zaprosom; ona ne dokazyivayet otnosheniye konkretnogo voprosa k susjhnosti FUM, soderzhateljnostj otveta ili samostoyateljnuyu poleznostj. Eti tri resheniya vsegda proveryayutsya vruchnuyu.

## Materialyi

- [Chto takoye FUM](2026-08-03_17-01-51_MSK_zakrepitj-sistemnoye-ustraneniye-nedorabotok.md) - kratkoye raskryitiye nazvaniya FUM, yego agentskogo naznacheniya i fraktaljnogo principa organizacii myishleniya.
- [Kak razreshatj konflikt avtonomii poduzla i ustojchivosti sostavnogo uzla](2026-06-22_08-14-25_MSK_konflikt-avtonomii-i-ustojchivosti-FUM.md) - obsjhij princip otbora zhiznesposobnyikh variantov koordinacii bez opravdaniya totaljnoj vlasti nad poduzlom.
- [Kak razlichatj issledovateljskiye statusyi FUM](2026-06-22_08-22-06_MSK_razlicheniye-issledovateljskikh-statusov-FUM.md) - granicyi mezhdu gipotezoj, siljnyim predpolozheniyem, vosproizvedyonnyim rezuljtatom i otkryitiyem.
- [Kak sootnosyatsya strukturiruyusjhiye operatoryi i interfejs FUM-uzla](2026-07-10_05-38-47_MSK_otvetitj-o-svyazi-operatorov-i-interfejsa-FUM-uzla.md) - operatornyij graf kak vnutrennij strukturnyij sloj i interfejs kak granica yego predyyavleniya i obratnogo dejstviya.

Formaljnyij voprositeljnyij priznak sam po sebe nedostatochen: posle otbora doslovnyikh voprosov kazhdyij kandidat prokhodit smyislovuyu proverku na pryamoye otnosheniye k susjhnosti FUM. Poetomu sluzhebnyiye voprosyi o shirine Mermaid-skhem v Obsidian i uchyote versij ChatGPT ili Codex ne vkhodyat v perechenj.

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-22 10:02:43 MSK - Dobavitj audit pokryitiya voprosov i otvetov](../Zhurnal/2026-07-22_10-02-43_MSK_dobavitj-audit-pokryitiya-voprosov-i-otvetov/zapros.md)
- [iskhodnyij zapros 2026-07-10 05:51:44 MSK - Sozdatj papku voprosov i otvetov](../Zhurnal/2026-07-10_05-51-44_MSK_sozdatj-papku-voprosov-i-otvetov/zapros.md)
- [iskhodnyij zapros 2026-06-22 08:14:25 MSK](../Zhurnal/2026-06-22_08-14-25_MSK/zapros.md)
- [iskhodnyij zapros 2026-06-22 08:22:06 MSK](../Zhurnal/2026-06-22_08-22-06_MSK/zapros.md)
- [iskhodnyij zapros 2026-07-10 05:38:47 MSK - Otvetitj o svyazi operatorov i interfejsa FUM-uzla](../Zhurnal/2026-07-10_05-38-47_MSK_otvetitj-o-svyazi-operatorov-i-interfejsa-FUM-uzla/zapros.md)
- [iskhodnyij zapros 2026-07-10 06:28:42 MSK - Ispravitj klassifikaciyu zaprosa](../Zhurnal/2026-07-10_06-28-42_MSK_ispravitj-klassifikaciyu-zaprosa/zapros.md)
- [iskhodnyij zapros 2026-07-10 06:46:29 MSK - Dopolnitj voprosyi i otvetyi po vsem zaprosam](../Zhurnal/2026-07-10_06-46-29_MSK_dopolnitj-voprosyi-i-otvetyi-po-vsem-zaprosam/zapros.md)
- [iskhodnyij zapros 2026-07-13 15:20:42 MSK - Ogranichitj voprosyi i otvetyi susjhnostjyu FUM](../Zhurnal/2026-07-13_15-20-42_MSK_ogranichitj-voprosyi-i-otvetyi-susjhnostjyu-FUM/zapros.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 17:18:11 MSK -->
<!-- content-sha256: sha256:90a546a33e8e282ffcbb4fa38f1baf22271b0f17e6bcef5c9d80b62b9feb0262 -->
<!-- FUM-MD-RECENCY:END -->
