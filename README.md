# Prerequisites

- `nix` with flake support

# Start the application

1. `nix develop -c sqlite3 db.sqlite <create_table.sql`
3. build the app (`nix build`)
4. run the app (`nix run .# --db_file db.sqlite`)
