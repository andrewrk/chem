fs = require('fs')
path = require('path')
util = require('util')
{spawn} = require("child_process")

chemPath = (file) ->
  path.join(path.dirname(fs.realpathSync(__filename)), "..", file)

userPath = (file) ->
  path.join(process.cwd(), file)

client_out = userPath("./public/game.js")
img_path = userPath("./assets/img")
spritesheet_out = userPath("./public/spritesheet.png")
animations_json_out = userPath("./public/animations.json")

fileCopy = (src, dest, flags, cb) ->
  in_stream = fs.createReadStream(src)
  out_stream = fs.createWriteStream(dest, flags: flags)
  util.pump(in_stream, out_stream, cb)

fileDelete = (file_path) -> try fs.unlinkSync(file_path)

compilers =
  coffee:
    require: 'coffee-script'
    compile: (src, dest, cb) ->
      exec 'coffee', ['-cj', dest, src], cb
  co:
    require: 'coco'
    compile: (src, dest, cb) ->
      exec 'coco', ['-cj', dest, src], cb
  ls:
    require: 'LiveScript'
    compile: (src, dest, cb) ->
      exec 'livescript', ['-cj', dest, src], cb
  js:
    require: null
    compile: (src, dest, cb) ->
      fileCopy src, dest, 'w', cb

chem_client_src = [
  chemPath("./src/lib/vec2d.coffee")
  chemPath("./src/client/engine.coffee")
]

all_out_files = [
  client_out
  spritesheet_out
  animations_json_out
]

extend = (obj, args...) ->
  for arg in args
    obj[prop] = val for prop, val of arg
  obj

sign = (n) -> if n > 0 then 1 else if n < 0 then -1 else 0

exec = (cmd, args=[], cb=->) ->
  bin = spawn(cmd, args)
  bin.stdout.on 'data', (data) ->
    process.stdout.write data
  bin.stderr.on 'data', (data) ->
    process.stderr.write data
  bin.on 'exit', cb

compilerFromPath = (filepath) ->
  if not filepath?
    return null
  ext = path.extname(filepath)
  if ext.length <= 1
    return null
  lang = ext.substring(1)
  compilers[lang]

compileClientSource = (watch_flag="") ->
  # figure out the path to the user's chemfile
  chemfile = do ->
    for file in fs.readdirSync(userPath("."))
      if file.indexOf("chemfile.") == 0
        return file
    return null
  if not (chemfile_compiler = compilerFromPath(chemfile))?
    console.error "Missing chemfile or unrecognized chemfile extension."
    return

  if chemfile_compiler.require?
    # allows us to parse the chemfile regardless of language
    require(chemfile_compiler.require)

  {sources} = forceRequire(userPath("./chemfile"))
  all_sources = chem_client_src.concat(sources)
  tempfile = "#{client_out}.tmp.js"
  fileDelete client_out
  compileNext = ->
    if not (src = all_sources.shift())?
      timestamp = (new Date()).toLocaleTimeString()
      fileDelete tempfile
      console.info "#{timestamp} - generated #{client_out}"
    else
      compiler = compilerFromPath(src)
      if not compiler?
        console.error "Unrecognized file extension for #{src}"
        return
      console.log "compile", src
      compiler.compile src, tempfile, appendNext
  appendNext = ->
    fileCopy tempfile, client_out, 'a', compileNext

  compileNext()

serveStaticFiles = (port) ->
  node_static = require('node-static')
  http = require('http')
  file_server = new node_static.Server("./public")
  app = http.createServer (request, response) ->
    file_server.serve request, response
  app.listen port
  console.info("Serving at http://localhost:#{port}")

# when any one of these files change, call callback
watchers = []
watchFiles = (files, cb) ->
  watcher.close() for watcher in watchers
  watchers = []
  success = true
  for file in files
    try
      watchers.push fs.watch(file, cb)
    catch error
      console.error "Image file not found: #{file}"
      success = false
  return success

watchSpritesheet = ->
  # redo the spritesheet when any files change
  recompile = ->
    createSpritesheet()
    timestamp = (new Date()).toLocaleTimeString()
    console.info "#{timestamp} - generated #{spritesheet_out}"
    console.info "#{timestamp} - generated #{animations_json_out}"
  rewatch = ->
    # get list of files to watch
    watch_files = []
    # get list of all image files
    {animations} = forceRequire(userPath('./chemfile'))
    all_img_files = getAllImgFiles()
    success = true
    for name, anim of animations
      files = filesFromAnimFrames(anim.frames, name, all_img_files)
      if files.length is 0
        console.error "animation `#{name}` has no frames"
        success = false
        continue
      for file in files
        watch_files.push path.join(img_path, file)
    if watchFiles(watch_files, recompile) and success
      recompile()
  # when chemfile changes, recompile and rewatch
  chemfile_path = require.resolve(userPath("./chemfile"))
  fs.watch chemfile_path, rewatch
  # always compile and watch on first run
  rewatch()

forceRequire = (module_path) ->
  resolved_path = require.resolve(module_path)
  delete require.cache[resolved_path]
  require(module_path)

walk = (dir) ->
  results = []
  processDir = (full_path, part_path) ->
    for file in fs.readdirSync(full_path)
      full_file = path.join(full_path, file)
      part_file = path.join(part_path, file)
      stat = fs.statSync(full_file)
      if stat.isDirectory()
        processDir(full_file, part_file)
      else
        results.push part_file
  processDir(dir, "")
  results

cmpStr = (a, b) -> if a < b then -1 else if a > b then 1 else 0

getAllImgFiles = -> walk(img_path)

filesFromAnimFrames = (frames, anim_name, all_img_files) ->
  frames ?= anim_name
  if typeof frames is 'string'
    files = (img for img in all_img_files when img.indexOf(frames) is 0)
    files.sort cmpStr
    return files
  else
    return frames

createSpritesheet = ->
  Canvas = require('canvas')
  Image = Canvas.Image
  {Vec2d} = require(chemPath('./lib/vec2d'))
  {Spritesheet} = require(chemPath('./lib/spritesheet'))
  # gather data about all image files
  # and place into array
  {_default, animations} = forceRequire(userPath('./chemfile'))
  frame_list = []
  all_img_files = getAllImgFiles()
  for name, anim of animations
    # apply the default animation properties
    animations[name] = anim = extend {}, _default, anim

    # change the frames array into an array of objects
    files = filesFromAnimFrames(anim.frames, name, all_img_files)
    anim.frames = []

    for file in files
      image = new Image()
      image.src = fs.readFileSync(path.join(img_path, file))
      frame =
        image: image
        size: new Vec2d(image.width, image.height)
        filename: file
        pos: new Vec2d(0, 0)
      frame_list.push frame
      anim.frames.push frame

    if anim.anchor is "center"
      anim.anchor = anim.frames[0].size.scaled(0.5).floor()

  sheet = new Spritesheet(frame_list)
  sheet.calculatePositions()

  # render to png
  canvas = new Canvas(sheet.size.x, sheet.size.y)
  context = canvas.getContext('2d')
  for frame in frame_list
    context.drawImage frame.image, frame.pos.x, frame.pos.y
  out = fs.createWriteStream(spritesheet_out)
  stream = canvas.createPNGStream()
  stream.on 'data', (chunk) -> out.write chunk

  # strip properties from animations that we do not wish to commit to disk
  for name, anim of animations
    for frame in anim.frames
      delete frame.image
      delete frame.filename

  # render json animation data
  fs.writeFileSync animations_json_out, JSON.stringify(animations, null, 4), 'utf8'

tasks =
  help: ->
    process.stderr.write """
    Usage: 

      # create a new project
      chem init <your_project_name> [<template_name>]
      # possible templates are: empty, meteor

      # run a development server which will automatically recompile your code,
      # generate your spritesheets, and serve your assets
      chem dev

    """
  init: (args) ->
    project_name = args[0]
    template = args[1] or "meteor"

    if not project_name?
      tasks.help()
      process.exit(1)
      return

    src = chemPath("templates/#{template}")

    # copy files from template to project_name
    exec 'cp', ['-r', src, project_name]
  dev: (args, options) ->
    serveStaticFiles(options.port or 10308)
    compileClientSource('w')
    watchSpritesheet()
  clean: ->
    exec 'rm', ['-f'].concat(all_out_files)

exports.run = ->
  cmd = process.argv[2]
  task = tasks[cmd]
  if task?
    task(process.argv.slice(3), {})
  else
    tasks.help([], {})

