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

    writeln("Start client connector");
    listenTCP_s(4000, &handler);
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
    
    StopWatch sw;
    sw.start();

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
            sw.stop();
            auto duration = sw.peek().msecs;
            //writeln(now, " - ", start, " = ", duration);
            writeln(duration, " > ", counter * 1000 / duration);

            counter = 0;
            sw.reset();
            sw.start();
        }
    }
}
