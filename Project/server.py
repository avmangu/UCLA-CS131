# server.py

from twisted.internet.protocol import Factory,Protocol,ClientFactory
from twisted.internet import reactor
from twisted.protocols.basic import LineReceiver
from twisted.web.client import getPage
import sys, conf, time, json

"""
TODO:
	1. Propagate? (Protocol)
	2. PropagateFactory (Factory)
	3. Server (LineRecevier)
	4. ServerFactory (Factory)
"""

SERVER_COMMUNICATIONS = {
	"Alford": ["Hamilton", "Welsh"],
	"Ball": ["Holiday", "Welsh"],
	"Hamilton": ["Alford", "Holiday"],
	"Holiday": ["Ball", "Hamilton"],
	"Welsh": ["Alford", "Ball"]
}

serverName = str(sys.argv[1])
fileName = serverName + "_log.txt"

class Server(LineReceiver):

    def __init__(self, factory):
# The factory is used to share state that exists beyond the lifetime of any given connection.
        self.factory = factory
        self.name = None
        self.server = factory.name
        self.fp = factory.fp
        self.clients = factory.clients
        self.connectedServers = SERVER_COMMUNICATIONS[self.server]

    def connectionMade(self):
        #self.sendLine("What's your name?")
        # increment the number of the connections in factory by one
        self.factory.numOfConnections = self.factory.numOfConnections + 1
        # If you need to send any greeting or initial message, do it here.
        # The logs should also contain notices of new and dropped connections from other servers. 
        s = "New connection established. Total number of connections is {0}".format(self.factory.numOfConnections)
        # write to server/client
        self.sendLine(s)
        self.fp.write(s + "\n")

    def connectionLost(self, reason):
        # decrement the number of connections
        self.factory.numOfConnections = self.factory.numOfConnections - 1
        # log: dropped connection
    	s = "A client dropped connection. Total number of connections is {0}".format(self.factory.numOfConnections)
        if not self.fp.closed:
            self.fp.write(s + "\n")

    def lineReceived(self, line):
        inputLine = line.strip()
        # deal with input commands by looking at the line
        if len(line) == 0:
            self.reportError(line, "Invalid command: EMPTY LINE.")
            return
        # record the input line
        self.fp.write("Received from client:\n" + inputLine + ".\n")
        # figure out the command
        inputArgs = inputLine.split()
        cmd = inputArgs[0]

        # different cases based on the value of cmd
        if cmd == "IAMAT":
            self.handle_IAMAT(inputLine)
        elif cmd == "AT":
            self.handle_AT(inputLine)
        elif cmd == "WHATSAT":
            self.handle_WHATSAT(inputLine)
        else: # invalid commands
            self.reportError(inputLine, "Invalid command. Valid command should be IAMAT/AT/WHATAT.")

        
        #Servers should respond to invalid commands with a line that 
        #contains a question mark (?), a space, and then a copy of the invalid command.
    def reportError(self, inputCommand, ErrorMsg):
        s = "? " + inputCommand
        self.sendLine(s)
        # record in out log
    	self.fp.write("Server Message:\n{0}; Error Message: {1}\n".format(s,ErrorMsg))

    def handle_IAMAT(self, inputLine):
        inputArgs = inputLine.split()
        # IAMAT kiwi.cs.ucla.edu +34.068930-118.445127 1479413884.392014450
        if len(inputArgs) != 4:
            self.reportError(inputLine, "Wrong number of arguments. Check again.")
            return
        # self.name = inputArgs[1] # client ID: kiwi.cs.ucla.edu
        clientID = inputArgs[1]  # client ID: kiwi.cs.ucla.edu
        loc = inputArgs[2] # latitude and longitude
        # check the format
    	if loc.count("+") + loc.count("-") != 2 or loc.count(".") > 2:
            self.reportError(inputLine, "Wrong location format. Check again.")
            return
        # correct # of input arguments, correct location format, need to parse the
    	# location into latitude and longitude
    	formalizedLocation = loc.replace("+"," +").replace("-"," -").split()
        # check the format of latitude and longitude
        if len(formalizedLocation) != 2:
            self.reportError(inputLine, "Wrong location format. Check again.")

        latitude = formalizedLocation[0]
        longitude = formalizedLocation[1]

        if (not float(latitude)) or (not float(longitude)):
            self.reportError(inputLine, "Invalid latitude or longitude. Check again.")

        time = inputArgs[3]
        if not float(time):
            self.reportError(inputLine, "Wrong time format. Check again.")
            return

        # prepare to store the message
    	copy = inputArgs[1] + " " + inputArgs[2] + " " + inputArgs[3]
        #self.clients[self.name] = copy
        msg = self.formMSG(time, copy)
        # before we store the message, we need to check whether the new info is outdated.
        if clientID not in self.clients:
            self.name = clientID
            self.clients[self.name] = msg
            self.sendLine(msg)
            self.fp.write("Server Message:\n" + msg + "\n")
            self.flooding(msg, "StartServer", "StartServer")
        elif msg != self.clients[clientID]:
            oldTime = float(self.clients[clientID].split()[-1])
            if float(time) < oldTime:
                self.sendLine("Outdated Information.\n")
                self.reportError(inputLine, "Outdated attempt. Check again")
            else:
                self.clients[clientID] = msg
                self.sendLine(msg)
                self.fp.write("Server Message:\n" + msg + "\n")
                self.flooding(msg, "StartServer", "StartServer")

    # The server should respond to clients with a message using this format:
    #	AT Alford +0.263873386 kiwi.cs.ucla.edu +34.068930-118.445127 1479413884.392014450
    def formMSG(self, ctime, copy):
        # the difference between the server's idea of when it got the message from the client
    	# and the client's time stamp
    	# time.time(): 
    	#	Return the time in seconds since the epoch as a floating point number
    	diff = str(time.time() - float(ctime))
        # add "+" if diff is positive
    	if diff[0] != "-":
            diff = "+" + diff
        # append
    	s = "AT " + self.server + " " + diff + " " + copy
        return s

    def flooding(self, msg, orig, start):
        for servers in self.connectedServers:
            if servers != orig and servers != start:
                self.fp.write("Propagate to " + servers + "\n")
                reactor.connectTCP("localhost", conf.PORT_NUM[servers], PropagateFactory(msg, self.fp)) #!!!!!
            #  connectTCP(host, port, factory, timeout=30, bindAddress=None)

    def handle_AT(self, inputLine):
        inputArgs = inputLine.split()
        if len(inputArgs) != 6:
            self.reportError(inputLine, "Wrong number of arguments. Check again.")
            return

        orig = inputArgs[1]
        clientID = inputArgs[3]
        clientTime = float(inputArgs[5])

        if orig not in conf.PORT_NUM:
            self.reportError(inputLine, "Invalid Server Name. Check again.")
            return

        # Two cases, either the client is in in our client list or not
        #s = inputArgs[3] + " " + inputArgs[4] + " " + inputArgs[5]
        inputArgs[1] = self.server
        newMsg = " ".join(inputArgs)

        if clientID not in self.clients:
            self.clients[clientID] = inputLine
            self.fp.write("Propagation: " + inputLine + "\n")
            self.flooding(inputLine, self.server, orig)
        # ???????
        elif inputLine != self.clients[clientID]:
            oldTime = float(self.clients[clientID].split()[-1])
            if oldTime < clientTime:
                self.clients[clientID] = inputLine
                self.fp.write("Propagation: " + inputLine + "\n")
                self.flooding(inputLine, self.server, orig)

    def handle_WHATSAT(self, inputLine):
        inputArgs = inputLine.split()
        if len(inputArgs) != 4:
            self.reportError(inputLine, "Wrong number of arguments. Check again.")
            return
        # WHATSAT kiwi.cs.ucla.edu 10 5
        clientID = inputArgs[1]
        radius = inputArgs[2]
        upperbound = inputArgs[3]

        # format checking
        if not float(radius):
            self.reportError(inputLine, "Invalid radius. Check again.")
            return
        if not int(upperbound):
            self.reportError(inputLine, "Invalid upper bound. Check again.")
            return
        radius = float(radius)
        if radius <= 0 or radius > 50:
            self.reportError(inputLine, "Radius out of range. Check again.")
            return
        upperbound = int(upperbound)
        if upperbound <= 0 or upperbound > 20:
            self.reportError(inputLine, "Upper bound out of range. Check again.")
            return

        if clientID not in self.clients:
            self.reportError(inputLine, "Cannot find client ID. Check again.")
            return

        #locInfo = self.clients[clientID].split()[1]
        locInfo = self.clients[clientID].split()[4]
        location = locInfo.replace("+"," +").replace("-"," -").split()
        latitude = location[0]
        longitude = location[1]
        radius = radius*1000
        prefix = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location="
        suffix = "{0},{1}&radius={2}&key={3}".format(latitude,longitude,radius,conf.API_KEY)
        addr = prefix + suffix
        
        #def getPage(url, *args, contextFactory=None, **kwargs): (source)
	    #   Download a web page as a string.
	    #   Download a page. Return a deferred, which will callback with a page (as a string) 
		#					or errback with a description of the error.
	    #   See HTTPClientFactory to see what extra arguments can be passed.
        
        d = getPage(addr).addCallback(self.handle_JSON, upperbound = upperbound, clientID = clientID) # deferred
        #  addCallback(callback, *callbackArgs, **callbackKeywords)
		# http://stackoverflow.com/questions/7891062/how-to-pass-extra-arguments-to-callback-register-functions-with-twisted-python-a
        #d.addCallback(self.handle_JSON, upperbound = upperbound, clientID = clientID)
        d.addErrback(self.handle_Errorback, inputLine = inputLine)

    def handle_JSON(self, result, upperbound, clientID):
        atMsg = json.loads(result)
        # only preserve data within the upperbound
        atMsg["results"] = atMsg["results"][:upperbound]
        #convert back to JSON style specified by the spec
		#? sequence of two or more adjacent newlines is replaced by a single newline
		#all trailing newlines are removed
		#followed by two newlines
		#Documentation of json.dumps:
		#	indent = 3 (according to spec)
		#	separators: Use (',', ': ') as default if indent is not None
		
        jsonMsg = json.dumps(atMsg, indent = 3, separators = (',', ': '))
        stored = self.clients[clientID]
        #raw = self.formMSG(stored.split()[-1], stored) + "\n" + jsonMsg
        raw = stored + "\n" + jsonMsg
        wellformed = raw.rstrip("\n") + "\n\n"
        self.transport.write(wellformed)
        self.fp.write("Response from Google API:\n" + wellformed + "\n")

    def handle_Errorback(self, error, inputLine):
        self.reportError(inputLine, error)


class ServerFactory(Factory):
    numOfConnections = 0

    def __init__(self):
        self.name = serverName
        self.clients = {}
        self.file = fileName

    def buildProtocol(self, addr):
        return Server(self)
    
    def startFactory(self):
        # This can be used to perform 'unserialization' tasks that are best put off 
        # until things are actually running, such as connecting to a database, opening files, etcetera.
        self.fp = open(self.file, 'a') # 'a' opens the file for appending
        self.fp.write("Starting server...\nThis is the log file for {0}\n\n".format(self.name))

    # This will be called before I stop listening on all Ports/Connectors.
    def stopFactory(self):
        self.fp.write("Stopping server...\nEnd for server {}\n\n".format(self.name))
        self.fp.close()


class PropagateProtocol(Protocol):
    def __init__(self, msg):
        self.msg = msg

    def connectionMade(self):
        self.transport.write(self.msg)
        self.transport.loseConnection()

class PropagateFactory(ClientFactory):
    def __init__(self, msg, fp):
        self.msg = msg + "\r\n" # end of line
        self.fp = fp

    def buildProtocol(self, addr):
        return PropagateProtocol(self.msg)

    def startedConnecting(self, connector):
        self.fp.write("Started to connect.\n")

    def clientConnectionLost(self, connector, reason):
        self.fp.write("Lost connection.  Reason: {0}\n".format(reason))

    def clientConnectionFailed(self, connector, reason):
        self.fp.write("Connection failed. Reason: {0}\n".format(reason))


def main():
    #	check the number of input arguments
    if len(sys.argv) != 2:
        print "Error: wrong number of arguments."
        exit(1)
    # check serverName
    if serverName not in conf.PORT_NUM:
        print "Error: Invalid server name. \n"
        exit(1)
    # get port number

    port_num = conf.PORT_NUM[serverName]
    reactor.listenTCP(port_num, ServerFactory())
    reactor.run()

if __name__ == "__main__":
    main()
