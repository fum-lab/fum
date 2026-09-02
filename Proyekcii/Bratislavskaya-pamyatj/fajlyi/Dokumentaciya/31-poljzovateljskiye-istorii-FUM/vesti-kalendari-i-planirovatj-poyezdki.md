# Istoriya: kalendarj, raspisaniye i poyezdki cherez FUM

Lichnyij [FUM-agent](../../Glossarij/lichnyij-FUM-agent.md) dolzhen pomogatj cheloveku vesti kalendarj, soglasovyivatj raspisaniye, planirovatj poyezdki, vyizyivatj taksi i rabotatj s drugimi servisami peremesjheniya kak s chastjyu yedinoj zhiznennoj sredyi. Poljzovatelj vyirazhayet namereniye odin raz, a FUM svyazyivayet vremya, mesto, uchastnikov, ogranicheniya, podtverzhdeniya, servisnyiye dejstviya i itogovyij sled v [pamyati FUM](../../Glossarij/pamyatj-FUM.md).

Takaya istoriya vazhna tem, chto vyivodit FUM iz rezhima rabotyi toljko s dokumentami i fajlami v rezhim byitovogo koordiniruyusjhego agenta. Kalendarj i poyezdka trebuyut ne toljko teksta otveta, no i aktualjnogo sostoyaniya, vneshnikh servisnyikh adapterov, akkuratnoj rabotyi s privatnyimi dannyimi, yavnogo podtverzhdeniya dejstvij i vozmozhnosti otmenyi ili vosstanovleniya posle oshibki.

## Poljzovateljskaya istoriya

Poljzovatelj s lichnyim FUM-agentom khochet skazatj: "zaplaniruj vstrechu, uchti dorogu, vyizovi taksi vovremya i predupredi menya, yesli raspisaniye konfliktuyet", chtobyi ne sobiratj odin zhiznennyij scenarij vruchnuyu iz kalendarya, kart, messendzherov, taksi i pamyati proshlyikh dogovoryonnostej.

FUM dolzhen ponimatj celj poljzovatelya, proveritj kalendarj i raspisaniye, predlozhitj variantyi vremeni i marshruta, vyiyavitj konfliktyi, pokazatj stoimostj i riski vneshnikh dejstvij, zaprositj podtverzhdeniye pered zakazom taksi ili drugoj platnoj operaciyej, vyipolnitj podtverzhdyonnoye dejstviye cherez servisnyij adapter i sokhranitj trassu rezuljtata.

## Osnovnoj scenarij

1. Poljzovatelj formuliruyet namereniye: sobyitiye, vremya ili diapazon, mesto, uchastnikov, ogranicheniya po doroge i predpochteniya transporta.
2. FUM chitayet dostupnyij kalendarj, raspisaniye i svyazannyiye zametki v ramkakh razreshyonnyikh urovnej dostupa.
3. FUM stroit variantyi: vremya sobyitiya, napominaniya, vremya vyikhoda, marshrut, zapas na dorogu, sposob peremesjheniya i zavisimyiye dejstviya.
4. FUM pokazyivayet poljzovatelyu konfliktuyusjhiye sobyitiya, neopredelyonnosti, cenu ili vneshnij risk, yesli dejstviye zatragivayet servis taksi, biletyi, oplatu, geolokaciyu ili peredachu dannyikh tretjyej storone.
5. Poljzovatelj podtverzhdayet konkretnyij variant ili ogranichivayet avtonomiyu FUM.
6. FUM zapisyivayet sobyitiye, sozdayot napominaniya, vyizyivayet nuzhnyij servisnyij adapter, sokhranyayet podtverzhdeniye, rezuljtat i oshibki v pamyati.
7. Pri izmenenii uslovij FUM soobsjhayet o konflikte, predlagayet perestroitj raspisaniye ili otmenitj vneshneye dejstviye.

## Aljternativyi i otkazyi

- Yesli u FUM net dostupa k kalendaryu ili servisu poyezdki, on pokazyivayet nedostupnuyu chastj scenariya i predlagayet ruchnoj shag bez imitacii vyipolnennogo dejstviya.
- Yesli servisnyij adapter vozvrasjhayet oshibku, FUM sokhranyayet yeyo v trasse i predlagayet vosstanovimyij variant: povtoritj, vyibratj drugoj servis, perejti k ruchnomu dejstviyu ili otmenitj plan.
- Yesli dejstviye trebuyet oplatyi, peredachi mestopolozheniya, dostupa k kontaktam, bronirovaniya ili fizicheskogo peremesjheniya cheloveka, FUM ne vyipolnyayet yego bez yavnogo podtverzhdeniya libo zaraneye zadannoj i proveryayemoj politiki avtonomii.
- Yesli raspisaniye konfliktuyet s privatnyim ili nedostupnyim sobyitiyem, FUM dolzhen pokazatj sam fakt konflikta bez raskryitiya skryitogo soderzhaniya za predelami razreshyonnogo dostupa.

## Kriterii priyomki

- Poljzovatelj mozhet opisatj kalendarno-transportnoye namereniye v odnom konture, ne vyibiraya vruchnuyu kazhdoye prilozheniye.
- FUM razlichayet lokaljnyiye dejstviya planirovaniya i vneshniye dejstviya cherez servisyi taksi, marshrutov, biletov ili raspisanij.
- Pered platnyim, privatnyim ili fizicheski znachimyim dejstviyem FUM pokazyivayet posledstviya i poluchayet podtverzhdeniye.
- V pamyati sokhranyayutsya iskhodnoye namereniye, ispoljzovannyiye istochniki, vyibrannyij variant, podtverzhdeniye, vyizvannyij adapter, rezuljtat i otkaznyiye rezhimyi.
- Scenarij mozhno proveritj snachala na fiksturakh ili simulyatore bez realjnogo zakaza taksi, platezhej i peredachi privatnogo mestopolozheniya.

## Status

Istoriya zafiksirovana kak celevoj poljzovateljskij scenarij dlya budusjhego interfejsa i servisnyikh adapterov FUM. [Zontichnyij pasport kalendarno-transportnogo servisnogo kontura](../42-pasport-kalendarno-transportnogo-servisnogo-kontura-lichnogo-FUM-agenta.md) zadayot proveryayemuyu modeljnuyu versiyu `R0` s sinteticheskimi fiksturami i simulyatorom bez vneshnego effekta. Realjnaya realizaciya po-prezhnemu trebuyet otdeljnyikh pasportov adapterov kalendarya, raspisanij, kart, taksi, biletov i uvedomlenij, a takzhe daljnejshego proyasneniya granic avtonomii v [chastichno proyasnyonnom voprose o kalendarno-transportnyikh dejstviyakh FUM](../../Voprosyi/2026-07-03_09-03-59_MSK_granicyi-kalendarno-transportnyikh-dejstvij-FUM.md).

## Istochniki trebovanij

- [iskhodnyij zapros 2026-07-03 09:03:59 MSK - Opisatj kalendarno transportnyiye dejstviya FUM](../../Zhurnal/2026-07-03_09-03-59_MSK_opisatj-kalendarno-transportnyiye-dejstviya-FUM/zapros.md)

## Opornyiye dokumentyi

- [FUM kak yedinaya tochka vzaimodejstviya s kompjyuterom](../19-yedinaya-tochka-vzaimodejstviya-s-kompjyuterom.md)
- [Pasport kalendarno-transportnogo servisnogo kontura lichnogo FUM-agenta](../42-pasport-kalendarno-transportnogo-servisnogo-kontura-lichnogo-FUM-agenta.md)
- [Interfejs FUM-uzla](../25-interfejs-FUM-uzla.md)
- [Vosproizvodimyiye avtomatizacii FUM](../17-vosproizvodimyiye-avtomatizacii.md)
- [Planovoye napravleniye interfejsa i servisnyikh adapterov](../../Planirovaniye/napravleniya-proyektirovaniya-i-razvitiya/05-interfejs-i-servisnyiye-adapteryi.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:c2eab47031570e7e8baca6d14facb9a366c88831f62df4470574098a391f572b -->
<!-- FUM-MD-RECENCY:END -->
