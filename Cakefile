
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

LIBS = addPath 'resources/client/libs', [
  'socket.io.js'
  'underscore-min.js'
  'jquery-1.7.min.js'
]
FILES = addPath 'resources', [
  'share/ext_validate.coffee'
  'client/utils/utils.coffee'
  'client/classes/classes.coffee'
  'client/init/init.coffee'
]
OUTPUT = "public/javascripts/client"



# Internal functions.

outputResult = (result) ->
  out = result[0]
  err = result[1]
  if not err and out
    console.log out
  err

concat = (minify) ->
  min = if minify then '.min' else ''
  my = "#{tempdir}/my#{min}.js"
  q = muffin.exec "cat #{LIBS.join ' '} #{my} > #{OUTPUT}#{min}.js"
  Q.when q[1], outputResult
  
minify = (callback) ->
  q = muffin.minifyScript "#{tempdir}/my.js"
  Q.when q, concat.bind(null, false)

joinAndCompile = (options) ->
  q = muffin.exec "coffee -cj #{tempdir}/my.js #{FILES.join ' '}"  
  Q.when q[1], (result) ->
    err = outputResult(result)
    unless err
      if options.minify
        minify(concat.bind(null, true))
      else
        concat(false)

compileStylus = (file) ->
  q = muffin.exec "stylus -c -o ./public/stylesheets/ #{file}"
  Q.when q[1], outputResult




# Options.

option '-w', '--watch', 'continue to watch the files and rebuild them when they change'
option '-m', '--minify', 'minify client side scripts'



# Tasks.

task 'build', 'Build coffeescripts.', (options) ->
  compileClientScripts = true
  muffin.run
    files: './**/*'
    options: options
    map:
      'app.coffee': (matches) ->
        muffin.compileScript matches[0], "./app.js", options

      'resources/(server|share)/(.+?).coffee': (matches) ->
        muffin.compileScript matches[0], "./lib/#{matches[2]}.js", options

      'resources/(client|share)/(.+?).coffee': (matches) ->
        if compileClientScripts
          compileClientScripts = false  # To prevent wasted compiles
          joinAndCompile(options)

      'resources/client/stylus/(.+?).styl': (matches) ->
        compileStylus matches[0]

    after: ->
      compileClientScripts = true



