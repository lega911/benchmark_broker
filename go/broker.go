package main

import (
    "fmt"
    "net"
    "os"
    "time"
)

var workers chan net.Conn

func main() {
    workers = make(chan net.Conn, 100)

    go runCounter()
    go runServer("localhost:4000", brokerClientHandler)
    runServer("localhost:4001", brokerWorkerHandler)
}

func runServer(host string, handler func(conn net.Conn)) {
    l, err := net.Listen("tcp", host)
    if err != nil {
        fmt.Println("Error listening:", err.Error())
        os.Exit(1)
    }
    defer l.Close()
    fmt.Println("Listening " + host)
    for {
        conn, err := l.Accept()

        if err != nil {
            fmt.Println("Error accepting: ", err.Error())
            os.Exit(1)
        }
        go handler(conn)
    }
}

var counter chan int64

func getTick() (int64) {
    return time.Now().UnixNano() / int64(time.Millisecond)
}

func runCounter() {
    total := int64(0)
    counter = make(chan int64)
    start := getTick()
    var now int64
    for v := range counter {
        total += v
        now = getTick()

        duration := now - start
        if duration > 1000 {
            fmt.Println("Counter: ", 1000 * total / duration)
            start = now
            total = 0
        }
    }
}

func brokerClientHandler(conn net.Conn) {
    fmt.Println("new client")
    defer conn.Close()
    req := make([]byte, 64)
    resp := make([]byte, 64)
    count := int64(0)
    for {
        lenRead, err := conn.Read(req)
        if err != nil {
            break
        }
        if lenRead != 64 {
            panic("Error read from client")  // net package < mtu shouldn't be divided
        }

        worker := <- workers  // take a worker from queue

        lenWrote, err := worker.Write(req)
        if err != nil {
            panic("Error write to worker")
        }
        if lenWrote != 64 {
            panic("Error write to worker 2")
        }

        lenRead, err = worker.Read(resp)
        if err != nil {
            panic("Error read from worker")
        }
        if lenRead != 64 {
            panic("Error read from worker 2")
        }

        workers <- worker  // put the worker to queue

        lenWrote, err = conn.Write(resp)
        if err != nil {
            break
        }
        if lenWrote != 64 {
            panic("Error write to client")
        }

        // counter
        count += 1
        if count > 10000 {
            counter <- count
            count = 0
        }
    }
}

func brokerWorkerHandler(conn net.Conn) {
    fmt.Println("new worker")
    workers <- conn
}
