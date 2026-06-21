package service

import (
	"encoding/json"
	"log"
	"net/http"
	bfpb "simulator/proto"
	"time"

	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"
)

const subjectFlightPosition = "flight.position.updated"

// openSkyResponse raw JSON từ OpenSky API
type openSkyResponse struct {
	Time   int64           `json:"time"`
	States [][]interface{} `json:"states"`
}

func (c *OpenSkyClient) PollOpenSky() {
	req, err := http.NewRequest(
		http.MethodGet,
		"https://opensky-network.org/api/states/all?lamin=8&lomin=102&lamax=24&lomax=110",
		nil,
	)
	if err != nil {
		log.Printf("[opensky] create request error: %v", err)
		return
	}

	req.SetBasicAuth(c.username, c.password)

	resp, err := c.client.Do(req)
	if err != nil {
		log.Printf("[opensky] request error: %v", err)
		return
	}
	defer resp.Body.Close()
	log.Printf("[opensky] Status: %s", resp.Status)

	var data openSkyResponse
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		log.Printf("[opensky] decode error: %v", err)
		return
	}

	for _, state := range data.States {
		event := mapState(state)
		if event == nil {
			continue
		}
		c.publish(event)
	}
}

// mapState parse một state array từ OpenSky sang proto FlightEvent
func mapState(s []interface{}) *bfpb.FlightEvent {
	if len(s) < 11 {
		return nil
	}
	icao24, _   := s[0].(string)
	callsign, _ := s[1].(string)
	lon, _      := s[5].(float64)
	lat, _      := s[6].(float64)
	alt, _      := s[7].(float64)
	speed, _    := s[9].(float64)
	heading, _  := s[10].(float64)

	return &bfpb.FlightEvent{
		Icao24:   icao24,
		Callsign: callsign,
		Lat:      lat,
		Lon:      lon,
		Alt:      alt,
		Speed:    speed,
		Heading:  heading,
		Ts:       timestamppb.New(time.Now()),
	}
}

// publish marshal FlightEvent thành protobuf bytes và gửi lên NATS
func (c *OpenSkyClient) publish(event *bfpb.FlightEvent) {
	data, err := proto.Marshal(event)
	if err != nil {
		log.Printf("[opensky] proto marshal error: %v", err)
		return
	}

	if err := c.nc.Publish(subjectFlightPosition, data); err != nil {
		log.Printf("[opensky] NATS publish error for %s: %v", event.GetIcao24(), err)
		return
	}
	log.Printf("[opensky] Published: %s (%s)", event.GetIcao24(), event.GetCallsign())
}
