# Start the application

1. create a database file for sqlite (i.e. `touch db.sqlite`)
2. create the table (`cat create_table.sql | sqlite3 db.sqlite`)
3. build the app (`nix build .#hxChat`)
4. run the app (`./result/bin/hx --db_file db.sqlite`)
