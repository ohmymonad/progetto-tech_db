# progetto-tech_db

Progetto per il corso di sistemi di basi di dati: **GymManager**, gestionale per una palestra
(anagrafica membri, registrazione presenze, gestione classi e iscrizioni).

## Requisiti

- Ruby 3.x (solo standard library, nessuna gemma esterna)
- PostgreSQL 16 con client `psql`

## Avvio

```bash
./bin/setup --seed   # avvia Postgres, crea ruolo e database, applica lo schema e i dati di esempio
ruby app.rb          # server su http://localhost:4567
```

Omettere `--seed` per partire con un database vuoto.

Il setup crea un ruolo Postgres omonimo dell'utente di sistema e usa l'autenticazione `peer`
sul socket Unix: non serve configurare alcuna password.

## Struttura

| Percorso | Contenuto |
|----------|-----------|
| `app.rb` | Entry point: server HTTP su `TCPServer`, definizione delle rotte, rendering ERB |
| `lib/db.rb` | Accesso al database tramite il client `psql`, con parametri quotati |
| `lib/router.rb` | Router HTTP minimale (metodo + path → handler) |
| `lib/models/` | Query per membri, presenze e classi |
| `views/` | Template ERB con layout condiviso, stile Tailwind da CDN |
| `db/schema.sql` | Schema relazionale |
| `db/seed.sql` | Dati di esempio |
| `bin/setup` | Script di provisioning |

## Note implementative

L'applicazione non usa gemme esterne: il server HTTP è costruito sulla standard library e
l'accesso al database avviene invocando `psql`, passando i valori come variabili (`-v`) sempre
referenziate in forma quotata (`:'nome'`) per evitare SQL injection.
