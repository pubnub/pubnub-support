/*
  This code is provided "as-is" with no implied warranty/support/etc. Use at
  your own risk and customize to your requirements as needed.

  Below, each event has a sepaare path but PubNub Presence Web Hooks can be
  configured so that each event has a separeate path (/active, /join, etc.)
  or one path to handle them all and you parse the action in your handler.
  But it is highly recommended that you have at least two web hook paths:
    - one for active/inactive
    - one for join/leave/timeout/statechange
  since active/inactive are multipart form (non-JSON) and the other
   are application/json format (see code below for clarity).
   Questions? Contact PubNub Support: https://support.pubnub.com
*/

var express = require("express");
var inspect  = require('util').inspect;

var bodyParser = require("body-parser");
var Busboy = require('busboy');
var app = express();
app.use(bodyParser.json({ type: 'application/json' }))

app.listen(process.env.PORT || 3000, function(){
  console.log("Express server listening on port %d in %s mode", this.address().port, app.settings.env);
});

// JOIN Web Hook URI = https://myserver.com:3000/join
app.post("/join", (request, response) => {
    console.log("JOIN - request.body: ", request.body);
    // do something but do not delay the 200 response or PubNub will try calling
    //   again after 5s of no response up to 3 times before it quits trying
    response.status(200).end();
});

// leave Web Hook URI = https://myserver.com:3000/leave
app.post("/leave", (request, response) => {
    console.log("LEAVE - request.body: ", request.body);
    // do something but do not delay the 200 response or PubNub will try calling
    //   again after 5s of no response up to 3 times before it quits trying
    response.status(200).end();
});

// timeout Web Hook URI = https://myserver.com:3000/timeout
app.post("/timeout", (request, response) => {
    console.log("TIMEOUT - request.body: ", request.body);
    // do something but do not delay the 200 response or PubNub will try calling
    //   again after 5s of no response up to 3 times before it quits trying
    response.status(200).end();
});

// statechange Web Hook URI = https://myserver.com:3000/statechange
app.post("/statechange", (request, response) => {
    console.log("STATE CHANGE - request.body: ", request.body);
    // do something but do not delay the 200 response or PubNub will try calling
    //   again after 5s of no response up to 3 times before it quits trying
    response.status(200).end();
});

// active Web Hook URI = https://myserver.com:3000/active
app.post("/active", (req, res) => {
  parseMultiPart("ACTIVE", req, res);
});

// inactive Web Hook URI = https://myserver.com:3000/inactive
app.post("/inactive", (req, res) => {
  parseMultiPart("INACTIVE", req, res);
});

function parseMultiPart(event, req, res) {
    console.log(event);

    var busboy = new Busboy({ headers: req.headers });

    busboy.on('file', function(fieldname, file, filename, encoding, mimetype) {
      console.log('File [' + fieldname + ']: filename: ' + filename + ', encoding: ' + encoding + ', mimetype: ' + mimetype);
      file.on('data', function(data) {
        console.log('File [' + fieldname + '] got ' + data.length + ' bytes');
      });
      file.on('end', function() {
        console.log('File [' + fieldname + '] Finished');
      });
    });

    busboy.on('field', function(fieldname, val, fieldnameTruncated, valTruncated, encoding, mimetype) {
      console.log('Field [' + fieldname + ']: value: ' + inspect(val));
    });

    busboy.on('finish', function() {
      console.log('Done parsing form!');
      res.writeHead(303, { Connection: 'close', Location: '/' });
      res.end();
    });

    req.pipe(busboy);
}
