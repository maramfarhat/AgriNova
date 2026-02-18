const WebSocket = require("ws");
const wss = new WebSocket.Server({ port: 3000 });

let clients = [];

wss.on("connection", (ws) => {
  console.log("🟢 Nouveau client connecté !");
  clients.push(ws);

  ws.on("message", (message) => {
    console.log("Message reçu :", message.toString());

    // Rediffusion à tous les clients sauf l’expéditeur
    clients.forEach(client => {
      if (client !== ws && client.readyState === WebSocket.OPEN) {
        client.send(message.toString());
      }
    });
  });

  ws.on("close", () => {
    console.log("🔴 Client déconnecté.");
    clients = clients.filter(c => c !== ws);
  });
});

console.log("✅ Serveur WebSocket lancé sur ws://localhost:3000");
