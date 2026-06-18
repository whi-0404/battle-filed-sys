package service

import (
	"encoding/json"
	"log"
	"net/http"
	"time"
)

type OpenSkyResponse struct {
	Time   int64           `json:"time"`
	States [][]interface{} `json:"states"`
}

type FlightEvent struct {
	ICAO24    string    `json:"icao24"`
	Callsign  string    `json:"callsign"`
	Lat       float64   `json:"lat"`
	Lon       float64   `json:"lon"`
	Alt       float64   `json:"alt"`
	Speed     float64   `json:"speed"`
	Heading   float64   `json:"heading"`
	Timestamp time.Time `json:"ts"`
}

func mapState(s []interface{}) FlightEvent {
	icao24, _ := s[0].(string)
	callsign, _ := s[1].(string)
	lon, _ := s[5].(float64)
	lat, _ := s[6].(float64)
	alt, _ := s[7].(float64)
	speed, _ := s[9].(float64)
	heading, _ := s[10].(float64)

	return FlightEvent{
		ICAO24:    icao24,
		Callsign:  callsign,
		Lon:       lon,
		Lat:       lat,
		Alt:       alt,
		Speed:     speed,
		Heading:   heading,
		Timestamp: time.Now(),
	}
}

func (c *OpenSkyClient) PollOpenSky() {

	req, err := http.NewRequest(
		http.MethodGet,
		"https://opensky-network.org/api/states/all?lamin=8&lomin=102&lamax=24&lomax=110",
		nil,
	)

	if err != nil {
		log.Printf("create request error: %v", err)
		return
	}

	// OpenSky Authentication
	req.SetBasicAuth(
		c.username,
		c.password,
	)

	resp, err := c.client.Do(req)
	if err != nil {
		log.Printf("opensky request error: %v", err)
		return
	}
	log.Printf("Status: %s", resp.Status)

	defer resp.Body.Close()

	var data OpenSkyResponse

	err = json.NewDecoder(resp.Body).Decode(&data)
	if err != nil {
		log.Printf("decode error: %v", err)
		return
	}

	for _, state := range data.States {

		flightEvent := mapState(state)

		log.Printf(
			"Flight %s (%s)",
			flightEvent.ICAO24,
			flightEvent.Callsign,
		)

		c.publish(flightEvent)
	}
}

func (c *OpenSkyClient) publish(event FlightEvent) {
	data, err := json.Marshal(event)
	if err != nil {
		log.Printf("Error marshaling flight event: %v", err)
		return
	}

	err = c.nc.Publish("flight.position.updated", data)
	if err != nil {
		log.Printf("Error publishing to NATS: %v", err)
		return
	}
	log.Printf("Published to NATS: Flight %s (%s)", event.ICAO24, event.Callsign)
}
