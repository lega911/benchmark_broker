package main

import (
    "net"
    "os"
)


func main() {
    kind := os.Args[1]
    if kind == "client" {
        runClient("localhost:4000")
    }
    if kind == "worker" {
        runWorker("localhost:4001")
    }
}


func runClient(host string) {
    conn, err := net.Dial("tcp", host)
    if err != nil {
        panic("Connect error")
    }

    resp := make([]byte, 64)
    msg := []byte("0123456789012345678901234567890123456789012345678901234567890123")  // 64b
    for {
        lenWrote, err := conn.Write(msg)
        if err != nil {
            panic("Error write to broker")
        }
        if lenWrote != 64 {
            panic("Error write to broker 2")
        }

        lenRead, err := conn.Read(resp)
        if err != nil {
            panic("Error read from broker")
        }
        if lenRead != 64 {
            panic("Error read from broker 2")
        }

    }
}


func runWorker(host string) {
    conn, err := net.Dial("tcp", host)
    if err != nil {
        panic("Connect error")
    }

    req := make([]byte, 64)
    for {
        lenRead, err := conn.Read(req)
        if err != nil {
            panic("Error read from broker")
        }
        if lenRead != 64 {
            panic("Error read from broker 2")
        }

        lenWrote, err := conn.Write(req)
        if err != nil {
            panic("Error write to broker")
        }
        if lenWrote != 64 {
            panic("Error write to broker 2")
        }
    }
}