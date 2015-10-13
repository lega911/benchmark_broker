/*
1734 > 34602
2884 > 20804
4520 > 13274
6157 > 9745
7800 > 7692
9444 > 6353
11083 > 5413
12725 > 4715
14363 > 4177
16464 > 3644
16522 > 3631
16561 > 3623

*/

import vibe.d;
import core.time;
import std.stdio;


TCPConnection[] workers;
bool logging;
ulong counter;

shared static this()
{
    logging = false;
    runTask({
        writeln("Start worker connector");
        listenTCP_s(4001, &worker_handler);
    });

    runTask({
        writeln("Start client connector");
        listenTCP_s(4000, &handler);
    });

    // 10 workers
    for(auto i=0;i<10;i++) {
        runTask({
            runWorker();
        });        
    }

    // 10 clients
    for(auto i=0;i<9;i++) {
        runTask({
            runClient();
        });        
    }
    runClient();
}

void worker_handler(TCPConnection conn) {
    writeln("Worker connected");

    workers ~= conn;

    while(conn.connected){
        sleep(500.msecs);
    }
    writeln("Worker disconected");
}

long getTickMs() nothrow @nogc
{
    import core.time;
    return convClockFreq(MonoTime.currTime.ticks, MonoTime.ticksPerSecond, 1_000);
}

void handler(TCPConnection conn) {
    writeln("Client connected");
    TCPConnection worker;
    ubyte[64] req, resp;
    long start = getTickMs();
    while(conn.connected){
        // read client
        if(!conn.waitForData(dur!"seconds"(100L))) {
            writeln("Read from client timeout");
            break;
        }
        conn.read(req);

        // wait worker
        while(workers.length == 0) {
            sleep(1.msecs);
        }
        worker = workers[$-1];
        workers.length -= 1;

        worker.write(req);

        if(!worker.waitForData(dur!"seconds"(100L))) {
            writeln("Read from worker timeout");
            break;
        }
        worker.read(resp);

        conn.write(resp);
        workers ~= worker;  // send worker to queue

        counter++;
        if(counter > 60000) {
            long now = getTickMs();
            auto duration = now - start;
            //writeln(now, " - ", start, " = ", duration);
            writeln(duration, " > ", counter * 1000 / duration);
            counter = 0;
            start = now;
        }
    }
}


void runWorker() {
    ubyte[64] buf;
    auto conn = connectTCP("localhost", 4001);

    while(conn.connected){
        conn.read(buf);
        conn.write(buf);
    }
};


void runClient() {
    ubyte[64] buf, msg;
    for(auto i=0;i<64;i++) {
        msg[i] = ubyte(i & 0xff);
    }

    sleep(500.msecs);

    auto conn = connectTCP("localhost", 4000);

    while(conn.connected){
        conn.write(msg);
        conn.read(buf);
    }
};