import ceylon.whole {
    ...
}
import ceylon.logging {
    ...
}
import ceylon.collection {
    ...
}

Logger log = logger(`module`);

shared alias Factorization => [Whole, Whole];

suppressWarnings ("expressionTypeNothing")
shared void run() {
    addLogWriter(writeSimpleLog);
    
    MutableList<Whole> wholes = LinkedList<Whole>();
    variable Boolean hadError = false;
    variable Factorization(Whole) factorize = factorizeDixon;
    for (arg in process.arguments) {
        if (arg.startsWith("-")) {
            if (arg == "--dixon") {
                factorize = factorizeDixon;
            } else if (arg == "--pollard-p-1") {
                factorize = factorizePollardP1;
            } else if (arg == "--trace") {
                defaultPriority = trace;
            } else {
                process.writeErrorLine("Unknown option: '``arg``'");
                process.exit(1);
            }
        } else {
            if (exists n = parseWhole(arg)) {
                wholes.add(n);
            } else {
                process.writeErrorLine("Not a valid number: ``arg``");
                hadError = true;
            }
        }
    }
    
    if (!wholes.empty) {
        for (n in wholes) {
            value [p, q] = factorize(n);
            print("``n``: ``p`` ``q``");
        }
    } else if (!hadError) {
        while (exists line = process.readLine()) {
            if (exists n = parseWhole(line)) {
                value [p, q] = factorizeDixon(n);
                print("``n``: ``p`` ``q``");
            } else {
                process.writeErrorLine("Not a valid number: ``line``");
                hadError = true;
            }
        }
    }
    
    if (hadError) {
        process.exit(1);
    }
}
