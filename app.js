(function() {
  /*
   Include libraries.
  */
  var SECRET, User, Word, WordModel, WordSchema, app, express, findOptions, findRecentWords, getInitialWord, getLastDoc, https, io, lastDoc_, mongoose, oathQuery, oathScopes, oathUrl, penaltyUserIds, querystring, saveInitialWord, setPenaltyUser, updateWords, updateWords_, url, users, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  SECRET = require('secret-strings').LAST_FIRST;
  _ = require("underscore");
  require('./underscore_extention');
  express = require("express");
  mongoose = require("mongoose");
  url = require('url');
  querystring = require('querystring');
  https = require('https');
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
    User.prototype.isValid_ = false;
    User.prototype.isValid = function() {
      return this.isValid_;
    };
    User.prototype.setValid = function(valid) {
      return this.isValid_ = valid;
    };
    function User(socket) {
      this.socket = socket;
    }
    User.prototype.setToken = function(token) {
      this.token = token;
    };
    User.prototype.validate = function(fn) {
      var options;
      if (!this.socket || !this.token) {
        return;
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
            this.id = json.user_id;
            this.isValid_ = true;
            this.socket.emit('validated nicely!', {
              userId: this.id
            });
            updateWords(this.socket);
            return fn();
          } else {
            return this.socket.emit('need login');
          }
        }, this));
      }, this));
    };
    return User;
  })();
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
  getInitialWord = function() {
    var obj;
    return obj = {
      content: 'しりとり',
      createdBy: 'initial post by server'
    };
  };
  saveInitialWord = function(fn) {
    var word;
    word = new WordModel();
    word = _.extend(word, getInitialWord());
    return word.save(fn);
  };
  findRecentWords = function(fn) {
    return WordModel.find({}, [], findOptions, fn);
  };
  lastDoc_ = {};
  getLastDoc = function() {
    return lastDoc_ || {};
  };
  updateWords_ = function(socket, err, docs) {
    if (err) {
      return;
    }
    lastDoc_ = docs[0];
    return socket.emit('update', docs);
  };
  updateWords = function(socket) {
    return findRecentWords(function(err, docs) {
      if (_.isEmpty(docs)) {
        return saveInitialWord(updateWords_.bind(this, socket));
      } else {
        return updateWords_(socket, err, docs);
      }
    });
  };
  /*
   Socket IO listening.
  */
  users = {};
  penaltyUserIds = [];
  setPenaltyUser = function(user) {
    penaltyUserIds.push(user.id);
    return _.delay(function() {
      penaltyUserIds = _.without(penaltyUserIds, user.id);
      user = users[user.id];
      if (user) {
        return user.socket.emit('release penalty', {
          message: 'Now you can post.'
        });
      }
    }, 60 * 60 * 1000);
  };
  /*
   Singleton class for managing users.
  */
  io.sockets.on('connection', function(socket) {
    var user;
    user = new User(socket);
    updateWords(socket);
    socket.on('got token', function(data) {
      var token;
      token = data.token;
      user.setToken(token);
      return user.validate(function() {
        users[user.id] = user;
        if (_.include(penaltyUserIds, user.id)) {
          return socket.emit('got penalty', {
            message: 'ん! you can\'t post for a while.'
          });
        }
      });
    });
    socket.on('post word', function(post) {
      var postLocked, word, word1;
      if (!user.isValid()) {
        socket.emit('error message', {
          message: 'you bad boy.'
        });
      }
      if (_.include(penaltyUserIds, user.id)) {
        return socket.emit('error message', {
          message: 'ん! you can\'t post for a while.'
        });
      } else if (postLocked) {
        return socket.emit('error message', {
          message: 'post conflicted with someones post!'
        });
      } else if (!_.isValidWord(post.content)) {
        return socket.emit('error message', {
          message: 'Please enter a Japanese word in HIRAGANA.'
        });
      } else if (!_.isValidLastFirst(getLastDoc().content, post.content)) {
        return socket.emit('error message', {
          message: 'I\'m not sure it\'s being Last and First.'
        });
      } else if (_.isEndsN(post.content)) {
        setPenaltyUser(user);
        word1 = new Word(post);
        return word1.save(function() {
          var word2;
          word2 = new Word(getInitialWord());
          return word2.save(function() {
            updateWords(io.sockets);
            return socket.emit('got penalty', {
              message: 'ん! you can\'t post for a while.'
            });
          });
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
    return socket.on('disconnect', function() {
      if (users[user.id]) {
        return delete users[user.id];
      }
    });
  });
  oathScopes = ['https://www.googleapis.com/auth/userinfo.profile'];
  oathQuery = {
    response_type: 'token',
    scope: oathScopes.join('+'),
    redirect_uri: SECRET.GOOGLE_OAUTH_REDIRECT_TO,
    client_id: SECRET.GOOGLE_OAUTH_CLIENT_IE
  };
  oathUrl = 'https://accounts.google.com/o/oauth2/auth?' + querystring.stringify(oathQuery);
  app.get("/", function(req, res) {
    return res.render("index", {
      title: "LastFirstApp",
      oathUrl: oathUrl,
      isProduction: SECRET.IS_PRODUCTION
    });
  });
  app.get("/about", function(req, res) {
    return res.render("about", {
      title: "LastFirstApp - about",
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
