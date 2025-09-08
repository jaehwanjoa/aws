const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('Fixable Vulnerable Node.js Project for SCA Testing');
});

app.listen(port, () => {
  console.log(`App listening at http://localhost:${port}`);
});
