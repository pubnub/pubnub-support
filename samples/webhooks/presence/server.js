var express = require("express");
var inspect  = require('util').inspect;

var bodyParser = require("body-parser");
var Busboy = require('busboy');
var app = express();
app.use(bodyParser.json({ type: 'application/json' }))

app.listen(process.env.PORT || 3000, function(){
  console.log("Express server listening on port %d in %s mode", this.address().port, app.settings.env);
});

app.post("/join", (request, response) => {
    console.log("JOIN - request.body: ", request.body);
    response.status(200).end();
});

app.post("/leave", (request, response) => {
    console.log("LEAVE - request.body: ", request.body);
    response.status(200).end();
});

app.post("/timeout", (request, response) => {
    console.log("TIMEOUT - request.body: ", request.body);
    response.status(200).end();
});

app.post("/statechange", (request, response) => {
    console.log("STATE CHANGE - request.body: ", request.body);
    response.status(200).end();
});

app.post("/active", (req, res) => {
  parseMultiPart("ACTIVE", req, res);
});

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
