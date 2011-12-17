(function() {
  /*
   Include libraries.
  */
  var User, Users, Word, WordModel, WordSchema, app, express, findOptions, findRecentWords, https, io, mongoose, oathQuery, oathScopes, oathUrl, querystring, sendBadBoyMessage, updateWords, url, users, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  express = require("express");
  mongoose = require("mongoose");
  _ = require("underscore");
  url = require('url');
  querystring = require('querystring');
  https = require('https');
  /*
   Setting DB.
  */
  WordSchema = new mongoose.Schema({
    content: String,
    createdBy: String,
    createdAt: Date
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
        return false;
      }
      options = {
        host: 'www.googleapis.com',
        path: '/oauth2/v1/tokeninfo?access_token=' + this.token
      };
      return https.get(options, __bind(function(res) {
        return res.on('data', __bind(function(data) {
          var json;
          json = JSON.parse(data.toString());
          if (!json.error) {
            console.log(json);
            this.id = json.user_id;
            this.isValid = true;
            this.socket.emit('validated nicely!', {
              user_id: this.id
            });
            return updateWords(this.socket);
          } else {
            return this.socket.emit('validation fail', {
              error: 'too bad.'
            });
          }
        }, this));
      }, this));
    };
    return User;
  })();
  /*
   Singleton class for managing users.
  */
  Users = (function() {
    function Users(id, token) {
      this.id = id;
      this.token = token;
    }
    Users.prototype.users_ = [];
    Users.prototype.add = function(user) {
      return this.users_.push(user);
    };
    Users.prototype.remove = function(id) {
      return _.find(this.users_, function(user) {
        if (user.id === id) {
          this.users_[_i].splice();
          return true;
        }
      });
    };
    Users.prototype.has = function(idOrToken) {
      return _.find(this.users_, function(user) {
        return user.id === idOrToken || user.token === idOrToken;
      });
    };
    return Users;
  })();
  users = new Users();
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
      if (_.keys(post).length === 3 && post.content && post.createdBy && post.createdAt) {
        this.model_ = new WordModel();
        this.model_ = _.extend(this.model_, post);
        this.lastLetter = _.last(post);
      } else {
        console.log('something goes wrong..');
      }
    }
    Word.prototype.save = function(fn) {
      this.model_.save(fn);
      return this.isSaved = true;
    };
    return Word;
  })();
  findRecentWords = function(fn) {
    return WordModel.find({}, [], findOptions, fn);
  };
  updateWords = function(socket) {
    return findRecentWords(function(err, docs) {
      return socket.emit('update', docs);
    });
  };
  sendBadBoyMessage = function(socket) {
    return socket.emit('bad boy', {
      error: 'you bad body.'
    });
  };
  /*
   Socket IO listening.
  */
  io.sockets.on('connection', function(socket) {
    var user;
    user = new User(socket);
    updateWords(socket);
    socket.on('got token', function(data) {
      var token;
      token = data.token;
      if (!users.has(token)) {
        user.setToken(token);
        users.add(user);
        return user.validate();
      }
    });
    return socket.on('post word', function(post) {
      var word;
      if (!user.isValid) {
        sendBadBoyMessage(socket);
        return;
      }
      word = new Word(post);
      return word.save(function(err) {
        if (!err) {
          socket.emit('posted successfully', post);
          return updateWords(io.sockets);
        }
      });
    });
  });
  oathScopes = ['https://www.googleapis.com/auth/userinfo.profile'];
  oathQuery = {
    response_type: 'token',
    scope: oathScopes.join('+'),
    redirect_uri: 'http://localhost:3000/oauth2callback',
    client_id: '381639783208.apps.googleusercontent.com'
  };
  oathUrl = 'https://accounts.google.com/o/oauth2/auth?' + querystring.stringify(oathQuery);
  app.get("/", function(req, res) {
    return res.render("index", {
      title: "LastFirstApp",
      oathUrl: oathUrl
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
  app.listen(3000);
}).call(this);
