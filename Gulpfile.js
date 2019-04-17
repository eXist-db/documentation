/**
 * Settings
 * Turn on/off build features
 */

var settings = {
  clean: true,
  scripts: true,
  hjs: false,
  polyfills: false,
  styles: true,
  svgs: true,
  copy: true,
  vendor: true
}

/**
 * Paths to project folders
 */

var paths = {
  input: 'src/main/frontend/',
  output: 'src/main/xar-resources/resources/',
  scripts: {
    input: 'src/main/frontend/javascript/*',
    polyfills: '.polyfill.js',
    output: 'src/main/xar-resources/resources/scripts/'
  },
  styles: {
    input: 'src/main/frontend/css/**',
    output: 'src/main/xar-resources/resources/styles/'
  },
  svgs: {
    input: 'src/main/frontend/img/*.svg',
    output: 'src/main/xar-resources/resources/images/'
  },
  copy: {
    input: 'src/main/frontend/copy/**',
    output: 'src/main/xar-resources/resources/'
  },
  vendor: {
    input: 'node_modules/',
    output: 'src/main/xar-resources/resources/'
  },
  fonts: {
    output: 'src/main/xar-resources/resources/fonts/',
  }
}

/**
 * Template for banner to add to file headers
 */

var banner = {
  full: '/*!\n' +
    ' * <%= package.name %> v<%= package.version %>\n' +
    ' * <%= package.description %>\n' +
    ' * (c) ' + new Date().getFullYear() + ' <%= package.author.name %>\n' +
    ' * <%= package.license %> License\n' +
    ' * <%= package.repository.url %>\n' +
    ' */\n\n',
  min: '/*!' +
    ' <%= package.name %> v<%= package.version %>' +
    ' | (c) ' + new Date().getFullYear() + ' <%= package.author.name %>' +
    ' | <%= package.license %> License' +
    ' | <%= package.repository.url %>' +
    ' */\n'
}

/**
 * Gulp Packages
 */

// General
var {
  gulp,
  src,
  dest,
  series,
  parallel
} = require('gulp')
var del = require('del')
var flatmap = require('gulp-flatmap')
var lazypipe = require('lazypipe')
var rename = require('gulp-rename')
var header = require('gulp-header')
var pkg = require('./package.json')

// Scripts
var standard = require('gulp-standard')
var concat = require('gulp-concat')
var uglify = require('gulp-uglify')
var optimizejs = require('gulp-optimize-js')

// Styles
var sass = require('gulp-sass')
var prefix = require('gulp-autoprefixer')
var minify = require('gulp-cssnano')

// SVGs
var svgmin = require('gulp-svgmin')

/**
 * Gulp Tasks
 */

// Remove pre-existing content from output folders
var cleanDist = function(done) {
  // Make sure this feature is activated before running
  if (!settings.clean) return done()

  // Clean the dist folder
  del.sync([
    paths.output
  ])

  // Signal completion
  return done()
}

// Repeated JavaScript tasks
var jsTasks = lazypipe()
  .pipe(header, banner.full, {
    package: pkg
  })
  .pipe(optimizejs)
  .pipe(dest, paths.scripts.output)
  .pipe(rename, {
    suffix: '.min'
  })
  .pipe(uglify)
  .pipe(optimizejs)
  .pipe(header, banner.min, {
    package: pkg
  })
  .pipe(dest, paths.scripts.output)

// Lint, minify, and concatenate scripts
var buildScripts = function(done) {
  // Make sure this feature is activated before running
  if (!settings.scripts) return done()

  // Run tasks on script files
  src(paths.scripts.input)
    .pipe(flatmap(function(stream, file) {
      // If the file is a directory
      if (file.isDirectory()) {
        // Setup a suffix variable
        var suffix = ''

        // If separate polyfill files enabled
        if (settings.polyfills) {
          // Update the suffix
          suffix = '.polyfills'

          // Grab files that aren't polyfills, concatenate them, and process them
          src([file.path + '/*.js', '!' + file.path + '/*' + paths.scripts.polyfills])
            .pipe(concat(file.relative + '.js'))
            .pipe(jsTasks())
        }

        // Grab all files and concatenate them
        // If separate polyfills enabled, this will have .polyfills in the filename
        src(file.path + '/*.js')
          .pipe(concat(file.relative + suffix + '.js'))
          .pipe(jsTasks())

        return stream
      }

      // Otherwise, process the file
      return stream.pipe(jsTasks())
    }))

  // Signal completion
  done()
}

// Lint scripts
var lintScripts = function(done) {
  // Make sure this feature is activated before running
  if (!settings.scripts) return done()

  // Lint scripts
  src(paths.scripts.input)
    .pipe(standard({
      fix: true
    }))
    .pipe(standard.reporter('default'))

  // Signal completion
  done()
}

// Process, lint, and minify Sass files
var buildStyles = function(done) {
  // Make sure this feature is activated before running
  if (!settings.styles) return done()

  // Run tasks on all Sass files
  src(paths.styles.input)
    .pipe(sass({
      outputStyle: 'expanded',
      sourceComments: true
    }))
    .pipe(prefix({
      browsers: ['last 2 version', '> 0.25%'],
      cascade: true,
      remove: true
    }))
    .pipe(header(banner.full, {
      package: pkg
    }))
    .pipe(dest(paths.styles.output))
    .pipe(rename({
      suffix: '.min'
    }))
    .pipe(minify({
      discardComments: {
        removeAll: true
      }
    }))
    .pipe(header(banner.min, {
      package: pkg
    }))
    .pipe(dest(paths.styles.output))

  // Signal completion
  done()
}

// Optimize SVG files
var buildSVGs = function(done) {
  // Make sure this feature is activated before running
  if (!settings.svgs) return done()

  // Optimize SVG files
  src(paths.svgs.input)
    .pipe(svgmin())
    .pipe(dest(paths.svgs.output))

  // Signal completion
  done()
}

// Copy third-party dependencies from node_modules into resources
var vendorFiles = function(done) {
  // Make sure this feature is activated before running
  if (!settings.vendor) return done()

  // TODO ensure each declared third-parrty dep has a corresponding command below
  // TODO modernizr@2 needs refactor via npm or gulp-modernizr
  var deps = pkg.dependencies.length


  // copy vendor scripts
  src(['node_modules/bootstrap/dist/js/bootstrap.min.*', 'node_modules/jquery/dist/jquery.min.*'])
  .pipe(dest(paths.scripts.output))

  // copy vendor Styles
  src(['node_modules/bootstrap/dist/css/bootstrap.min.*', 'node_modules/highlight.js/styles/atom-one-dark.css'])
    .pipe(dest(paths.styles.output))

  // TODO copy and install vendor fonts
  // Signal completion
  done()
}


// Copy static files into output folder
var copyFiles = function(done) {
  // Make sure this feature is activated before running
  if (!settings.copy) return done()

  // Copy static files
  src(paths.copy.input)
    .pipe(dest(paths.copy.output))

  // Signal completion
  done()
}

// Build and copy highlight.js
var buildPack = function(done) {
  // Make sure this feature is activated before running
  if (!settings.hjs) return done()

  // build highlight pack
  // see https://highlightjs.readthedocs.io/en/latest/building-testing.html
  // TODO currently building is bugged
  let command = 'cd node_modules/highlight.js'
                    + ' && npm install'
                    + ' && node tools/build :common xquery'

  exec(command, (err, stdout, stderr)=> {
    console.log(stderr)
    console.log(stdout)

    callback(err)
  })

  src('node_modules/highlight.js/build/*pack.js')
    .pipe(dest(paths.scripts.output))

  // Signal completion
  done()
}

/**
 * Export Tasks
 */

// Default task
// gulp
exports.default = series(
  cleanDist,
  vendorFiles,
  parallel(
    buildScripts,
    lintScripts,
    buildStyles,
    buildSVGs,
    copyFiles,
    buildPack
  )
)
