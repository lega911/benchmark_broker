
# Build broker

$ go build go/broker.go

# Run

* start broker
* start workers: $ for((i=0;i<10;i++)) do ./go/client worker & done
* start clients: $ for((i=0;i<10;i++)) do ./go/client client & done
