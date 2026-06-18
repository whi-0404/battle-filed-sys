package api

import (
	"battlefiled-sys/internal/hub"
	"log"
	"net/http"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 32 * 1024, // 32KB write buffer cho snapshot lớn
	// Cho phép tất cả origins (production nên restrict)
	CheckOrigin: func(r *http.Request) bool { return true },
}

// WebSocketHandler xử lý HTTP → WebSocket upgrade cho endpoint /ws/radar
type WebSocketHandler struct {
	hub *hub.Hub
}

func NewWebSocketHandler(h *hub.Hub) *WebSocketHandler {
	return &WebSocketHandler{hub: h}
}

// ServeHTTP implement http.Handler
func (wh *WebSocketHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("[ws-handler] upgrade error: %v", err)
		return
	}

	log.Printf("[ws-handler] New radar client connected from %s", r.RemoteAddr)
	wh.hub.RegisterClient(conn)
}

// HealthHandler endpoint đơn giản để kiểm tra backend còn sống
func HealthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"ok","service":"battlefield-backend"}`))
}
