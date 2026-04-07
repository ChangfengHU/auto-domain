package control

import "testing"

func TestNewServerDerivesPublicEndpointsFromBaseURL(t *testing.T) {
	srv := NewServer(nil, "https://domain.example.com", "", "", "", "")

	if srv.agentServerWS != "wss://domain.example.com/connect" {
		t.Fatalf("agentServerWS = %q", srv.agentServerWS)
	}
	if srv.agentConfigURL != "https://domain.example.com/_tunnel/agent/routes" {
		t.Fatalf("agentConfigURL = %q", srv.agentConfigURL)
	}
	if got := srv.publicURL("app.example.com"); got != "https://app.example.com" {
		t.Fatalf("publicURL = %q", got)
	}
}

func TestNewServerKeepsExplicitEndpoints(t *testing.T) {
	srv := NewServer(
		nil,
		"https://domain.example.com",
		"ws://10.0.0.2:9000/connect",
		"http://10.0.0.3:18100/agent/routes",
		"",
		"",
	)

	if srv.agentServerWS != "ws://10.0.0.2:9000/connect" {
		t.Fatalf("agentServerWS = %q", srv.agentServerWS)
	}
	if srv.agentConfigURL != "http://10.0.0.3:18100/agent/routes" {
		t.Fatalf("agentConfigURL = %q", srv.agentConfigURL)
	}
}

func TestNewServerFallsBackToLocalDefaults(t *testing.T) {
	srv := NewServer(nil, "", "", "", "", "")

	if srv.agentServerWS != "ws://127.0.0.1:9000/connect" {
		t.Fatalf("agentServerWS = %q", srv.agentServerWS)
	}
	if srv.agentConfigURL != "http://127.0.0.1:18100/agent/routes" {
		t.Fatalf("agentConfigURL = %q", srv.agentConfigURL)
	}
	if got := srv.publicURL("app.example.com"); got != "http://app.example.com" {
		t.Fatalf("publicURL = %q", got)
	}
}
