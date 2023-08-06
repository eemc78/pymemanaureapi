

module.exports = (router) => {
  router.post('/api/read/', (req, res, next) => {
    const { table } = req.body;
    const usuario_id = req.user?.id;
    const { select } = require("../models/read_model");
    if (table) {
      select(req.pool, req.body, usuario_id, (results, err) => {
        if (err) return res.status(500).json({ res: "ko", error: err });
        return res.json({
          res: "ok",
          result: results,
          token: req.token
        });
      })
      // require("../models/usuario_model").login(req.pool, { usuario, clave }, (results, err) => {
      //   if (err) return res.status(500).json({ res: "ko", error: err });
      //   if (results.length <= 0) return res.status(401).json({ res: "ko", error: "Usuario y/o clave incorrecto!" });
      //   let user = results[0];
      //   if (+user.activo === 0) return res.status(401).json({ res: "ko", error: "Usuario inactivo!" });
      //   let userData = {
      //     id: user.id,
      //     usuario: usuario,
      //     nombres: user.nombres,
      //     apellidos: user.apellidos,
      //   }
      //   let token = require("../lib/jwt").createJWToken(userData)
      //   return res.json({
      //     res: "ok",
      //     result: user,
      //     token: token
      //   });
      // })
      // res.json({
      //   res: "ok",
      //   result: req.body,
      // });

    } else {
      res.status(400).send('Ingrese cuando menos el nombre de la tabla!');
      res.end();
    }
  });

  // router.use('/api/read', router);
}