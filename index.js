#!/usr/bin/env node

var fs = require('fs')
  , path = require('path')
  , chokidar = require('chokidar')
  , Vec2d = require('vec2d').Vec2d
  , findit = require('findit')
  , spawn = require('child_process').spawn
  , jspackage = require('jspackage')
  , express = require('express')
  , optimist = require('optimist')
  , Spritesheet = require('spritesheet')
  , Batch = require('batch')
  , client_out = userPath("./public/main.js")
  , img_path = userPath("./assets/img")
  , spritesheet_out = userPath("./public/spritesheet.png")
  , animations_json_out = userPath("./public/animations.json")
  , objHasOwn = {}.hasOwnProperty;

var chemfile_path = null;
var all_out_files = [
  client_out,
  spritesheet_out,
  animations_json_out
];

var tasks = {
  help: function(){
    process.stderr.write("Usage: \n\n  # create a new project\n  # possible templates are: meteor, readme, readme-coco\n  \n  chem init <your_project_name> [--example <template>]\n\n\n  # run a development server which will automatically recompile your code,\n  # generate your spritesheets, and serve your assets\n  \n  chem dev\n\n\n  # delete all generated files\n\n  chem clean\n");
  },
  init: function(args, argv){
    var project_name = args[0];
    var template = argv.example || "readme";
    if (project_name == null) {
      tasks.help();
      process.exit(1);
      return;
    }
    var src = chemPath("templates/" + template);
    // copy files from template to project_name
    exec('cp', ['-r', src, project_name]);
  },
  dev: function(args, options){
    serveStaticFiles(options.port || 10308);
    compileClientSource({
      watch: true
    });
    watchSpritesheet();
  },
  clean: function(){
    exec('rm', ['-f'].concat(all_out_files));
  }
};

run();

function run(){
  var argv = optimist.argv;
  var cmd = argv._[0];
  var task = tasks[cmd];
  if (task != null) {
    task(argv._.slice(1), argv);
  } else {
    tasks.help();
  }
}
function extend(obj, src){
  for (var key in src) {
    if (objHasOwn.call(src, key)) {
      obj[key] = src[key];
    }
  }
  return obj;
}
function compilerFromPath (filepath){
  var ext;
  if (filepath == null) {
    return null;
  }
  ext = path.extname(filepath);
  return jspackage.extensions[ext];
}
function getChemfilePath (){
  var chemfile_compiler;
  if (chemfile_path != null) {
    return chemfile_path;
  }
  chemfile_path = initPath();
  // figure out the path to the user's chemfile
  if ((chemfile_compiler = compilerFromPath(chemfile_path)) == null) {
    console.error("Missing chemfile or unrecognized chemfile extension.");
    process.exit(-1);
    return null;
  }
  if (chemfile_compiler.require != null) {
    // allows us to parse the chemfile regardless of language
    require(chemfile_compiler.require);
  }
  return chemfile_path;
  function initPath() {
    var i$, ref$, len$, file;
    for (i$ = 0, len$ = (ref$ = fs.readdirSync(userPath("."))).length; i$ < len$; ++i$) {
      file = ref$[i$];
      if (file.indexOf("chemfile.") === 0) {
        return file;
      }
    }
    return null;
  }
}
function forceRequireChemfile (){
  var chem_path = path.resolve(getChemfilePath());
  var req_path = chem_path.substring(0, chem_path.length - path.extname(chem_path).length);
  return forceRequire(req_path);
}
function chemPath (file){
  return path.join(__dirname, file);
}
function userPath (file){
  return path.join(process.cwd(), file);
}
function sign (x){
  if (x > 0) {
    return 1;
  } else if (x < 0) {
    return -1;
  } else {
    return 0;
  }
}
function exec (cmd, args, cb){
  args = args || [];
  cb = cb || noop;
  var bin = spawn(cmd, args, {stdio: 'inherit'});
  bin.on('exit', function(code) {
    if (code !== 0) {
      cb(new Error(cmd + " exit code " + code));
    } else {
      cb();
    }
  });
}
function compileClientSource (myOptions){
  var options = {watch: !!myOptions.watch};
  var chemfile = forceRequireChemfile();
  var libs = chemfile.libs || [];
  options.mainfile = userPath(chemfile.main);
  options.libs = libs.map(function(l) {
    return userPath(l);
  }).concat([
    chemPath("./browser/"),
  ]);
  jspackage.compile(options, function(err, compiled_code){
    if (err) {
      var timestamp = new Date().toLocaleTimeString();
      console.error(timestamp + " - error: " + err);
      return;
    }
    return fs.writeFile(client_out, compiled_code, 'utf8');
  });
}
function serveStaticFiles (port){
  var app = express();
  var public_dir = userPath("./public");
  app.use(express.static(public_dir));
  app.listen(port, function() {
    console.info("Serving at http://0.0.0.0:" + port);
  });
}
function watchSpritesheet (){
  // redo the spritesheet when any files change
  // always compile and watch on first run
  rewatch();
  function recompile(){
    createSpritesheet(function(err, generated_files) {
      var timestamp = new Date().toLocaleTimeString();
      if (err) {
        console.info(timestamp + " - " + err.stack);
      } else {
        generated_files.forEach(function(file) {
          console.info(timestamp + " - generated " + file);
        });
      }
    });
  }
  function rewatch(){
    // get list of files to watch
    var watch_files = [getChemfilePath()];
    // get list of all image files
    var animations = forceRequireChemfile().animations;
    getAllImgFiles(function(err, all_img_files) {
      if (err) {
        console.error("Error getting all image files:", err.stack);
        watchFilesOnce(watch_files, rewatch);
        return;
      }
      var success = true;
      for (var name in animations) {
        var anim = animations[name];
        var files = filesFromAnimFrames(anim.frames, name, all_img_files);
        if (files.length === 0) {
          console.error("animation `" + name + "` has no frames");
          success = false;
          continue;
        }
        files.forEach(addWatchFile);
      }
      watchFilesOnce(watch_files, rewatch);
      if (success) {
        recompile();
      }
    });
    function addWatchFile(file) {
      watch_files.push(path.join(img_path, file));
    }
  }
}
function forceRequire (module_path){
  var resolved_path = require.resolve(module_path);
  delete require.cache[resolved_path];
  return require(module_path);
}
function cmpStr (a, b){
  if (a < b) {
    return -1;
  } else if (a > b) {
    return 1;
  } else {
    return 0;
  }
}
function getAllImgFiles(cb) {
  var files = [];
  var finder = findit.find(img_path);
  finder.on('error', cb);
  finder.on('file', function(file) {
    files.push(file);
  });
  finder.on('end', function() {
    cb(null, files);
  });
}
function filesFromAnimFrames (frames, anim_name, all_img_files){
  frames = frames || anim_name;
  if (typeof frames === 'string') {
    var files = all_img_files.map(function(img){
      return path.relative(img_path, img);
    }).filter(function(img) {
      return img.indexOf(frames) === 0;
    }).map(function(img) {
      return path.join(img_path, img);
    });
    files.sort(cmpStr);
    return files;
  } else {
    return frames.map(function(img) {
      return path.join(img_path, img);
    });
  }
}
function createSpritesheet(cb) {
  var spritesheet = forceRequireChemfile().spritesheet;
  if (spritesheet == null) return [];
  // gather data about all image files
  // and place into array
  var animations = spritesheet.animations;
  var defaults = spritesheet.defaults;
  var sheet = new Spritesheet();
  var abort = false;
  sheet.once('error', function(err) {
    abort = true;
    cb(err);
  });
  getAllImgFiles(function(err, all_img_files) {
    if (abort) return;
    if (err) return cb(err);
    var anim;
    var seen = {};
    for (var name in animations) {
      anim = animations[name];
      // apply the default animation properties
      animations[name] = anim = extend(extend({}, defaults), anim);
      // change the frames array into an array of objects
      var files = filesFromAnimFrames(anim.frames, name, all_img_files);
      if (files.length === 0) {
        cb(new Error("animation `" + name + "` has no frames"));
        return;
      }
      anim.frames = [];
      files.forEach(addFile);
    }
    sheet.save(spritesheet_out, function(err) {
      if (abort) return;
      if (err) return cb(err);
      for (var name in animations) {
        var anim = animations[name];
        anim.frames = anim.frames.map(fileToFrame);
        anim.anchor = computeAnchor(anim);
      }
      // render json animation data
      fs.writeFile(animations_json_out, JSON.stringify(animations, null, 2), function(err) {
        if (abort) return;
        if (err) return cb(err);
        cb(null, [spritesheet_out, animations_json_out]);
      });
    });
    function addFile(file) {
      if (!seen[file]) {
        seen[file] = true;
        sheet.add(file);
      }
      anim.frames.push(file);
    }
  });
  function fileToFrame(file) {
    var sprite = sheet.sprites[file];
    return {
      size: new Vec2d(sprite.image.width, sprite.image.height),
      pos: sprite.pos,
    };
  }
}
function computeAnchor(anim){
  switch (anim.anchor) {
  case 'center':
    return anim.frames[0].size.scaled(0.5).floor();
  case 'topleft':
    return new Vec2d(0, 0);
  case 'topright':
    return new Vec2d(anim.frames[0].size.x, 0);
  case 'bottomleft':
    return new Vec2d(0, anim.frames[0].size.y);
  case 'bottomright':
    return anim.frames[0].size;
  case 'bottom':
    return new Vec2d(anim.frames[0].size.x / 2, anim.frames[0].size.y);
  case 'top':
    return new Vec2d(anim.frames[0].size.x / 2, 0);
  case 'right':
    return new Vec2d(anim.frames[0].size.x, anim.frames[0].size.y / 2);
  case 'left':
    return new Vec2d(0, anim.frames[0].size.y / 2);
  default:
    return anim.anchor
  }
}
function noop(err) {
  if (err) throw err;
}
function watchFilesOnce(files, cb) {
  var watcher = chokidar.watch(files, {ignored: /^\./, persistent: true});
  watcher.on('change', function() {
    cb();
    watcher.close();
  });
  return watcher;
}

