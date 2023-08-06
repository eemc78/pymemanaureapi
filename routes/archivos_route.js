const model = require("../models/archivos_model");

module.exports = (router) => {
  router.post('/api/archivos/', async (req, res, next) => {
    let archivos = req.files ? req.files.files || req.files.archivos : [];
    if (archivos.length <= 0) return res.status(400).json({ res: "ko", error: "No se encontraron archivos!" });
    let idArchivos = [];
    for (let i = 0; i < archivos.length; i++) {
      const archivo = archivos[i];
      const fs = require('fs');
      const mime = require('mime');
      const ext = mime.getExtension(archivo.mimetype);
      if (!fs.existsSync('./uploads')) {
        fs.mkdirSync('./uploads');
      }
      let path = `./uploads/${archivo.md5}.${ext}`;
      archivo.mv(path);

      try {
        let res = await new Promise((resolve, reject) => {
          require('../models/archivos_model').guardar_archivo(req.pool,
            {
              usu_id: req.user.id,
              nombre: archivo.name,
              tipo: archivo.mimetype,
              extension: ext,
              path: path,
            }, (results, err) => {
              if (err) return reject(err);
              resolve(results);
            });
        });
        idArchivos.push({
          id: res.insertId,
          nombre: archivo.name,
          tipo: archivo.mimetype,
          extension: ext,
          path: path,
        });
      } catch (error) {
        return res.status(500).json({ res: "ko", error });
      }

    }
    return res.json({
      res: "ok",
      result: idArchivos,
    });
  });
  router.get('/api/archivos/:id', async (req, res, next) => {
    const id = req.params.id;
    try {
      let archivos = await new Promise((resolve, reject) => {
        require('../models/archivos_model').get_archivo(req.pool,
          {
            id: id,
          }, (results, err) => {
            if (err) return reject(err);
            resolve(results);
          });
      });
      let archivo = null
      if (archivos.length <= 0) return res.status(404).json({ res: "ko", error: "Archivo no encontrado!" });
      else {
        archivo = archivos[0];
        let fs = require('fs');
        let path = require('path');
        let base64 = fs.readFileSync(path.join(__dirname, '..', archivo.path)).toString('base64');
        archivo.base64 = `data:${archivo.tipo};base64,${base64}`;
      }

      return res.json({
        res: "ok",
        result: archivo,
      });
    } catch (error) {
      return res.status(500).json({ res: "ko", error });
    }
  });
}