const model = require("../models/usuario_model");

module.exports = (router) => {
  router.post('/api/usuario/login', (req, res, next) => {
    const { usuario, clave } = req.body;
    if (usuario && clave) {
      model.login(req.pool, { usuario, clave }, async (results, err) => {
        if (err) return res.status(500).json({ res: "ko", error: err });
        if (results.length <= 0) return res.status(401).json({ res: "ko", error: "Usuario y/o clave incorrecto!" });
        let user = results[0];
        if (+user.activo === 0) return res.status(401).json({ res: "ko", error: "Usuario inactivo!" });
        let userData = {
          id: user.id,
          usuario: usuario,
          nombres: user.nombres,
          apellidos: user.apellidos,
        }
        let token = require("../lib/jwt").createJWToken({ sessionData: userData })

        if (user.avatar) {
          try {
            let archivos = await new Promise((resolve, reject) => {
              require("../models/archivos_model").get_archivo(req.pool, { id: user.avatar }, (results, err) => {
                if (err) return reject(err);
                return resolve(results);
              })
            });

            if (archivos.length > 0) {
              let fs = require('fs');
              let path = require('path');
              let archivo = archivos[0];
              let base64 = fs.readFileSync(path.join(__dirname, '..', archivo.path)).toString('base64');
              user.avatar  = `data:${archivo.tipo};base64,${base64}`;
            }

          } catch (error) {
            // Debug error
            console.error(error);
            user.avatar = null;
          }
        }

        return res.json({
          res: "ok",
          result: user,
          token: token
        });
      })

    } else {
      res.status(400).send('Ingrese el usuario y la contraseña!');
      res.end();
    }
  });

  router.put('/api/usuario/perfil', async (req, res, next) => {
    const { clave, nombres, apellidos, } = req.body;
    let avatar = req.files ? req.files.avatar : null;

    // convertir el avatar a base64
    if (avatar) {

      const fs = require('fs');
      const mime = require('mime');
      const ext = mime.getExtension(avatar.mimetype);
      // If not exists uploads folder, create it
      if (!fs.existsSync('./uploads')) {
        fs.mkdirSync('./uploads');
      }

      // Move the file to the uploads folder
      let random = Math.floor(Math.random() * 1000000);
      let name = `${random}.${ext}`;
      avatar.mv('./uploads/' + name);

      try {
        let res = await new Promise((resolve, reject) => {
          require('../models/archivos_model').guardar_archivo(req.pool,
            {
              usu_id: req.user.id,
              nombre: avatar.name,
              nombre_archivo: name,
              tipo: avatar.mimetype,
              extension: ext,
              path: "/uploads/" + name,
            }, (results, err) => {
              if (err) return reject(err);
              resolve(results);
            });
        });
        avatar = res.insertId;
      } catch (error) {
        return res.status(500).json({ res: "ko", error });
      }
      // avatar = null;
    }

    model.perfil(req.pool, { id: req.user.id, clave, nombres, apellidos, avatar }, (results, err) => {
      if (err) return res.status(500).json({ res: "ko", error: err });
      return res.json({
        res: "ok",
        result: results,
      });
    });
  });

  // router.use('/api/usuario', router);
}