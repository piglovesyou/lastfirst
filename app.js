(function() {
  var Post, PostSchema, app, emitUpdateTo, express, io, mongoose, updateOptions, _;
  express = require("express");
  mongoose = require("mongoose");
  _ = require("underscore");
  PostSchema = new mongoose.Schema({
    name: String,
    title: String,
    body: String,
    createdAt: Date
  });
  mongoose.model('Post', PostSchema);
  mongoose.connect('mongodb://localhost/ndb');
  Post = mongoose.model('Post');
  app = module.exports = express.createServer();
  io = require('socket.io').listen(app);
  app.configure(function() {
    app.set("views", __dirname + "/views");
    app.set("view engine", "jade");
    app.use(express.bodyParser());
    app.use(express.methodOverride());
    app.use(app.router);
    return app.use(express.static(__dirname + "/public"));
  });
  app.configure("development", function() {
    return app.use(express.errorHandler({
      dumpExceptions: true,
      showStack: true
    }));
  });
  app.configure("production", function() {
    return app.use(express.errorHandler());
  });
  updateOptions = {
    sort: [['createdAt', 'descending']],
    limit: 5
  };
  emitUpdateTo = function(socket) {
    return Post.find({}, [], updateOptions, function(err, docs) {
      return socket.emit('update', docs.reverse());
    });
  };
  io.sockets.on('connection', function(socket) {
    emitUpdateTo(socket);
    return socket.on('post', function(data) {
      var post;
      post = new Post();
      if (_.isNull(data.body)) {
        data.body = '(empty body)';
      }
      post = _.extend(post, data);
      return post.save(function(err) {
        if (!err) {
          return emitUpdateTo(io.sockets);
        }
      });
    });
  });
  app.get("/", function(req, res) {
    return res.render("index", {
      title: "Express"
    });
  });
  app.listen(3000);
}).call(this);
