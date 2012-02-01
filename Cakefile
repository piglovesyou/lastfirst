
# Include required libraries.

muffin = require 'muffin'
Q = require 'q'
_ = require 'underscore'
temp = require 'temp'
tempdir = temp.mkdirSync()



# Client scripts setting.

addPath = (path, files) ->
  path += '/'  if /[^\/]$/.test(path)
  files[_i] = path + file  for file in files

# LIBS = addPath 'resources/client/libs', [
#   'socket.io.js'
#   'underscore-min.js'
#   'jquery-1.7.min.js'
# ]
FILES = addPath 'resources', [

  'share/ext_validate.coffee'
  'client/utils.coffee'

  'client/imagesearcher.coffee'
  'client/ui/abstractcomponent.coffee'
  'client/ui/word.coffee'
  'client/ui/blankword.coffee'
  'client/ui/wordlist.coffee'
  'client/ui/message.coffee'
  'client/ui/time.coffee'

  'client/init.coffee'
]
OUTPUT = "public/javascripts"



# Internal functions.

outputResult = (result) ->
  out = result[0]
  err = result[1]
  if not err and out
    console.log out
  err

# concat = (minify) ->
#   min = if minify then '.min' else ''
#   my = "#{tempdir}/my#{min}.js"
#   q = muffin.exec "cat #{LIBS.join ' '} #{my} > #{OUTPUT}#{min}.js"
#   Q.when q[1], outputResult
  
# minify = (callback) ->
#   q = muffin.minifyScript "#{tempdir}/my.js"
#   Q.when q, concat.bind(null, false)

joinAndCompile = (options) ->
  q = muffin.exec "cat #{FILES.join ' '} > #{tempdir}/concatnated.coffee"  
  Q.when q[1], (result) ->
    err = outputResult(result)
    unless err
      q = muffin.compileScript "#{tempdir}/concatnated.coffee", "#{OUTPUT}/client.js", options
      if options.minify
        Q.when q, (result) ->
          muffin.minifyScript "#{OUTPUT}/client.js", "#{OUTPUT}/client.min.js", options



      # q = muffin.compileScript "#{tempdir}/concatnated.coffee", "#{tempdir}/my.js", options
      # Q.when q, (result) ->
      #   if options.minify
      #     minify(concat.bind(null, true))
      #   else
      #     concat(false)



# Options.

option '-w', '--watch', 'continue to watch the files and rebuild them when they change'
option '-m', '--minify', 'minify client side scripts'



# Tasks.

task 'build', 'Build coffeescripts.', (options) ->
  options = _.defaults
    watch: true
  , options
  compileClientScripts = true
  muffin.run
    files: './**/*'
    options: options
    map:
      'app.coffee': (matches) ->
        options.bare = true
        muffin.compileScript matches[0], "./app.js", options

      'resources/(server|share)/(.+?).coffee': (matches) ->
        muffin.compileScript matches[0], "./lib/#{matches[2]}.js", options

      'resources/(client|share)/(.+?).coffee': (matches) ->
        if compileClientScripts
          compileClientScripts = false  # To prevent wasted compiles
          joinAndCompile(options)

    after: ->
      compileClientScripts = true



