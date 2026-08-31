# Piano di risoluzione — inserimento/eliminazione portale GymManager

> Stato: **diagnosi completata, test in scrittura, fix non ancora applicati.**
> Branch di sviluppo: `claude/portal-insert-delete-fix-rneabr`

## 1. Come riprodurre

```bash
service postgresql start
bash bin/setup --seed
ruby app.rb &            # http://localhost:4567

curl -i http://localhost:4567/                     # => 404 Not Found
curl -i http://localhost:4567/members              # => 500
curl -i -X POST http://localhost:4567/members/1/delete   # => 500
curl -i -X POST http://localhost:4567/classes/1/enroll -d "member_id=1"  # => 500
```

## 2. Diagnosi (bug confermati sul portale in esecuzione)

| # | File | Bug | Effetto osservato |
|---|------|-----|-------------------|
| 1 | `lib/router.rb` (`Router#add`) | `path.split('/')` su `"/"` restituisce `[]` → pattern regex vuota `/\A\z/` che non matcha `"/"` | **`GET /` → 404 "Pagina non trovata"** — la home del portale |
| 2 | `lib/router.rb` (`Router#add`/`#dispatch`) | le chiavi dei route param sono **Symbol** (`keys << seg[1..].to_sym`) mentre gli handler leggono `req.params['id']` (**String**) | `:id` è sempre `nil` → **DELETE / UPDATE / ENROLL rotti**: `ERROR: invalid input syntax for type integer: ""` (500) |
| 3 | `app.rb` (`ViewContext`, `render`) | `ctx.send(:binding)` restituisce il binding del **chiamante** (`main`), non quello del contesto di view | **tutte le pagine GET → 500**: `undefined local variable or method 'name_filter' for main` |
| 4 | `app.rb` (rotte `:id`) | `Member.find` / `ActivityClass.find` che ritornano `nil` non sono gestiti | 500 invece di un 404 leggibile su id inesistente |
| 5 | `app.rb` + `lib/db.rb` | `req.params.slice(...)` con campi assenti lascia variabili psql non sostituite (`:'email'`) | errore SQL su POST con form parziale |
| 6 | `views/layout.erb` | `flash_message` è renderizzato ma nessuna rotta lo valorizza (codice morto) | dopo un insert/delete l'utente non ha conferma che l'operazione sia avvenuta |

**Sintesi:** l'`INSERT` a livello SQL funziona (verificato: righe realmente scritte in `members` e `classes`, apostrofi/accenti/newline gestiti correttamente da psql `-v` + `:'var'`), ma **`DELETE`, `UPDATE` ed `ENROLL` sono tutti rotti dal bug #2** e ogni pagina di ritorno è rotta dai bug #1/#3 — da cui il "not found" segnalato.

## 3. Istanze che devono avere insert/delete corretti (da `specifica_porgetto.txt`)

| Tabella | Insert | Update | Delete | Rotta |
|---------|:------:|:------:|:------:|-------|
| `members` | ✔ | ✔ | ✔ | `POST /members`, `POST /members/:id/edit`, `POST /members/:id/delete` |
| `classes` | ✔ | ✔ | ✔ | `POST /classes`, `POST /classes/:id/edit`, `POST /classes/:id/delete` |
| `enrollments` | ✔ | — | — (solo CASCADE) | `POST /classes/:id/enroll` |
| `attendances` | ✔ | — | — (solo CASCADE) | `POST /attendance` |

## 4. Piano di esecuzione

1. **Prima i test** (minitest, stdlib, DB dedicato `gymmanager_test`, `TRUNCATE ... RESTART IDENTITY` prima di ogni test):
   - `test/test_helper.rb` — setup DB di test, fixture, helper `get`/`post` che costruiscono una vera `Request` e la passano al router.
   - `test/router_test.rb` — match di `/`, chiavi dei route param come String, 404 su rotta ignota.
   - `test/rendering_test.rb` — `render` produce HTML con i locals e il layout, senza eccezioni.
   - `test/models_test.rb` — CRUD dei model: `Member`, `ActivityClass`, `Attendance`, enrollments; filtri `name`/`status`; CASCADE su delete membro.
   - `test/integration_test.rb` — end-to-end per **ogni** istanza della tabella §3: la richiesta HTTP produce il redirect atteso **e** la riga è realmente presente/assente nel DB. Include casi limite: apostrofi, accenti, newline in textarea, campi vuoti, id inesistente.
2. Eseguire i test e verificarne il **fallimento** (riproduzione dei bug in suite).
3. Applicare i fix:
   - `lib/router.rb`: `path.split('/', -1)` (matcha `/`) e chiavi dei param come **String**.
   - `lib/view.rb` (estratto da `app.rb`): `ViewContext#get_binding` che restituisce il proprio binding; `content` esposto come metodo del contesto invece che come local var del layout.
   - `lib/application.rb`: rotte estratte da `app.rb` in `GymManager.router`, così sono testabili senza avviare il TCP server; `app.rb` resta il solo entrypoint (`lib/server.rb` per il server HTTP).
   - 404 esplicito quando `find` ritorna `nil`.
   - Normalizzazione dei parametri di form (chiavi mancanti → `''`) prima di passarli ai model.
   - Messaggio di conferma (flash) dopo insert/update/delete, così l'esito è visibile nel portale.
4. Rieseguire la suite fino al verde.
5. Smoke test HTTP reale su tutte le rotte (GET e POST) contro il DB `gymmanager`, verificando i conteggi delle righe prima/dopo.
6. Commit e push sul branch `claude/portal-insert-delete-fix-rneabr`.

## 5. Come eseguire i test

```bash
service postgresql start
bash bin/setup                       # crea ruolo + db 'gymmanager'
ruby -Ilib -Itest test/integration_test.rb    # oppure, per tutta la suite:
for f in test/*_test.rb; do ruby -Ilib -Itest "$f"; done
```
