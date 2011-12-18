(function() {
  /*
   Include libraries.
  */
  var SECRET, User, Word, WordModel, WordSchema, app, c, express, findOptions, findRecentWords, getLastDoc, https, io, lastDoc_, mongoose, oathQuery, oathScopes, oathUrl, postLocked, querystring, updateWords, url, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  c = console.log;
  SECRET = require('secret-strings').LAST_FIRST;
  _ = require("underscore");
  require('./underscore_extention');
  express = require("express");
  mongoose = require("mongoose");
  url = require('url');
  querystring = require('querystring');
  https = require('https');
  c('"""""""""""""""""""""""""""""""""""""""""""');
  c(_.isValidLastFirst('あひる', 'るびい'));
  /*
   DB setting.
  */
  WordSchema = new mongoose.Schema({
    content: String,
    createdBy: String,
    createdAt: Date,
    nice: {
      type: Number,
      "default": 0
    }
  });
  mongoose.model('WordModel', WordSchema);
  mongoose.connect('mongodb://localhost/lastFirstDB');
  WordModel = mongoose.model('WordModel');
  findOptions = {
    sort: [['createdAt', 'descending']],
    limit: 5
  };
  /*
   App initialize.
  */
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
  /*
   Class for user.
  */
  User = (function() {
    User.prototype.socket = null;
    User.prototype.id = '';
    User.prototype.token = '';
    User.prototype.isValid = false;
    function User(socket) {
      this.socket = socket;
    }
    User.prototype.setToken = function(token) {
      this.token = token;
    };
    User.prototype.validate = function() {
      var options;
      if (!this.socket || !this.token) {
        return;
      }
      options = {
        host: 'www.googleapis.com',
        path: '/oauth2/v1/tokeninfo?access_token=' + this.token
      };
      c('before https.get');
      return https.get(options, __bind(function(res) {
        return res.on('data', __bind(function(data) {
          var json;
          json = JSON.parse(data.toString());
          c('got res from https.get', json);
          if (!json.error) {
            c('validate successfully.');
            this.id = json.user_id;
            this.isValid = true;
            this.socket.emit('validated nicely!', {
              userId: this.id
            });
            return updateWords(this.socket);
          } else {
            c('need login.');
            return this.socket.emit('need login');
          }
        }, this));
      }, this));
    };
    return User;
  })();
  /*
   Singleton class for managing users.
  */
  /*
   Class for word.
  */
  Word = (function() {
    Word.prototype.content = null;
    Word.prototype.lastLetter = null;
    Word.prototype.createdBy = null;
    Word.prototype.createdAt = null;
    Word.prototype.model_ = null;
    Word.prototype.isSaved = false;
    function Word(post) {
      if (_.keys(post).length === 2 && post.content && post.createdBy) {
        this.model_ = new WordModel();
        this.model_.createdAt = new Date();
        this.model_ = _.extend(this.model_, post);
        this.lastLetter = _.last(post);
      } else {
        c('something goes wrong..');
      }
    }
    Word.prototype.save = function(fn) {
      if (this.model_) {
        this.model_.save(fn);
        return this.isSaved = true;
      }
    };
    return Word;
  })();
  findRecentWords = function(fn) {
    return WordModel.find({}, [], findOptions, fn);
  };
  lastDoc_ = {};
  getLastDoc = function() {
    return lastDoc_ || {};
  };
  updateWords = function(socket) {
    return findRecentWords(function(err, docs) {
      lastDoc_ = docs[0];
      return socket.emit('update', docs);
    });
  };
  /*
   Socket IO listening.
  */
  postLocked = false;
  io.sockets.on('connection', function(socket) {
    var user;
    user = new User(socket);
    updateWords(socket);
    socket.on('got token', function(data) {
      var token;
      c('got token!!!!!!! from client');
      token = data.token;
      user.setToken(token);
      return user.validate();
    });
    return socket.on('post word', function(post) {
      var word;
      console.log('--------------------------------------');
      console.log(getLastDoc().content);
      if (!user.isValid) {
        return socket.emit('error message', {
          message: 'you bad boy.'
        });
      } else if (postLocked) {
        return socket.emit('error message', {
          message: 'post conflicted with someones post!'
        });
      } else if (!_.isValidWord(post.content)) {
        return socket.emit('error message', {
          message: 'Do you speak japanese?'
        });
      } else if (!_.isValidLastFirst(getLastDoc().content, post.content)) {
        return socket.emit('error message', {
          message: 'I\'m not sure it\'s being Last and First.'
        });
      } else {
        postLocked = true;
        word = new Word(post);
        return word.save(function(err) {
          postLocked = false;
          if (!err) {
            socket.emit('posted successfully', post);
            return updateWords(io.sockets);
          }
        });
      }
    });
  });
  oathScopes = ['https://www.googleapis.com/auth/userinfo.profile'];
  oathQuery = {
    response_type: 'token',
    scope: oathScopes.join('+'),
    redirect_uri: 'http://localhost:3000/oauth2callback',
    client_id: SECRET.GOOGLE_OAUTH_CLIENT_IE
  };
  oathUrl = 'https://accounts.google.com/o/oauth2/auth?' + querystring.stringify(oathQuery);
  app.get("/", function(req, res) {
    return res.render("index", {
      title: "LastFirstApp",
      oathUrl: oathUrl
    });
  });
  app.get("/dev", function(req, res) {
    return res.render("dev", {
      title: "dev"
    });
  });
  app.get("/oauth2callback", function(req, res) {
    var token;
    token = req.query.code;
    return res.render("oauth2callback", {
      layout: false,
      title: "LastFirstApp"
    });
  });
  app.listen(SECRET.PORT);
}).call(this);
