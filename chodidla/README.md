# Scanner chodidla

Druhá funkce Fyzioscanneru: rodič doma vyfotí nebo natočí dítěti nohy od kolene dolů a appka řekne, jestli je
postavení paty v pořádku, co na noze nesedí a co má dítě cvičit.

## Záběry
- **Zezadu** (hlavní): dítě stojí na něčem vyvýšeném (schod, stolička), telefon je ve výšce pat, cca 1 m za ním.
  Polohy: stoj na obou, na jedné, výpad, špičky. Pohyb (špičky, výpad) se bude natáčet jako krátké video
  a appka si vybere správný okamžik.
- **Z boku** (výška podélné klenby): body doplníme, až budou fotky.

Doma podoskop nebude, otisk plosky tedy appka mít nebude.

## Proč vlastní model
Model postavy, který používá kontrola cvičení (MediaPipe Pose), na fotkách od kolene dolů nefunguje, protože
potřebuje vidět obličej a trup. Ověřeno na 330 fotkách z podoskopu Kinisi (říjen 2026): na zadních záběrech
nenašel nic použitelného. Proto se naučí vlastní malý model, který najde body na noze přímo v telefonu.

## Metodika: `metodika.html`
Jak zakreslit osu bérce a osu paty (4 body, každý jako půlení šířky nohy), jaké úhly počítáme (postavení paty
proti svislici a úhel bérec–pata), jak má vypadat správná fotka a normy podle věku se zdroji. Hranice v ní jsou
návrh a potvrdí je terapeuti.

## Kontrola návrhů: `oznacovani.html`
Claude na každém zadním snímku navrhne body a hodnocení paty, terapeuti návrh potvrdí nebo opraví. Z verdiktů
a oprav se upraví pravidla a naučí model.

1. Otevři https://jirka-eng.github.io/kinisi-appka/chodidla/oznacovani.html , vyber složku s fotkami a načti soubor
   s návrhy `navrhy-chodidel.json` (je na sdíleném Disku). Vyplň, kdo kontroluje. Fotky zůstávají v počítači.
2. U složky (dítěte) vyplň věk. Podle něj se počítá očekávané postavení paty.
3. U každé fotky: **Sedí osy?** Když ne, chyť bod a posuň ho. **Souhlasíš s hodnocením** levé a pravé nohy?
   Když ne, vyber, jak to vidíš ty. Když vše sedí, stačí **Enter**.
4. Nejdřív oba zkontrolujete stejných 30 fotek (označené „společná fotka“), každý zvlášť. Podle shody poznáme,
   jakou přesnost můžeme od appky chtít. Potom si rozdělte zbytek.
5. Průběžně ukládej tlačítkem **Uložit popisky do souboru** a soubor dej na sdílený Disk. Popisky se drží jen
   v prohlížeči daného počítače. Na jiném počítači je načteš tlačítkem **Načíst popisky**.

Fotky bez návrhu jde označit ručně: zvol záběr (`Z` / `O` / `B` / `N`), polohu (`1`–`6`) a naklikej 4 body.

## Pravidla
- **Fotky ani soubory s popisky do repa nedávej.** Repo je veřejné a jsou to zdravotní údaje dětí (na otiscích jsou
  navíc vidět obličeje). Patří na sdílený Disk.
- Ke každému dítěti je potřeba souhlas rodiče s použitím fotek pro vývoj.
