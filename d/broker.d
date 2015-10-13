/*
2015-Oct-13 12:12:14.688913, start: 10466811, now: 10468099, duration: 1288ms, rps:46584
2015-Oct-13 12:12:16.33728, start: 10466811, now: 10469748, duration: 2937ms, rps:20429
2015-Oct-13 12:12:17.990073, start: 10466811, now: 10471400, duration: 4589ms, rps:13074
2015-Oct-13 12:12:19.652233, start: 10466811, now: 10473063, duration: 6252ms, rps:9597
2015-Oct-13 12:12:21.293905, start: 10466298, now: 10474704, duration: 8406ms, rps:7137
2015-Oct-13 12:12:22.936303, start: 10466795, now: 10476347, duration: 9552ms, rps:6281
2015-Oct-13 12:12:24.580633, start: 10466811, now: 10477991, duration: 11180ms, rps:5366
2015-Oct-13 12:12:26.228924, start: 10466811, now: 10479639, duration: 12828ms, rps:4677
2015-Oct-13 12:12:27.875454, start: 10466811, now: 10481286, duration: 14475ms, rps:4145
2015-Oct-13 12:12:29.518768, start: 10466811, now: 10482929, duration: 16118ms, rps:3722
2015-Oct-13 12:12:31.164742, start: 10468099, now: 10484575, duration: 16476ms, rps:3641
2015-Oct-13 12:12:32.81601, start: 10469748, now: 10486226, duration: 16478ms, rps:3641
2015-Oct-13 12:12:34.465663, start: 10471400, now: 10487876, duration: 16476ms, rps:3641
2015-Oct-13 12:12:36.104132, start: 10473063, now: 10489515, duration: 16452ms, rps:3647
2015-Oct-13 12:12:37.760386, start: 10474704, now: 10491171, duration: 16467ms, rps:3643
2015-Oct-13 12:12:39.415931, start: 10476347, now: 10492826, duration: 16479ms, rps:3641

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
            writeln(Clock.currTime(), ", start: ", start, ", now: ", now, ", duration: ", duration, "ms, rps:", counter * 1000 / duration);
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