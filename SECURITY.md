# Security

Meld een kwetsbaarheid via **Security → Report a vulnerability** in deze repository (privé). Maak er geen openbaar issue van. Je krijgt binnen een week antwoord.

## Log

| Datum | Actie |
|---|---|
| 2026-11-21 | 0.6.0: een regel uit de uitvoer van een mislukte stap (`excerpt`) gaat naar het Dashboard. De Pipeline maskeert eerst geheimen: de gegenereerde geheimen van de showcase, tokens (GitHub, AWS, Bearer/Basic), wachtwoorden in URL's en waarden achter namen als `password`, `secret`, `token`, `api-key`. Het Dashboard toont hem als tekst, nooit als HTML. |
