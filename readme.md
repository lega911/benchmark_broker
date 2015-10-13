
# Build broker

$ go build go/broker.go

# Run

## Start broker

```sh
cd d && dub
```
or
```sh
go run ./go/broker.go
```

## Start workers

```sh
$ for((i=0;i<10;i++)) do go run ./go/client.go worker & done
```

## Start clients

```sh
$ for((i=0;i<10;i++)) do go run ./go/client.go client & done
```