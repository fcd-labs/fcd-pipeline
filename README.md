# fcd-pipeline

Deelproduct **Pipeline** van het product [FCD](https://fcd-labs.github.io/fcd/). Eén Pipeline voor alle showcases: wat per showcase verschilt, staat in de configuratie van de showcase (bijvoorbeeld [fcd-demo/fcd](https://github.com/fcd-labs/fcd-demo/tree/main/fcd)), niet in de code.

Het bash-script `fcd` is de enige weg om te bouwen, te testen, te controleren, uit te rollen en te releasen. De agent haalt wijzigingen op uit git (alleen `main` en release-tags), draait het script, rolt uit met docker compose en stuurt na elke stap en gate een logregel naar het Dashboard.

Meer over deze showcase: https://fcd-labs.github.io/fcd/showcases/demo/

## Gebruik

```bash
./fcd check --showcase ../fcd-demo   # wat mist er?
./fcd up --showcase ../fcd-demo      # Dashboard en Pipeline-agent van de showcase, in de vastgelegde versies
./fcd ci ../sk-bestellen                  # de stappen en gates van de showcase, lokaal (omgeving werkplek)
./fcd hooks ../sk-bestellen               # dezelfde stappen vóór elke push
./fcd report --showcase ../fcd-demo  # statusrapport en log in de showcase-repository
```

Elke productrepository heeft `versions.env` (de versies) en `ci/steps.sh` (hoe het product gelint, getest en gebouwd wordt). De configuratie van de showcase wordt gelezen met `yq`. Tools en hun licentie: [tools.env](tools.env).

Licentie: [MIT](LICENSE).
