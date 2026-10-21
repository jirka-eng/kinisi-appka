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

## Označování fotek: `oznacovani.html`
Nástroj pro terapeuty, ze kterých vznikají data na učení modelu. Otevři
https://jirka-eng.github.io/kinisi-appka/chodidla/oznacovani.html a vyber složku s fotkami. Fotky zůstávají v počítači
a nikam se neposílají.

1. U každé fotky vyber druh záběru: `Z` zezadu, `O` otisk, `B` z boku, `N` nepoužitelná. Když označíš zadní snímek,
   druhá kamera ze stejné vteřiny se sama označí jako otisk a při listování se přeskočí.
2. U zadního snímku vyber polohu (`1`–`6`) a naklikej 4 body na každé noze: střed lýtka, střed Achillovky ve výšce
   kotníků, střed paty nahoře a střed paty dole. Nástroj hned ukáže úhel paty (+ znamená vbočená, − vybočená).
3. Doplň, jak patu a Achillovku vidíš ty. Model se učí z tvého úsudku, ne z vypočteného čísla.
4. U složky (dítěte) vyplň věk.
5. Průběžně ukládej tlačítkem **Uložit popisky do souboru** a soubor dej na sdílený Disk. Popisky se drží jen
   v prohlížeči daného počítače. Na jiném počítači je načteš tlačítkem **Načíst popisky**.

Rozdělte si složky tak, aby dva lidé nepopisovali stejné fotky. Při načtení se pozdější popisek přepíše.

Hranice „v rozmezí / mírně / výrazně“ (5° a 10°) jsou zatím jen orientační. Doladí je terapeuti podle věku.

## Pravidla
- **Fotky ani soubory s popisky do repa nedávej.** Repo je veřejné a jsou to zdravotní údaje dětí (na otiscích jsou
  navíc vidět obličeje). Patří na sdílený Disk.
- Ke každému dítěti je potřeba souhlas rodiče s použitím fotek pro vývoj.
