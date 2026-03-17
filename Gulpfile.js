/**
 * Settings
 * Turn on/off build features
 */

const settings = {
  clean: true,
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
const rename = require('gulp-rename')
const header = require('gulp-header')
const pkg = require('./package.json')
const muxml = require('gulp-muxml')


// Styles
const sass = require('gulp-sass')(require('sass'))
const postcss = require('gulp-postcss')
const autoprefixer = require('autoprefixer')
const cssnano = require('cssnano')
const sourcemaps = require('gulp-sourcemaps')

// SVGs
const through2 = require('through2')

let delApi
async function getDel () {
  if (delApi) return delApi
  // del@8 is ESM-only
  delApi = await import('del')
  return delApi
}

let svgoApi
async function getSvgo () {
  if (svgoApi) return svgoApi
  // svgo@4 is ESM-only
  svgoApi = await import('svgo')
  return svgoApi
}

/**
 * Gulp Tasks
 */

// Remove pre-existing content from output folders
const cleanDist = async function () {
  // Make sure this feature is activated before running
  if (!settings.clean) return

  // Clean the dist folder
  const { deleteSync } = await getDel()
  deleteSync([paths.output])
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
const buildStyles = async function () {
  // Make sure this feature is activated before running
  if (!settings.styles) return

  // Run tasks on all Sass files
  src(paths.styles.input)
    .pipe(sourcemaps.init())
    .pipe(sass({
      outputStyle: 'expanded',
      sourceComments: true
    }))
    .pipe(postcss([
      autoprefixer({
        cascade: true
      }),
      cssnano()
    ]))
    // Uncomment if you want the non minified files
    // .pipe(header(banner.full, {
    //   package: pkg
    // }))
    // .pipe(dest(paths.styles.output))
    .pipe(rename({
      suffix: '.min'
    }))
    .pipe(header(banner.min, {
      package: pkg
    }))
    .pipe(sourcemaps.write('.'))
    .pipe(dest(paths.styles.output))
}

// Optimize SVG files
const buildSVGs = function () {
  // Make sure this feature is activated before running
  if (!settings.svgs) return Promise.resolve()

  return src(paths.svgs.input)
    .pipe(through2.obj(function (file, enc, cb) {
      if (!file.isBuffer()) return cb(null, file)

      getSvgo()
        .then(({ optimize }) => {
          const input = file.contents.toString('utf8')
          const result = optimize(input, { path: file.path })
          file.contents = Buffer.from(result.data, 'utf8')
          cb(null, file)
        })
        .catch(cb)
    }))
    .pipe(dest(paths.svgs.output))
}

// Copy third-party dependencies from node_modules into resources
const vendorFiles = function (done) {
  // Make sure this feature is activated before running
  if (!settings.vendor) return done()

  // TODO ensure each declared third-parrty dep has a corresponding command below
  // TODO modernizr@2 needs refactor via npm or gulp-modernizr
 
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
    buildStyles,
    buildSVGs,
    prettyXml
  )
)
