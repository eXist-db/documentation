/**
 * Settings
 * Turn on/off build features
 */

const settings = {
  clean: true,
  scripts: true,
  hjs: false,
  polyfills: false,
  styles: true,
  svgs: true,
  vendor: true
}

/**
 * Paths to project folders
 */

const paths = {
  input: 'src/main/frontend/',
  output: 'target/generated-resources/frontend/xar-resources/resources/',
  scripts: {
    input: 'src/main/frontend/javascript/*',
    polyfills: '.polyfill.js',
    output: 'target/generated-resources/frontend/xar-resources/resources/scripts/'
  },
  styles: {
    input: 'src/main/frontend/sass/*.{scss,sass}',
    output: 'target/generated-resources/frontend/xar-resources/resources/styles/'
  },
  svgs: {
    input: 'src/main/frontend/svg/*.svg',
    output: 'target/generated-resources/frontend/xar-resources/resources/images/'
  },
  vendor: {
    output: 'target/generated-resources/frontend/xar-resources/resources/'
  },
  xml: {
    listings: 'src/main/xar-resources/data/*/listings/*.xml',
    articles: 'src/main/xar-resources/data/*/*.xml'
  }
}

/**
 * Template for banner to add to file headers
 */

const banner = {
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
const {
  gulp,
  src,
  dest,
  series,
  parallel
} = require('gulp')
const del = require('del')
const flatmap = require('gulp-flatmap')
const lazypipe = require('lazypipe')
const rename = require('gulp-rename')
const header = require('gulp-header')
const pkg = require('./package.json')
const muxml = require('gulp-muxml')


// Scripts
const standard = require('gulp-standard')
const concat = require('gulp-concat')
const uglify = require('gulp-uglify')
const optimizejs = require('gulp-optimize-js')

// Styles
const sass = require('gulp-sass')(require('sass'))
const prefix = require('gulp-autoprefixer')
const minify = require('gulp-cssnano')
const sourcemaps = require('gulp-sourcemaps')

// SVGs
const svgmin = require('gulp-svgmin')

/**
 * Gulp Tasks
 */

// Remove pre-existing content from output folders
const cleanDist = function (done) {
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
const jsTasks = lazypipe()
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
const buildScripts = function (done) {
  // Make sure this feature is activated before running
  if (!settings.scripts) return done()

  // Run tasks on script files
  src(paths.scripts.input)
    .pipe(flatmap(function (stream, file) {
      // If the file is a directory
      if (file.isDirectory()) {
        // Setup a suffix variable
        const suffix = ''

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
const lintScripts = function (done) {
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

// pretty print all xml listings
// articles not yet decided
const prettyXml = function (done) {
  src(paths.xml.listings, { base: "./" })
    .pipe(muxml({
      stripComments: false,
      stripCdata: false,
      stripInstruction: false,
      saxOptions: {
        trim: true,
        normalize: true
      }
    }))
    .pipe(dest("./"))
  // Signal completion
  done()
}

// Process, lint, and minify Sass files
const buildStyles = function (done) {
  // Make sure this feature is activated before running
  if (!settings.styles) return done()

  // Run tasks on all Sass files
  src(paths.styles.input)
    .pipe(sourcemaps.init())
    .pipe(sass({
      outputStyle: 'expanded',
      sourceComments: true
    }))
    .pipe(prefix({
      browsers: ['last 2 version', '> 0.25%'],
      cascade: true,
      remove: true
    }))
    // Uncomment if you want the non minified files
    // .pipe(header(banner.full, {
    //   package: pkg
    // }))
    // .pipe(dest(paths.styles.output))
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
    .pipe(sourcemaps.write('.'))
    .pipe(dest(paths.styles.output))

  // Signal completion
  done()
}

// Optimize SVG files
const buildSVGs = function (done) {
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
const vendorFiles = function (done) {
  // Make sure this feature is activated before running
  if (!settings.vendor) return done()

  // TODO ensure each declared third-parrty dep has a corresponding command below
  // TODO modernizr@2 needs refactor via npm or gulp-modernizr
  const deps = pkg.dependencies.length


  // copy vendor scripts
  src(['node_modules/bootstrap/dist/js/bootstrap.min.*', 'node_modules/@popperjs/core/dist/umd/popper.min.*', 'node_modules/@highlightjs/cdn-assets/highlight.min.js', 'node_modules/@highlightjs/cdn-assets/languages/xquery.min.js', 'node_modules/@highlightjs/cdn-assets/languages/dockerfile.min.js'])
    .pipe(dest(paths.scripts.output))

  // copy pre-packed lang definitions for code highlighter
  // CSS Bash Makefile Diff JSON Markdown Perl SQL Shell Properties Less SCSS Puppet'
  src(['node_modules/@highlightjs/cdn-assets/languages/xquery.min.js', 'node_modules/@highlightjs/cdn-assets/languages/dockerfile.min.js', 'node_modules/@highlightjs/cdn-assets/languages/apache.min.js', 'node_modules/@highlightjs/cdn-assets/languages/http.min.js', 'node_modules/@highlightjs/cdn-assets/languages/nginx.min.js'])
  .pipe(dest(paths.scripts.output))

  // copy vendor Styles
  src(['node_modules/bootstrap/dist/css/bootstrap.min.*', 'node_modules/@highlightjs/cdn-assets/styles/atom-one-dark.min.css'])
    .pipe(dest(paths.styles.output))

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
    prettyXml
  )
)
