# Changelog

Alle wijzigingen per versie. Formaat: [Keep a Changelog](https://keepachangelog.com/nl/1.1.0/), versies: [semantic versioning](https://semver.org/lang/nl/).

## [Unreleased]

## [0.7.0] - 2026-11-21

### Toegevoegd
- Lokale git-server (`Pipeline.spec.source: local-git`): bare repositories in `~/.fcd/git`; de agent, de vastgelegde versies en de releases gebruiken alleen die. Geen push naar remote.
- Mensgate met de knop op het Dashboard (`QualityGate.spec.approval: dashboard-button`): bij de start (`Pipeline.spec.trigger: dashboard-button`: de agent draait alleen na de startknop, en alleen wat gemerged is) en vóór het releasen (de run wacht op "Release goedkeuren"; dicht na `FCD_APPROVAL_TIMEOUT` seconden). De naam van wie drukt staat in de logregel.
- `fcd demo reset [--save]`: bewaart desgewenst de run en het statusrapport, zet de lokale git terug naar `demo-start` (de klaarstaande branches weer terug, nieuwere tags weg), start een lege log (nieuw experiment), rolt de start opnieuw uit en zet de reset als logregel in de log. Ook via de knop "Demo opnieuw" op het Dashboard.
- `fcd demo diff [branch]` en `fcd demo merge [branch]`: de klaarstaande wijziging laten zien en lokaal mergen, met de naam van de goedkeurder; ook via de knop "Patch mergen" op het Dashboard. De merge komt als logregel in de log (`fcd-demo.merged`).
- De reset rolt de start uit via de Pipeline zelf (alleen de Pipeline rolt uit): live op het Dashboard, met de stappen tot en met de end-to-end test. De reset-logregel noemt de klaarstaande wijzigingen.
- De startknop zonder iets nieuws op `main` zegt welke klaarstaande wijziging nog gemerged moet worden.
- `fcd report` (en "Demo opnieuw" met bewaren) bewaart het statusrapport ook als pagina om te lezen (`.html`).
- Integratietests: alle contractdoelen tegelijk (elk in een eigen container), de tussenstand zodra er een klaar is. Testverkeer stuurt de testheaders van het product (`CI_TEST_HEADERS`).
- De reset maakt de omgeving van de deelproducten eerst leeg (ook de stubs).
- Stappen per container (`Step.spec.level: container`): statische controle, unittests, contracttest en bouwen draaien per container van het deelproduct, elk met een eigen logregel (`container`). Contracten per container (`Contract.spec.container`). Stubs zijn geen deel van het deelproduct: hun image wordt alleen gebouwd als het ontbreekt.
- Ingekorte stappen voor de demo, met een goedgekeurde afwijking: end-to-end alleen de tests van `Step.spec.grep`; security, versheid, SBOM en licenties van dezelfde inhoud uit de cache van de voorbereiding (`Step.spec.cache`).
- De changelog tot en met de uitgerolde versie in `service.deployed` (contract 0.5.0), voor de changelog-tab van het Dashboard.

## [0.6.0] - 2026-11-21

### Toegevoegd
- Logregels volgens contract 0.4.0 (live weergave van het Dashboard, fcd-labs/fcd-pipeline#13): begin en einde van elke stap en gate.
  - `fcd-qualitygate.started` vóór elke gate.
  - Mensgate op de werkplek: komt de run bij de mensgate en is de versie hoger dan de laatste release, dan wacht de gate op de goedkeurder (`waitingFor`: `QualityGate.spec.approver`, anders "product owner"; actie "merge op main met een hogere versie").
  - `testsuiterun.started` en `fcd-testsuiterun.progressed` voor integratie en end-to-end: end-to-end met `expected` (`playwright test --list`) en een tussenstand uit de uitvoer, hoogstens één per seconde; integratie een tussenstand na elk contractdoel. Unittests alleen de eindstand.
  - `excerpt` bij een mislukte stap: één regel uit de log van de stap (de eerste met `FAIL` of `ERROR`, anders de laatste), hoogstens 300 tekens, geheimen gemaskeerd.
  - `steps` bij `pipelinerun.started`: de stappen van deze run, in volgorde (ook bij `--until`).
- De nieuwe logregels gaan alleen naar een Dashboard dat ze kent: de vastgelegde Dashboard-versie van de showcase is 0.4.0 of hoger. Anders blijft alles zoals in 0.5.2.
- `fcd up` geeft het Dashboard de configuratie van de showcase (`FCD_CONFIG_DIR=<showcase-repo>/fcd`, alleen-lezen gemount).

## [0.5.2] - 2026-11-21

### Toegevoegd
- De webinterface van het API-register (Apicurio Registry UI, Apache-2.0) draait mee, op de poort `registry-ui` uit de configuratie (Demo: 8072). Het register laat alleen die webinterface toe (CORS).
- Elk contract staat in het register met zijn titel uit de configuratie en labels (showcase, repository, deelproduct, type, compatibiliteit), zodat je bijvoorbeeld zoekt op `deelproduct:bestellen`. De groep (de showcase) krijgt een beschrijving.

## [0.5.1] - 2026-11-21

### Opgelost
- Een contract dat naar een ander contract verwijst (`$ref`, zoals het eindpunt van de logregel naar het schema) wordt geregistreerd met een referentie naar dat contract in het register (configuratie: `Contract.spec.references`). Zonder referentie kon Apicurio geen nieuwe versie vergelijken.
- Een contractversie die niet geregistreerd kan worden bij het vullen van het register wordt gemeld, niet verzwegen.

## [0.5.0] - 2026-11-21

### Toegevoegd
- API-register per showcase: Apicurio Registry (Apache-2.0) als tool van FCD, gestart door `fcd up`, opslag in het geheugen (afwijking EXP-003). `fcd up` vult het register uit git: alle contracten uit de configuratie, in hun vrijgegeven versie.
- Stap 3 (contracttest) per contract uit de configuratie (`kind: Contract`): lint, een nieuwe versie als het contract veranderde, geen brekende wijziging volgens oasdiff (OpenAPI) en volgens de compatibiliteitsregel in het API-register (BACKWARD). Een brekende wijziging laat de codegate dichtvallen.
- Na een release registreert de Pipeline elke nieuwe contractversie in het register.

### Gewijzigd
- Welke contracten een repository heeft, staat in de configuratie van de showcase, niet meer in `ci/steps.sh` (`CI_OPENAPI` is weg).

## [0.4.1] - 2026-11-20 - Noodpatch

### Opgelost
- `fcd up`, `down` en `status` kozen de compose-projecten op voorvoegsel (`demo-`) en raakten zo ook een ander project met dezelfde naam aan (`fcd up` startte het). Nu alleen de exacte projecten van de showcase: `<prefix>-dashboard` en `<prefix>-<deelproduct>`.

## [0.4.0] - 2026-11-20

### Gewijzigd
- Deelproduct van het product FCD (was fcd-demo), voor alle showcases. Repository `fcd-pipeline`.
- Alles wat per showcase verschilt komt uit de configuratie van de showcase (`fcd-<showcase>/fcd/*.fcd.yaml`): stappen en volgorde, quality gates en drempels, uitrollen en releasen, goedgekeurde afwijkingen, omgeving (poorten, projectnamen) en de vastgelegde versies van Pipeline en Dashboard.
- Data per showcase: eigen outbox, status, experiment en geheimen (`~/.fcd/<showcase>/`), eigen projectnamen (`<prefix>-<deelproduct>`).
- Versheid: het product meldt feiten (`freshness|onderdeel|naam|huidig|nieuwste`); de drempel staat in de configuratie.
- Het licentiebeleid komt uit de configuratie (geen vast bestand meer).

### Toegevoegd
- `fcd up --showcase <dir>`: het Dashboard en de Pipeline-agent van de showcase, in de vastgelegde versies (git-tags, lokaal gebouwd).
- De agent volgt ook de showcase-repository: een wijziging in de configuratie haalt de deelproducten opnieuw door de pipeline.
- `fcd report` bewaart ook de log van het experiment (`log/<experiment>.jsonl`) in de showcase-repository.
- `FCD_REPO_BASE`: een andere plek voor de repositories (een fork of een proef).

### Opgelost
- Een tijdelijke testomgeving in een run na een merge meldde zich als `lokaal`; de bestellingen van de integratietests telden dan mee voor het key result. Nu altijd `werkplek`.
- Logregels bevatten geen lokale paden meer (rapporten en run relatief aan de repository): de log staat openbaar in de showcase-repository.
- Releasen naar een git-host die geen GitHub is: alleen de tag (elke git-host werkt), geen fout.
- Scans: een bevinding (exitcode 3) en een mislukte scan (zoals een geblokkeerde download) hebben elk een eigen reden; beide houden de gate dicht.

## [0.3.3] - 2026-11-20

### Toegevoegd
- `fcd experiment start <naam>`: een nieuw experiment met een lege log; de vorige log blijft bewaard en is te kiezen in het Dashboard. De agent haalt alles opnieuw door de pipeline, zodat de containers in het nieuwe experiment meten.

### Opgelost
- `fcd bump` vergelijkt met `main` in plaats van met de laatste release-tag. Een gemergde, nog niet getagde versie werd anders niet als "al uitgebracht" gezien, en dan bleef de versie van het deelproduct staan.

## [0.3.2] - 2026-11-20

### Opgelost
- `fcd bump` haalt eerst de release-tags op. Zonder die tags vergeleek hij met een oudere release en verhoogde hij de versie van het deelproduct niet (de codegate ving het).

## [0.3.1] - 2026-11-20 - Noodpatch

### Opgelost
- Contracttest (stap 3): van de vorige release werd alleen het losse contractbestand opgehaald, waardoor verwijzingen naar andere bestanden (`$ref`) niet werkten en de codegate onterecht dichtviel. Nu wordt de hele repository van de vorige release uitgepakt.
- Ook vóór een push worden de release-tags opgehaald, zodat de versie- en contractcontrole lokaal hetzelfde ziet als de Pipeline.

## [0.3.0] - 2026-11-20

### Toegevoegd
- `fcd report`: bewaart het statusrapport van het Dashboard in `fcd-demo/reports/`.
- De uitgerolde containers krijgen experiment en omgeving mee (`FCD_EXPERIMENT`, `FCD_ENVIRONMENT`), voor de meting van het key result.

### Gewijzigd
- GitOps ook voor de Pipeline zelf: de agent draait de `fcd` die op `main` staat (zijn eigen checkout, als eerste bijgewerkt), nooit een werkkopie.

## [0.2.0] - 2026-11-20

### Toegevoegd
- De gate-logregel bevat de details van gebruikte afwijkingen (`explainDetails`: regel, reden, goedkeurder, einddatum).
- `fcd_secret`: een gegenereerd geheim per machine in `~/.fcd/secrets`, nooit in git.
- Stap 4 haalt ook de images op die niet zelf gebouwd worden.

### Opgelost
- Bij twee redenen tegelijk verdween het scheidingsteken in de reden van een gate.
- De trigger van een merge op `main` is de persoon die mergede, niet de AI die de commits schreef; ook de goedkeurder in de mensgate.
- De agent slaat repositories zonder `versions.env` over, zonder foutmelding.

## [0.1.0] - 2026-11-20

### Toegevoegd
- `fcd`: het bash-script dat de enige weg is. `check`, `ci` (CI-stappen 1–10 met code-, bouw-, security-, uitrol- en mensgate), `bump`, `hooks` (pre-push), `agent`, `up`, `down`, `status`, `logs`.
- Na elke stap en gate een logregel (CDEvents) naar het Dashboard; zonder Dashboard in een outbox die later wordt verstuurd.
- Tools in containers met vaste versie en digest (`tools.env`); licentiebeleid in `trivy/trivy-license.yaml`.
- Unittests met bats, lint met ShellCheck.
