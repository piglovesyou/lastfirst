
###
 Include libraries.
###

SECRET = require('secret-strings').LAST_FIRST
_ = require 'underscore'
require './lib/ext_validate'
express = require 'express'
url = require 'url'
querystring = require 'querystring'
stylus = require 'stylus'
nib = require 'nib'
# {OAuth} = require 'oauth'





###
 DB setting.
###
{Words} = require './lib/words'




###
 Include resources.
###
{User}  = require('./lib/user')
{Word}  = require('./lib/word')
users = require('./lib/users').getInstance()
NO_AUTH_FOR_DEV = not SECRET.IS_PRODUCTION and SECRET.NO_AUTH_FOR_DEV




###
 App initialize.
###
app = module.exports = express.createServer()
io = require('socket.io').listen(app)
app.configure ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use stylus.middleware(
    src: __dirname + '/public'
    compile: (str, path) ->
      stylus(str)
      .set('filename', path)
      .set('compress', true)
      .use(nib())
  )
  app.use app.router
  app.use express.static(__dirname + '/public')
app.configure 'development', ->
  app.use express.errorHandler
    dumpExceptions: true
    showStack: true
    force: true
app.configure 'production', ->
  app.use express.errorHandler()





###
 Socket IO listening.
###
 
{updateWords, getLastDoc} = require './lib/socket_util'
validateUtil = require('./lib/validate_util')
validateResult = validateUtil.RESULT_TYPE

io.sockets.on 'connection', (socket) ->
  user = new User(socket)
  socket.on 'got token', (data) ->
    token = data.token
    user.setToken(token)
    user.validate () ->
      if users.isPenaltyUser(user.id)
        socket.emit 'got penalty',
          message: 'ん! you can\'t post for a while.'

  socket.on 'post word', (post) ->
    result = validateUtil.postedWord(user, users, post, getLastDoc(), postLocked)
    switch (result)
      when validateResult.IS_NOT_VALID_POST, validateResult.IS_INVALID_USER
        socket.emit 'error message',
          message: 'you bad boy.'

      when validateResult.IS_PENALTY_USER
        socket.emit 'error message',
          message: 'ん! you can\'t post for a while.'

      when validateResult.POST_LOCKED    
        socket.emit 'error message',
          message: 'post conflicted with someones post!'

      when validateResult.IS_INVALID_WORD
        socket.emit 'error message',
          message: 'Please enter a Japanese word in HIRAGANA.'

      when validateResult.IS_NOT_LASTFIRST
        socket.emit 'error message',
          message: 'I\'m not sure it\'s being Last and First.'

      when validateResult.WORD_ENDS_N    
        users.setPenaltyUser(user.id)
        word1 = new Word(post)
        word1.save () ->
          word2 = new Word(getInitialWord())
          word2.save () ->
            updateWords(io.sockets)
            socket.emit 'got penalty',
              message: 'ん! you can\'t post for a while.'

      when validateResult.IS_VALID       
        postLocked = true
        word = new Word(post)
        word.save (err) ->
          postLocked = false
          unless err
            socket.emit 'posted successfully', post
            updateWords(io.sockets)

  socket.on 'like', (data) ->
    userId = data.userId
    wordId = data.wordId
    if users.has(data.userId)
      Words.findById wordId, (err, word) ->
        unless err
          liked = word.liked
          if _.include(liked, userId)
            socket.emit 'error message', message: 'you bad boy.'
          else
            word.liked.push(userId)
            Words.update {_id: wordId}, {liked: liked}, null, () ->
              io.sockets.emit 'update like', word
   
  socket.on 'pull update', ->
    user.updateWords()
   
  socket.on 'disconnect', () ->
    users.remove(user.id)
   
   
   
   





oauthScopes = [
  'https://www.googleapis.com/auth/userinfo.profile'
]
oauthQuery =
  response_type: 'token'
  scope: oauthScopes.join('+')
  redirect_uri: SECRET.GOOGLE_OAUTH_REDIRECT_TO
  client_id: SECRET.GOOGLE_OAUTH_CLIENT_IE
oauthUrl = 'https://accounts.google.com/o/oauth2/auth?' +
    querystring.stringify(oauthQuery)













googleLoaderParam = JSON.stringify
  "modules": [
    "name": "search"
    "version": "1"
    "nocss": "true"
  ]
googleLoaderParam = """
  #{googleLoaderParam}&key=#{SECRET.GOOGLE_LOADER_KEY}
  """
googleLoaderParam = "autoload=#{encodeURIComponent googleLoaderParam}"







# GET requests.
app.get '/', (req, res) ->
  res.render 'index',
    title: 'LastFirstApp'
    oauthUrl: oauthUrl
    isProduction: SECRET.IS_PRODUCTION
    noAuthForDev: NO_AUTH_FOR_DEV
    googleLoaderParam: googleLoaderParam

app.get '/about', (req, res) ->
  res.render 'about',
    title: 'LastFirstApp - about'
    oauthUrl: oauthUrl
    isProduction: SECRET.IS_PRODUCTION
    noAuthForDev: NO_AUTH_FOR_DEV
    googleLoaderParam: googleLoaderParam
    layout: false

app.get '/oauth2callback', (req, res) ->
  token = req.query.code
  res.render 'oauth2callback'
    layout: false
    title: 'LastFirstApp'





# For development
app.get '/dev', (req, res) ->
  res.render 'dev',
    isProduction: true
    title: 'dev'
app.get '/dev2', (req, res) ->
  res.render 'dev2',
    isProduction: true
    title: 'dev'


app.listen SECRET.PORT

