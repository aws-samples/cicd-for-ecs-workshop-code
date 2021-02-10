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
  .option('-u, --upstream-service <name>', 'name of upstream service to invoke')
  .option('-e, --upstream-path <path>', 'Http path for upstream service')
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

  if (program.upstreamService != undefined) { // Call upstream service
    console.log("Calling upstream service")
    const upstreamService = program.upstreamService.trim();

    const upstreamPath = (program.upstreamPath != undefined)
      ? program.upstreamPath.trim()
      : '/'

    const upstreamServicePath = 'http://' + upstreamService + upstreamPath
    console.log(`Upstream service path: ${upstreamServicePath}`)

    axios.get(
      upstreamServicePath, { responseType: 'json' }
    )
    .then(function(response) {
      res.type('json').send(
        format({
//          "Timestamp" : timestamp,
          "Service" : service,
          "Upstream" : response.data
        },pretty)
      );
    })
    .catch(function(error) {
      console.log(JSON.stringify(error));
      console.trace();
      res.type('json').send(
        format({
          "Service" : service,
          "Upstream error" : error
        },pretty)
      );
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
