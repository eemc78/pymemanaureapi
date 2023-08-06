

module.exports = (router) => {
  router.post('/api/visita', (req, res, next) => {
    let archivos = req.files ? req.files.files || req.files.archivos : [];
    let { id, nombre, apellido, dni, telefono, email, direccion, fecha, hora, motivo, observaciones } = req.body;

    return res.json({
      res: "ok",
      result: req.body,
    });
  });

  // router.use('/api/json', router);
}