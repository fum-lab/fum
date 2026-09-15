+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0137"
"статус" = "устранена"
+++
# Nestrogaya versiya ssyilki poyasnenij

## Nablyudayemyij sboj

V novoj yavno vyibirayemoj peredache poyasnenij ssyilka profilya prinimala versii `true` i `1.0` kak celuyu `1`. Oshibka zatragivala podtverzhdeniye polnoj formyi i vosstanovleniye ssyilochnoj formyi. Prezhnij format po umolchaniyu ne ispoljzuyet etot protokol.

## Granica povtoreniya

Sravneniye obyyekta ssyilki s ozhidayemyim slovaryom Python bez otdeljnoj proverki tochnogo tipa versii. Drejf imyon i snimka obyyavlenij 0045 imeyet druguyu granicu i syuda ne vklyuchyon.

## Proyavleniya

### FUM-SBOJ-0137/PROYAVLENIYE-0001

[RED 8](../Zhurnal/2026-09-15_06-33-09_MSK_vyinesti-povtoryayemyiye-poyasneniya-otveta/materialyi/zapuski-proverok/8_41662084-731a-4e9e-bce7-7be2282dac91.json) podtverdil otsutstviye ozhidayemogo ValueError dlya `true` i `1.0`. [GREEN 9](../Zhurnal/2026-09-15_06-33-09_MSK_vyinesti-povtoryayemyiye-poyasneniya-otveta/materialyi/zapuski-proverok/9_1c43c94a-b62d-4635-ac95-7d5254942e64.json) proshyol vse pyatj adresnyikh testov posle ispravleniya; otdeljnyij test vyizyivayet obe tochki dlya `True`, `1.0`, `999` i `None`. Nablyudeniye odno, s dvumya predstavleniyami nevernogo tipa.

## Ozhidaniye i klassifikaciya

Versiya ssyilki dolzhna byitj tochnyim celyim chislom 1, a ne znacheniyem, ravnyim yemu po pravilam Python. Podtverzhdena nedorabotka novoj realizacii. Nomer vyidelen koordinatorom 01a07d3d-d376-7ad2-aafc-67e4c25a67eb dlya sobyitiya `explanation-profile-version-python-equality-01a0930d`; korenj proyavleniya — 01a0930d-fb6a-7013-b600-5da1a75b79bd.

## Mekhanizm i sistemnoye ustraneniye

Obsjhij predikat `действительная_ссылка` proveryayet obyyekt, tochnyij tip `int` u versii i ravenstvo vsekh polej ozhidayemoj ssyilke. Obe tochki ispoljzuyut odin predikat posle proverki opredeleniya. Eto predotvrasjheniye nevernogo tipa na konechnoj granice ssyilki; ono ne yavlyayetsya obsjhej reviziyej vsekh chislovyikh kontraktov proyekta.

## Svyazannyiye shagi

- [FUM-STEP-0165](../Planirovaniye/kartochki-shagov/🟡-FUM-STEP-0165-sobiratj-rabochij-kontekst-zadachi.md) — ogranichennaya peredacha poyasnenij; osnovaniye svyazi FUM-SBOJ-0137/PROYAVLENIYE-0001. Polnyij shag ostayotsya aktivnyim.

## Kriterii zakryitiya

Obe tochki otklonyayut `True`, `1.0`, `999` i `None` v versii ssyilki, prinimayut izvestnuyu celuyu versiyu i sokhranyayut proverku khyesha, peredachi, obratimosti i polnoj rezervnoj formyi. Adresnyij regressionnyij test khranitsya vmeste s kodom.

## Podtverzhdeniye ustraneniya

Kriterij konechnoj granicyi proveren GREEN 9: pyatj testov, kod 0. Nezavisimyij read-only-razbor review_explanation_wire podtverdil ispoljzovaniye strogogo predikata v obeikh tochkakh; dopolniteljnyikh zapuskov on ne delal. Polnaya priyomka etapa i integraciya v master etoj zapisjyu ne utverzhdayutsya.

## Istochniki

- [Iskhodnyiye komandyi i rezerv](../Zhurnal/2026-09-15_06-33-09_MSK_vyinesti-povtoryayemyiye-poyasneniya-otveta/zapros.md).
- [Otchyot etapa](../Zhurnal/2026-09-15_06-33-09_MSK_vyinesti-povtoryayemyiye-poyasneniya-otveta/otchyot.md).
- [Kod](../Instrumentyi/fum-svyaznostj-rabochej-sessii/scripts/poyasneniya_otveta.py) i [regressii](../Instrumentyi/fum-svyaznostj-rabochej-sessii/tests/test_poyasneniya_otveta.py).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 12:56:44 MSK -->
<!-- content-sha256: sha256:f5e2028c2ca5c93c0c7778743ba3cbcdde20b68210c9c66fe42963403d70cece -->
<!-- FUM-MD-RECENCY:END -->
