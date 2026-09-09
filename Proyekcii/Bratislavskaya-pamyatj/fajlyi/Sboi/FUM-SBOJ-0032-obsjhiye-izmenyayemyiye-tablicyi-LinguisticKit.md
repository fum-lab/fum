+++
"версия_схемы" = 1
"идентификатор_сбоя" = "FUM-СБОЙ-0032"
"статус" = "устранена"
+++
# Obsjhiye izmenyayemyiye tablicyi LinguisticKit ne podderzhivayut Swift 6

Granica ustraneniya — proverennyij variant LinguisticKit v dochernej vetke forka. Zakreplyonnaya zavisimostj FUM i originaljnaya vetka upstream etoj zapisjyu ne obnovlyayutsya.

## Nablyudayemyij sboj

Iskhodnyij upstream f26d46c99367bb1eef37c50906d2691ef36ca4d2 obyyavlyayet tools 6.0, no yego shtatnaya sborka v rezhime Swift 6 otvergayet obsjhiye tablicyi, perechisleniya i reyestr preobrazovanij bez Sendable. ScriptTable soderzhit lenivyiye svojstva i izmenyayemyij slovarj maksimaljnyikh dlin; odnoj annotacii byilo byi nedostatochno.

## Granica povtoreniya

Odnovremennoye ispoljzovaniye opublikovannogo ekzemplyara tablicyi do podgotovki keshej i kompilyaciya iskhodnogo paketa s polnoj proverkoj Concurrency. Oshibka ustanovsjhika CI i testovyij import ekstraktora otnosyatsya k drugim mekhanizmam.

## Proyavleniya

| Lokaljnyij nomer               | Istochnik i dokazateljstvo                                                                                       | Effekt                                           | Vosstanovleniye                                                                          |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ | --------------------------------------------------------------------------------------- |
| FUM-SBOJ-0032/PROYAVLENIYE-0001 | [Pryamyiye zapuski 1 i 3](../Zhurnal/2026-09-08_22-21-18_MSK_obnovitj-LinguisticKit-dlya-Swift-Concurrency/otchyot.md) | Paket ne sobirayetsya v zayavlennom rezhime Swift 6. | Do publikacii tablicyi sformirovatj neizmenyayemyiye indeksyi i podtverditj checked Sendable. |

## Mekhanizm i ogranichennoye vosstanovleniye

ScriptTable stal final-klassom s neizmenyayemyim grafom khranimyikh znachenij. Indeksyi, naboryi bukv i dlinyi elementov polnostjyu stroyatsya v init. Publichnyiye perechisleniya i vnutrenniye opisateli preobrazovanij takzhe poluchayut proveryayemyij Sendable. Blokirovok, globaljnogo aktora, unchecked Sendable i nebezopasnogo otklyucheniya diagnostiki net.

## Kriterii zakryitiya

- Strogaya kompilyaciya Swift 6 bez preduprezhdenij.
- Paralleljnoye pervoye obrasjheniye k svezhej tablice i sovmestnoye ispoljzovaniye publichnyikh tablic prokhodyat testyi i Thread Sanitizer.
- Vse prezhniye testyi prokhodyat, vyikhod predstaviteljnogo russkogo korpusa sovpadayet pobajtno.
- Stoimostj nachaljnoj podgotovki i povtornyikh vyizovov izmerena i obosnovana.

## Podtverzhdeniye ustraneniya

[Kommit biblioteki b868465](https://github.com/fum-lab/LinguisticKit/commit/b8684654b2a16b04852b5b4cb0ec29e23c354939) prokhodit 32 prezhnikh i 3 novyikh testa; posledniye takzhe proshli Thread Sanitizer. [Sravniteljnyij profilj](../Zhurnal/2026-09-08_22-21-18_MSK_obnovitj-LinguisticKit-dlya-Swift-Concurrency/materialyi/profili/sravneniye.json) sokhranyayet 7 iskhodnyikh i 7 novyikh zapuskov s tochnyim korpusom. Dopolniteljnaya stoimostj podgotovki prinyata; uskoreniye povtornogo puti ne zayavleno.

## Istochniki

- [Iskhodnyij zapros](../Zhurnal/2026-09-08_22-21-18_MSK_obnovitj-LinguisticKit-dlya-Swift-Concurrency/zapros.md).
- [Otchyot i mashinnyiye zapisi](../Zhurnal/2026-09-08_22-21-18_MSK_obnovitj-LinguisticKit-dlya-Swift-Concurrency/otchyot.md).


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-08 23:05:31 MSK -->
<!-- content-sha256: sha256:1dea458bcb0c8820e98e6dbf68e671328620e74da7ff93142495c7c1f9dc7fb0 -->
<!-- FUM-MD-RECENCY:END -->
