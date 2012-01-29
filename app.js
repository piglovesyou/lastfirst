
/*
 Include libraries.
*/

var NO_AUTH_FOR_DEV, OAuth, SECRET, User, Word, Words, app, express, io, nib, oauthQuery, oauthScopes, oauthUrl, querystring, stylus, updateWords, url, users, validateResult, validateUtil, _;

SECRET = require('secret-strings').LAST_FIRST;

_ = require('underscore');

require('./lib/ext_validate');

express = require('express');

url = require('url');

querystring = require('querystring');

stylus = require('stylus');

nib = require('nib');

OAuth = require('oauth').OAuth;

/*
 DB setting.
*/

Words = require('./lib/words').Words;

/*
 Include resources.
*/

User = require('./lib/user').User;

Word = require('./lib/word').Word;

users = require('./lib/users').getInstance();

NO_AUTH_FOR_DEV = !SECRET.IS_PRODUCTION && SECRET.NO_AUTH_FOR_DEV;

/*
 App initialize.
*/

app = module.exports = express.createServer();

io = require('socket.io').listen(app);

app.configure(function() {
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(stylus.middleware({
    src: __dirname + '/public',
    compile: function(str, path) {
      return stylus(str).set('filename', path).set('compress', true).use(nib());
    }
  }));
  app.use(app.router);
  return app.use(express.static(__dirname + '/public'));
});

app.configure('development', function() {
  return app.use(express.errorHandler({
    dumpExceptions: true,
    showStack: true,
    force: true
  }));
});

app.configure('production', function() {
  return app.use(express.errorHandler());
});

updateWords = require('./lib/socket_util').updateWords;

/*
 Socket IO listening.
*/

validateUtil = require('./lib/validate_util');

validateResult = validateUtil.RESULT_TYPE;

io.sockets.on('connection', function(socket) {
  var user;
  user = new User(socket);
  socket.on('got token', function(data) {
    var token;
    token = data.token;
    user.setToken(token);
    return user.validate(function() {
      users.add(user);
      if (users.isPenaltyUser(user.id)) {
        return socket.emit('got penalty', {
          message: 'ん! you can\'t post for a while.'
        });
      }
    });
  });
  socket.on('post word', function(post) {
    var postLocked, result, word, word1;
    result = validateUtil.postedWord(user, users, post, getLastDoc(), postLocked);
    switch (result) {
      case validateResult.IS_NOT_VALID_POST:
      case validateResult.IS_INVALID_USER:
        return socket.emit('error message', {
          message: 'you bad boy.'
        });
      case validateResult.IS_PENALTY_USER:
        return socket.emit('error message', {
          message: 'ん! you can\'t post for a while.'
        });
      case validateResult.POST_LOCKED:
        return socket.emit('error message', {
          message: 'post conflicted with someones post!'
        });
      case validateResult.IS_INVALID_WORD:
        return socket.emit('error message', {
          message: 'Please enter a Japanese word in HIRAGANA.'
        });
      case validateResult.IS_NOT_LASTFIRST:
        return socket.emit('error message', {
          message: 'I\'m not sure it\'s being Last and First.'
        });
      case validateResult.WORD_ENDS_N:
        users.setPenaltyUser(user.id);
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
      case validateResult.IS_VALID:
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
  socket.on('like', function(data) {
    var userId, wordId;
    userId = data.userId;
    wordId = data.wordId;
    if (users.has(data.userId)) {
      return Words.findById(wordId, function(err, word) {
        var liked;
        if (!err) {
          liked = word.liked;
          if (_.include(liked, userId)) {
            return socket.emit('error message', {
              message: 'you bad boy.'
            });
          } else {
            word.liked.push(userId);
            return Words.update({
              _id: wordId
            }, {
              liked: liked
            }, null, function() {
              return io.sockets.emit('update like', word);
            });
          }
        }
      });
    }
  });
  return socket.on('disconnect', function() {
    return users.remove(user.id);
  });
});

oauthScopes = ['https://www.googleapis.com/auth/userinfo.profile'];

oauthQuery = {
  response_type: 'token',
  scope: oauthScopes.join('+'),
  redirect_uri: SECRET.GOOGLE_OAUTH_REDIRECT_TO,
  client_id: SECRET.GOOGLE_OAUTH_CLIENT_IE
};

oauthUrl = 'https://accounts.google.com/o/oauth2/auth?' + querystring.stringify(oauthQuery);

app.get('/', function(req, res) {
  return res.render('index', {
    title: 'LastFirstApp',
    oauthUrl: oauthUrl,
    isProduction: SECRET.IS_PRODUCTION,
    noAuthForDev: NO_AUTH_FOR_DEV
  });
});

app.get('/about', function(req, res) {
  return res.render('about', {
    title: 'LastFirstApp - about',
    oauthUrl: oauthUrl,
    isProduction: SECRET.IS_PRODUCTION
  });
});

app.get('/dev', function(req, res) {
  return res.render('dev', {
    isProduction: true,
    title: 'dev'
  });
});

app.get('/dev2', function(req, res) {
  return res.render('dev2', {
    isProduction: true,
    title: 'dev'
  });
});

app.get('/oauth2callback', function(req, res) {
  var token;
  token = req.query.code;
  return res.render('oauth2callback', {
    layout: false,
    title: 'LastFirstApp'
  });
});

app.listen(SECRET.PORT);
