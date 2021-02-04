// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

'use strict';

const port = (typeof process.env.PORT !== 'undefined')
  ? process.env.PORT
  : '80'

const express = require('express');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: true}));

// Constants
const HOST = '0.0.0.0';

function format(o, pretty) {
  return (pretty)
    ? JSON.stringify(o, null, 2) + '\n'
    : JSON.stringify(o);
}

app.get('/hello/:name', (req, res) => {
  var name = req.params.name
  let timestamp = Date.now();
  res.send("Hi there " + name + "<br><i>" + timestamp + "</i>") 
});
app.get('/ping', (req, res) => {
  res.send("ok");
});

const server = app.listen(port, HOST);
console.log(`Service running on http://${HOST}:${port}`);

process.on('SIGTERM', () => {
  console.info('SIGTERM signal received.');
  console.log('Closing http server.');
  server.close(() => {
    console.log('Http server closed.');
    process.exit(0);
  });
});
