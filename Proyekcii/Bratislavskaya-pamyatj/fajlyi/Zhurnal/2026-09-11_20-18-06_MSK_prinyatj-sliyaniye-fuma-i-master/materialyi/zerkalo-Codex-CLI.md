# Zerkalo i oflajn-sborka Codex CLI

Po [utochneniyu 243](../zapros.md) sozdano publichnoye zerkalo [fum-lab/codex](https://github.com/fum-lab/codex). GitHub podtverdil fork i parent/source openai/codex. Nezavisimyiye Git-chteniya main oboikh repozitoriyev dali `33bdf976ccd1130823d4fe041e4d5075ab511d67`. Eto proverennyij snimok main, a ne utverzhdeniye o stabiljnom relize. Lokaljnyiye clone, gitlink, ustanovka i sborka zdesj ne vyipolnyalisj.

## Sostav vosproizvodimogo komplekta

Provereno po oficialjnomu iskhodnomu snimku 11 sentyabrya 2026 goda.

- Rust 1.95.0, vyibrannyij target i komponentyi toolchain; iskhodniki, Cargo.toml, Cargo.lock i konfiguraciya Cargo; dostupnyiye bez seti arkhivyi crates s kontroljnyimi summami; C/C++ kompilyator, linker i primenimyij SDK. Lockfile vklyuchayet shestj Git-istochnikov: microsoft/mxc, helix-editor/nucleo, dzbarsky/rules_rust, openai-oss-forks/crossterm, tokio-tungstenite i tungstenite-rs. Zerkaliruyutsya tochnyiye polnyiye revizii lockfile i neobkhodimyiye vlozhennyiye zavisimosti. [Rust toolchain](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/codex-rs/rust-toolchain.toml), [Cargo.lock](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/codex-rs/Cargo.lock), [Cargo.toml](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/codex-rs/Cargo.toml).
- Odinochnyij binarnik codex i polnyij reliz imeyut raznyiye granicyi. Polnaya postavka dopolniteljno soderzhit codex-code-mode-host, proxy i platformennyiye helpers. Dlya workspace/release-profilya susjhestvenen V8 150.4.0: Cargo obyichno poluchayet native-arkhivyi, poetomu nuzhnyi zakreplyonnyiye arkhivyi, bindings i checksum manifest. Iskhodnaya sborka ispoljzuyet otdeljnyij Bazel-graf, V8 15.0.245.2, zakreplyonnyiye libc++, libc++abi i llvm-libc i ostaljnyiye vkhodyi MODULE.bazel/lock. Sokhranyonnyij gotovyij binarnik ne yavlyayetsya svideteljstvom sborki V8 iz iskhodnikov. [Sostav reliza](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/.github/workflows/rust-release.yml), [kontrakt V8](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/third_party/v8/README.md).
- npm launcher zapuskayet podgotovlennyij Rust-binarnik. Dlya obyichnoj dokumentirovannoj Cargo-sborki JS-paketyi ne obyazateljnyi; npm-upakovka otdeljno trebuyet zakreplyonnyikh Node/npm, pnpm 10.34.5, pnpm-lock.yaml i platformennyikh payload. Kornevyim JS-instrumentam nuzhen Node ne nizhe 22, launcher — ne nizhe 16. Matrica upakovki: macOS, Linux musl i Windows MSVC dlya arm64/x64. [Instrukciya sborki](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/docs/install.md), [package.json](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/package.json), [upakovsjhik](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/codex-cli/scripts/build_npm_package.py).

## Licenzii i granicyi avtonomnosti

Codex sokhranyayet Apache-2.0. V postavke sokhranyayutsya LICENSE, NOTICE, primenimyiye uvedomleniya i svedeniya ob izmeneniyakh. NOTICE otdeljno ukazyivayet proiskhozhdeniye iz Ratatui pod MIT. CC0 sobstvennogo koda FUM ne izmenyayet licenzii vneshnikh komponentov. Polnyij licenzionnyij sostav proveryayetsya dlya vyibrannogo profilya. [LICENSE](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/LICENSE), [NOTICE](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/NOTICE).

Priyomka avtomatizacii: zakreplyonnyij komplekt, sborka s zamorozhennyim lockfile i fakticheski zapresjhyonnoj setjyu, proverka vyibrannyikh vozmozhnostej, khyeshi rezuljtatov i profilj vremeni, pamyati i diska. Pobitovaya vosproizvodimostj proveryayetsya otdeljno i poka ne dokazana.

Dostupnostj modeli takzhe proveryayetsya otdeljno. Oblachnomu backend nuzhen servis; lokaljnyiye Ollama ili LM Studio trebuyut sobstvennogo runtime i zaraneye dostupnoj modeli. Zerkalo CLI ne predostavlyayet eti dannyiye avtomaticheski. [Obrabotka lokaljnyikh provajderov](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/codex-rs/utils/oss/src/lib.rs).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 22:03:48 MSK -->
<!-- content-sha256: sha256:2b69813ef3468e5198cfcedbe145f23d59ede75c04dc5b4bc7edd197fb0ba458 -->
<!-- FUM-MD-RECENCY:END -->
