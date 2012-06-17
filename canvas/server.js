var node_static = require('node-static');
var http = require('http');

var spawn = require('child_process').spawn;

var exec = function(cmd, args, cb) {
  var bin;
  if (args == null) args = [];
  if (cb == null) cb = function() {};
  bin = spawn(cmd, args);
  bin.stdout.on('data', function(data) {
    process.stdout.write(data);
  });
  bin.stderr.on('data', function(data) {
    process.stderr.write(data);
  });
  bin.on('exit', cb);
};

var is_dev_mode = process.env.npm_package_config_development_mode === 'true';
var makeAssetsIfDev = function(cb) {
  if (is_dev_mode) {
    exec("cake", ["build"], cb);
  } else {
    cb();
  }
};

var file_server = new node_static.Server("./public");
var app = http.createServer(function(request, response) {
  makeAssetsIfDev(function() {
    file_server.serve(request, response);
  });
}).listen(process.env.npm_package_config_port);

console.info("Serving at http://localhost:" + process.env.npm_package_config_port + "/");

