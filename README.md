# Bibliaút – natív iOS app (SwiftUI)

A webes Bibliaút artifact natív iPhone/iPad-portja. Ugyanaz a tartalom (6 szakasz, 60 állomás,
600 kérdés, 8 képes kérdés, 8 ajándékkártya), ugyanaz az alapjátékmenet, plusz néhány natív extra:

- ösvény állomásokkal, kincsesládákkal (5. és 10. állomás után), szakaszonkénti feloldással;
  a ládák rajzolt fa-ládák, kinyitás után nyitva maradnak
- 5 szív, 5 percenként regenerálódik (globálisan, nem leckénként)
- **hibajavító kör**: a lecke végén a rosszul megválaszolt kérdések újra jönnek, amíg mind jó nem
  lesz – csak utána zárul az állomás
- **csillagok**: hibátlan első kör = 3 csillag (tele sárga), ≥70 % = 2 (fél sárga), alatta 1 (fehér
  körvonal); az ösvényen a teljesített állomás közepén a legjobb eredmény csillaga látszik
- 10 XP / első próbálkozásra helyes válasz + 5 XP állomás-bónusz, szintek (Újonc → Bibliatudós)
- **talentum**: minden teljesített állomás 5 talentumot ad, 5-ös helyes sorozatnál ×1,5, 10-esnél ×2
  (5 / 8 / 10); a ládák egy koppintásra 20-at adnak; a Gyűjtemény fülön 50 talentumért vásárolhatók
  az ajándékkártyák
- **Statisztika** fül: szint, sorozat, heti/összes lecke, havi naptár (arany = tanult nap,
  jégkék ❄ = kihagyott „befagyasztott” nap, karika = ma)
- **Menü** (színes „•••” gomb): Profil (név), Nyelv (HU/EN), + 2 szabad hely későbbi funkcióknak
- napi sorozat (streak), világos + sötét mód, haptikus visszajelzés
- SF Symbols ikonok (láng, nyitott könyv, szív, kereszttel vert talentum-érme, láda, kereszt az app-ikonon)

## Megnyitás és futtatás

Követelmény: **Xcode 16 vagy újabb** (macOS), iOS 17+ eszköz vagy szimulátor.

1. Másold át a `Bibliaut-iOS` mappát a Mac-re.
2. Nyisd meg a `Bibliaut.xcodeproj`-t.
3. Signing & Capabilities → válaszd ki a saját Team-edet (Apple ID elég a saját telefonra telepítéshez).
4. Válassz egy iPhone/iPad szimulátort vagy a csatlakoztatott eszközt, majd ⌘R.

A projekt „file system synchronized” csoportot használ, ezért a `Bibliaut/` mappában lévő minden
fájl automatikusan a targethez tartozik – új fájlt elég a mappába tenni.

### Tesztelés saját iPhone-on / iPad-en

**A) Van Mac (ez a normál út):** kábellel csatlakoztasd az eszközt, Xcode-ban válaszd ki
futtatási célnak, ⌘R. Ingyenes Apple ID-vel az app 7 napig fut, utána újra kell telepíteni
Xcode-ból; fizetős fejlesztői fiókkal (99 USD/év) 1 évig, és TestFlight-tal másoknak is kiküldhető.
Az eszközön először engedélyezni kell: Beállítások → Adatvédelem és biztonság → Fejlesztői mód,
illetve Beállítások → Általános → VPN és eszközkezelés → a fejlesztői tanúsítvány megbízhatóvá tétele.

**B) Nincs Mac:** iOS-appot csak macOS-en lehet lefordítani, ezért két reális lehetőség van:
- felhő-Mac bérlése óradíjban (pl. MacinCloud, MacStadium) és ott az A) lépések;
- a repó **GitHub Actions** workflow-ja (`.github/workflows/ios-build.yml`) minden `main`-re
  pusholt commitnál macOS-futtatón lefordítja az appot, és feltölt egy aláíratlan
  `Bibliaut-unsigned.ipa` artifactot (Actions fül → legutóbbi futás → Artifacts). Ezt Windowsról
  **Sideloadly** vagy **AltStore** programmal (ingyenes Apple ID-vel) lehet a telefonra tenni –
  ez is 7 naponta újra aláírást kér.

Mentések: a haladás `UserDefaults`-ban van (`bq-*` kulcsok), az app törlésével elvész; újratelepítés
(frissítés) megtartja.

## Fájlok

| Fájl | Mi van benne |
|---|---|
| `Bibliaut/BibliautApp.swift` | belépési pont + `RootView` (képernyőváltás: fő / lecke / eredmény / láda) |
| `Bibliaut/Theme.swift` | színpaletta (light/dark), betűk, közös gombok, `TalentCoin`, rajzolt `ChestView`, `StationStar` |
| `Bibliaut/Models/Content.swift` | `Codable` modellek, `content.json` betöltése |
| `Bibliaut/Models/GameStore.swift` | játéklogika + mentés `UserDefaults`-ba (`bq-*` kulcsok, mint a weben) |
| `Bibliaut/Models/Strings.swift` | HU/EN UI-szövegek |
| `Bibliaut/Views/HomeView.swift` | `MainView` (fülek + alsó sáv), ösvény, chipek, menü- és profil-lap |
| `Bibliaut/Views/CollectionView.swift` | talentum-egyenleg, vásárolható ajándékkártyák |
| `Bibliaut/Views/StatsView.swift` | statisztika-csempék, havi naptár |
| `Bibliaut/Views/LessonView.swift` | kérdés-képernyő (szöveges és képes válaszok) |
| `Bibliaut/Views/ResultView.swift` | eredmény- és láda-jutalom-képernyő |
| `Bibliaut/Views/IconView.swift` | a képes kérdések ikonjai – a webes SVG-k natív `Path`/`Canvas` rajzolása |
| `Bibliaut/Resources/content.json` | a teljes tananyag, a webes verzióból gépileg exportálva |
| `Bibliaut/Assets.xcassets/AppIcon.appiconset/AppIcon.png` | 1024×1024 app-ikon (bordó háttér, arany ösvény, kereszt) |

## Mentett kulcsok (UserDefaults)

`bq-lang`, `bq-name`, `bq-xp`, `bq-talents`, `bq-progress`, `bq-stars` (legjobb csillag állomásonként), `bq-heart-losses`, `bq-streak`,
`bq-laststudy`, `bq-chests`, `bq-gift-log` (megvett kártyák), `bq-daily` (napi leckeszám),
`bq-first-study`.

## Megjegyzések

- A tartalom nem lett kézzel átgépelve: a webes artifact adatszekciójából script exportálta
  JSON-ba, így a 600 kérdés szó szerint azonos.
- A kód Windows-on készült, Xcode nélkül; a GitHub Actions build (Xcode 16.4, iOS 18 SDK)
  hiba és warning nélkül lefordítja.
- Ismert szépséghiba: sötét módban a „Holló” képes válasz nagyon sötét (`#2B2B2B`) ikonja alig látszik
  a kártyán – ugyanez a weben is így van, a színt a `content.json`-ban lehet módosítani.
- Az app-ikont a `make-icon.ps1` (GDI+) script rajzolta; ha más kell, egy tetszőleges 1024×1024 PNG-t
  kell `AppIcon.png` néven a mappába tenni.
