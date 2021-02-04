// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

'use strict';

const defaultPort = (typeof process.env.SS_PORT !== 'undefined')
  ? process.env.SS_PORT
  : '80'

const program = require('commander');
program
  .version('1.0.0')
  .requiredOption('-s, --service <name>', 'name of service')
  .option('-d, --downstream-service <name>', 'name of downstream service to invoke')
  .option('-e, --downstream-path <path>', 'Http path for downstream service')
  .option('-p, --port <port>', 'server port', defaultPort)
  .parse(process.argv);

const port = parseInt(program.port)
const service = program.service.trim();

const express = require('express');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: true}));


const axios = require('axios');

// Constants
const HOST = '0.0.0.0';

function format(o, pretty) {
  return (pretty)
    ? JSON.stringify(o, null, 2) + '\n'
    : JSON.stringify(o);
}

const servicePath = `/${service}`
console.log(`Service path: ${servicePath}`)

app.get(servicePath, function(req, res) {

  let pretty = (typeof req.query.pretty !== 'undefined');
  let timestamp = Date.now();
  res.set('Cache-Control', 'no-cache');

  if (program.downstreamService != undefined) { // Call downstream service
    console.log("Calling downstream service")
    const downstreamService = program.downstreamService.trim();

    const downstreamPath = (program.downstreamPath != undefined)
      ? program.downstreamPath.trim()
      : '/'

    const downstreamServicePath = 'http://' + downstreamService + downstreamPath
    console.log(`Downstream service path: ${downstreamServicePath}`)

    axios.get(
      downstreamServicePath, { responseType: 'json' }
    )
    .then(function(response) {
      res.type('json').send(
        format({
//          "Timestamp" : timestamp,
          "Service" : service,
          "Downstream" : response.data
        },pretty)
      );
    })
    .catch(function(error) {
      console.log(JSON.stringify(error));
      console.trace();
      return Promise.reject(error);
      //      return console.log(error.toJSON());
    })
  }
  else {
    res.type('json').send(
      format({
//        "Timestamp" : timestamp,
        "Service" : service
      },pretty)
    );
  }
});
app.get('/ping', (req, res) => {
  res.send("ok");
});

app.listen(port, HOST);
console.log(`Service running on http://${HOST}:${port}`);
console.log(`Service name: "${service}"`)
