package main

import (
	"context"
	"database/sql"
	"encoding/csv"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/lib/pq"
	_ "github.com/lib/pq"
)

// DB connection string from env
const defaultDBURL = "postgres://postgres:postgres@localhost:5432/battlefield?sslmode=disable"

type Aircraft struct {
	ICAO24   string
	Callsign string
}

type TrackData struct {
	ICAO24   string
	Lat      float64
	Lon      float64
	Alt      float64
	Heading  float64
	Speed    float64
	Time     time.Time
}

func main() {
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = defaultDBURL
	}

	db, err := sql.Open("postgres", dbURL)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v\n", err)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		log.Fatalf("Failed to ping database: %v\n", err)
	}

	dataDir := os.Getenv("DATA_DIR")
	if dataDir == "" {
		dataDir = "data-crawl"
	}
	files, err := os.ReadDir(dataDir)
	if err != nil {
		log.Fatalf("Failed to read data-crawl dir: %v", err)
	}

	// We will keep track of unique aircraft and latest tracking state in memory
	aircrafts := make(map[string]Aircraft)
	latestTracking := make(map[string]TrackData)
	var allHistories []TrackData

	log.Println("Reading CSV files...")
	for _, f := range files {
		if !strings.HasSuffix(f.Name(), ".csv") {
			continue
		}
		filePath := filepath.Join(dataDir, f.Name())
		log.Printf("Processing %s\n", filePath)

		if err := processCSV(filePath, aircrafts, latestTracking, &allHistories); err != nil {
			log.Printf("Error processing %s: %v", filePath, err)
		}
	}

	log.Printf("Found %d unique aircraft, %d latest tracking states, %d history records",
		len(aircrafts), len(latestTracking), len(allHistories))

	log.Println("Inserting Aircrafts...")
	insertAircrafts(context.Background(), db, aircrafts)

	log.Println("Inserting Tracking (Latest)...")
	insertTracking(context.Background(), db, latestTracking)

	log.Println("Inserting Tracking History (Batch)...")
	insertHistory(context.Background(), db, allHistories)

	log.Println("Ingestion completed successfully.")
}

func processCSV(filePath string, aircrafts map[string]Aircraft, latestTracking map[string]TrackData, allHistories *[]TrackData) error {
	file, err := os.Open(filePath)
	if err != nil {
		return err
	}
	defer file.Close()

	reader := csv.NewReader(file)
	// Read header
	headers, err := reader.Read()
	if err != nil {
		return err
	}

	// Map column index
	colMap := make(map[string]int)
	for i, h := range headers {
		colMap[strings.TrimSpace(h)] = i
	}

	// Required columns
	reqCols := []string{"time", "icao24", "lat", "lon", "velocity", "heading", "baroaltitude"}
	for _, c := range reqCols {
		if _, ok := colMap[c]; !ok {
			return fmt.Errorf("missing required column: %s", c)
		}
	}
	callsignIdx, hasCallsign := colMap["callsign"]

	for {
		record, err := reader.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			log.Printf("Error reading row: %v", err)
			continue
		}

		// Check for missing data
		isValid := true
		for _, c := range reqCols {
			if strings.TrimSpace(record[colMap[c]]) == "" {
				isValid = false
				break
			}
		}
		if !isValid {
			continue
		}

		// Parse data
		tsInt, err1 := strconv.ParseInt(record[colMap["time"]], 10, 64)
		lat, err2 := strconv.ParseFloat(record[colMap["lat"]], 64)
		lon, err3 := strconv.ParseFloat(record[colMap["lon"]], 64)
		vel, err4 := strconv.ParseFloat(record[colMap["velocity"]], 64)
		hdg, err5 := strconv.ParseFloat(record[colMap["heading"]], 64)
		alt, err6 := strconv.ParseFloat(record[colMap["baroaltitude"]], 64)

		if err1 != nil || err2 != nil || err3 != nil || err4 != nil || err5 != nil || err6 != nil {
			// Skip row with invalid format
			continue
		}

		icao24 := strings.TrimSpace(record[colMap["icao24"]])
		callsign := ""
		if hasCallsign {
			callsign = strings.TrimSpace(record[callsignIdx])
		}
		recordTime := time.Unix(tsInt, 0)

		data := TrackData{
			ICAO24:  icao24,
			Lat:     lat,
			Lon:     lon,
			Alt:     alt,
			Heading: hdg,
			Speed:   vel,
			Time:    recordTime,
		}

		// Update maps
		if existing, ok := aircrafts[icao24]; !ok || (existing.Callsign == "" && callsign != "") {
			aircrafts[icao24] = Aircraft{ICAO24: icao24, Callsign: callsign}
		}

		if existing, ok := latestTracking[icao24]; !ok || recordTime.After(existing.Time) {
			latestTracking[icao24] = data
		}

		*allHistories = append(*allHistories, data)
	}

	return nil
}

func insertAircrafts(ctx context.Context, db *sql.DB, aircrafts map[string]Aircraft) {
	for _, a := range aircrafts {
		_, err := db.ExecContext(ctx, `
			INSERT INTO aircraft (icao24, callsign, type, status, created_at, updated_at)
			VALUES ($1, $2, 'CIVIL', 'ACTIVE', NOW(), NOW())
			ON CONFLICT (icao24) DO UPDATE SET callsign = EXCLUDED.callsign, updated_at = NOW()
		`, a.ICAO24, a.Callsign)
		if err != nil {
			log.Printf("Failed to insert aircraft %s: %v", a.ICAO24, err)
		}
	}
}

func insertTracking(ctx context.Context, db *sql.DB, latest map[string]TrackData) {
	for _, t := range latest {
		_, err := db.ExecContext(ctx, `
			INSERT INTO tracking (icao24, latitude, longitude, altitude, heading, speed, last_updated)
			VALUES ($1, $2, $3, $4, $5, $6, $7)
			ON CONFLICT (icao24) DO UPDATE SET 
				latitude = EXCLUDED.latitude,
				longitude = EXCLUDED.longitude,
				altitude = EXCLUDED.altitude,
				heading = EXCLUDED.heading,
				speed = EXCLUDED.speed,
				last_updated = EXCLUDED.last_updated
		`, t.ICAO24, t.Lat, t.Lon, t.Alt, t.Heading, t.Speed, t.Time)
		if err != nil {
			log.Printf("Failed to insert tracking %s: %v", t.ICAO24, err)
		}
	}
}

func insertHistory(ctx context.Context, db *sql.DB, histories []TrackData) {
	txn, err := db.BeginTx(ctx, nil)
	if err != nil {
		log.Printf("Failed to begin transaction for history insert: %v", err)
		return
	}

	stmt, err := txn.Prepare(pq.CopyIn("track_history", "icao24", "latitude", "longitude", "altitude", "heading", "speed", "snapshot_at"))
	if err != nil {
		log.Printf("Failed to prepare copyin statement: %v", err)
		return
	}

	for _, h := range histories {
		_, err = stmt.Exec(h.ICAO24, h.Lat, h.Lon, h.Alt, h.Heading, h.Speed, h.Time)
		if err != nil {
			log.Printf("Exec CopyIn error for %s: %v", h.ICAO24, err)
		}
	}

	_, err = stmt.Exec()
	if err != nil {
		log.Printf("Exec flush error: %v", err)
	}

	err = stmt.Close()
	if err != nil {
		log.Printf("Close CopyIn stmt error: %v", err)
	}

	err = txn.Commit()
	if err != nil {
		log.Printf("Commit CopyIn txn error: %v", err)
	}
}
