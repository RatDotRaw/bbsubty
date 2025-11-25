const WebSocket = require('ws');
const server = new WebSocket.Server({ port: 4269 });

server.on('connection', (ws) => {
  console.log('Client connected');
  
  ws.on('message', (message) => {
    console.log(`Received: ${message}`);
    ws.send(`Echo: ${message}`);
  });
  
  ws.send('Welcome to the WebSocket server!');
});

console.log('WebSocket server started on port 4269');