package function

import (
	"fmt"
	"net/http"
	"os"
)

func HelloWorld(w http.ResponseWriter, r *http.Request) {
	env := os.Getenv("ENV")
	if env == "" {
		env = "no var env set"
	}
	name := r.URL.Query().Get("name")
	if name == "" {
		name = "world"
	}
	fmt.Fprintf(w, "Hello %s from %s!", name, env)
}
