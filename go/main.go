package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	_ "github.com/mattn/go-sqlite3"
)

var db *sql.DB
var writep *sql.Stmt
var readp *sql.Stmt

const table = "CREATE TABLE IF NOT EXISTS test (id INTEGER PRIMARY KEY AUTOINCREMENT,name REAL,timestamp INTEGER);"
const readq = "SELECT id, name, timestamp FROM test ORDER BY id DESC LIMIT 100;"
const writeq = "INSERT INTO test (name, timestamp) VALUES (?, ?);"

func initDB() {
	var err error
	db, err = sql.Open("sqlite3", "./data.db")
	if err != nil {
		log.Fatal(err)
	}

	_, err = db.Exec(table)
	if err != nil {
		log.Fatal(err)
	}

	// set WAL and busy_timeout
	_, err = db.Exec("PRAGMA journal_mode=WAL;")
	if err != nil {
		log.Fatal(err)
	}
	_, err = db.Exec("PRAGMA busy_timeout=5000;")
	if err != nil {
		log.Fatal(err)
	}

	writep, err = db.Prepare(writeq)
	if err != nil {
		log.Fatal(err)
	}

	readp, err = db.Prepare(readq)
	if err != nil {
		log.Fatal(err)
	}
}

type Item struct {
	Id        int    `json:"id"`
	Name      string `json:"name"`
	Timestamp int64  `json:"timestamp"`
}

func writeHandler(w http.ResponseWriter, r *http.Request) {
	var item Item
	err := json.NewDecoder(r.Body).Decode(&item)
	if err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	item.Timestamp = time.Now().Unix()
	_, err = writep.Exec(item.Name, item.Timestamp)
	if err != nil {
		http.Error(w, fmt.Sprintf("Database error %s", err), http.StatusInternalServerError)
		return
	}

	w.Write([]byte(fmt.Sprintf(`{"status":"OK", "name": "%s" }`, item.Name)))
}

func readHandler(w http.ResponseWriter, r *http.Request) {
	rows, err := readp.Query()
	if err != nil {
		http.Error(w, fmt.Sprintf("Database Q error %s", err), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var items []Item
	for rows.Next() {
		var item Item
		if err := rows.Scan(&item.Id, &item.Name, &item.Timestamp); err != nil {
			http.Error(w, fmt.Sprintf("Database error %s", err), http.StatusInternalServerError)
			return
		}
		items = append(items, item)
	}

	json.NewEncoder(w).Encode(items)
}

func main() {
	initDB()
	http.HandleFunc("/write", writeHandler)
	http.HandleFunc("/read", readHandler)

	log.Println("Server started on :3000")
	log.Fatal(http.ListenAndServe(":3000", nil))
}
