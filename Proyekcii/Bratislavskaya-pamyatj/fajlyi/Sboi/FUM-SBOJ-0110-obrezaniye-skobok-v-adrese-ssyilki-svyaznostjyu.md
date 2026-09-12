+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0110"
"статус" = "активна"
+++
# Obrezaniye skobok v adrese ssyilki svyaznostjyu

## Nablyudayemyij sboj

Proverka svyaznosti otklonila susjhestvuyusjhij fajl istochnika v kataloge `install()`: polnyij otnositeljnyij adres v avtomaticheski sozdannom indekse svezhesti obrezan do `install(`. Tot zhe razbor zatronul ssyilki pasporta i zaprosa i porodil neozhidannyij putj Git-sostoyaniya.

## Granica povtoreniya

Odna regressionnaya granica — polnyij razbor Markdown destination so sbalansirovannyimi kruglyimi skobkami v puti. Eto ne uglovyiye ssyilki planovogo reyestra iz FUM-SBOJ-0004 i ne ssyilki vnutri strochnogo koda iz FUM-SBOJ-0005. Neskoljko soobsjhenij odnogo sostavnogo zapuska schitayutsya odnim proyavleniyem.

## Proyavleniya

### FUM-SBOJ-0110/PROYAVLENIYE-0001

12 sentyabrya 2026 goda, pervyij planovyij srez 0216. Zapusk `f2ecb388-db41-43c3-b6b1-3224edc82990`, poryadok 2, zavershilsya kodom 1 za 321,6842435 s. [Mashinnaya zapisj](../Zhurnal/2026-09-12_03-28-44_MSK_podgotovitj-pasport-macOS-VM/materialyi/zapuski-proverok/2_f2ecb388-db41-43c3-b6b1-3224edc82990.json) podtverzhdayet iskhod i vremya, a [nablyudeniye vyivoda](../Zhurnal/2026-09-12_03-28-44_MSK_podgotovitj-pasport-macOS-VM/materialyi/svideteljstva/svyaznostj-skobki.txt) sokhranyayet tochnuyu diagnosticheskuyu stroku. Effekt — otkaz adresnoj priyomki. Sderzhivaniye: sobstvennoye novoye nablyudeniye sokhraneno kak txt, lokaljnyiye ssyilki ispoljzuyut `%28%29`; parser ne menyalsya. Povtornaya proverka uchityivayetsya otdeljno v otchyote.

## Ozhidaniye i klassifikaciya

Susjhestvuyusjhij istochnik i ssyilki, postroyennyiye shtatnyim generatorom, dolzhnyi soglasovanno razreshatjsya proverkoj svyaznosti. Eto nablyudyonnaya nedorabotka proveryayusjhego kontura; sam po sebe bukvaljnyij sbalansirovannyij adres `install()` ne dokazyivayet nevalidnyij Markdown. Otdeljnaya oshibka otsutstvovavshego LinguisticKit vosstanovlena shtatnyim init susjhestvuyusjhej zavisimosti i ne vklyuchena v mekhanizm skobok.

## Mekhanizm i sistemnoye ustraneniye

Na baze `01b329cb49f4c5a5655fab4c16d7ea3a3ebf55a5` recency vstavlyayet bukvaljnyij otnositeljnyij putj, a `MARKDOWN_LINK_RE` v module svyaznosti zavershayet destination na pervoj zakryivayusjhej skobke. Sistemnoye ustraneniye trebuyet razbiratj celyij dopustimyij adres pri sokhranenii zakryityikh proverok celi. Ogranichennyij obkhod dokumenta i uspeshnyij povtor ne zakryivayut etu kartochku.

## Svyazannyiye shagi

[FUM-STEP-0226 — Sokhranyatj skobki v adresakh ssyilok svyaznosti](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0226-sokhranyatj-skobki-v-adresakh-ssyilok-svyaznosti.md) vosproizvodit i ustranyayet FUM-SBOJ-0110/PROYAVLENIYE-0001. Realizaciya ne vklyuchena v konechnyij pasport 0216 i ne zapuskayetsya avtomaticheski.

## Kriterii zakryitiya

- Krasnaya fikstura vosproizvodit tochnuyu ssyilku s `install()` i obrezannuyu celj.
- Iskhodnaya ssyilka i forma `%28%29` razreshayutsya v odin susjhestvuyusjhij fajl, vklyuchaya rezuljtat recency.
- Sokhranyayutsya otkazyi dlya neizvestnogo, registronevernogo i vyikhodyasjhego za korenj puti; nevernyij sintaksis ne poluchayet molchalivogo dopuska.
- Adresnyiye regressii, sorazmernyij profilj i primenimaya priyomka podtverzhdayut izmeneniye; svyazannyij shag zavershyon s dokazateljstvom.

## Istochniki

- [Pervichnyij zapros](../Zhurnal/2026-09-12_03-28-44_MSK_podgotovitj-pasport-macOS-VM/zapros.md) i [otchyot](../Zhurnal/2026-09-12_03-28-44_MSK_podgotovitj-pasport-macOS-VM/otchyot.md).
- [Proverka svyaznosti](../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py), `MARKDOWN_LINK_RE`, baza `01b329cb49f4c5a5655fab4c16d7ea3a3ebf55a5`.
- [Generator svezhesti](../Instrumentyi/fum-svezhestj-markdown/scripts/update-md-recency.py), `render_index_body`, ta zhe baza.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:01:10 MSK -->
<!-- content-sha256: sha256:f11ed2d10bc0029c7fdffc9de55242dce3e920b859a550dd40fedcedb0700875 -->
<!-- FUM-MD-RECENCY:END -->
