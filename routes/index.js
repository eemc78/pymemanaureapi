var express = require('express');
var router = express.Router();

/* GET home page. */
router.get('/', function (req, res, next) {
  res.render('index', { title: 'Pyme' });
});

require('./usuario_route')(router);
require('./read_route')(router);
require('./json_route')(router);
require('./archivos_route')(router);
require('./visita_route')(router);

if (false)
  router.post('/api/usuario/login', (req, res) => {
    const { usuario, clave } = req.body;
    const pool = req.pool;
    if (usuario && clave) {
      pool.getConnection((err, conn) => {
        if (err) return res.status(500).json({ res: "ko", error: err });
        pool.query('SELECT * FROM usu WHERE usuario = ? AND clave = MD5(?)', [usuario, clave], (err, results, fields) => {
          conn.release();
          if (err) return res.status(500).json({ res: "ko", error: err });

          if (results.length <= 0) {
            return res.status(401).json({ res: "ko", error: "Incorrect Username and/or Password!" });
          }
          else {
            let user = results[0];
            if (+user.activo === 0) return res.status(401).json({ res: "ko", error: "Usuario inactivo!" });
            let userData = {
              id: user.id,
              usuario: usuario,
              nombres: user.nombres,
              apellidos: user.apellidos,
            }
            let token = require("../lib/jwt").createJWToken(userData)
            return res.json({
              res: "ok",
              data: results,
              token: token
            });
          }

        });
      })
    } else {
      res.status(400).send('Ingrese el usuario y la contraseña!');
      res.end();
    }
  });

module.exports = router;
