{spawn} = require("child_process")

coffee = "coffee"
coco = "coco"

exec = (cmd, args=[], cb=->) ->
  bin = spawn(cmd, args)
  bin.stdout.on 'data', (data) ->
    process.stdout.write data
  bin.stderr.on 'data', (data) ->
    process.stderr.write data
  bin.on 'exit', cb

compile = (watch_flag="") ->
  coffee_flags = "-#{watch_flag}cbo"
  exec coffee, [coffee_flags, "./lib/", "./src/lib/"]
  exec coffee, [coffee_flags, "./lib/", "./src/shared/"]

  coco_flags = coffee_flags
  exec coco, [coco_flags, "./lib/", "./src/lib/"]
  exec coco, [coco_flags, "./lib/", "./src/shared/"]

task 'watch', -> compile('w')

task 'build', -> compile()
