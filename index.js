var http = require('http');
var host = process.env.HOST
var port = process.env.PORT

server = http.createServer(function myRequestListener(req, res) {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Hello World\n');
  res.not_a_function()
}).listen(port, host);

console.log(`Server process ${process.pid} running at http://${host}:${port}/`);
