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
  src,
  dest,
  series,
  parallel
} = require('gulp')
const rename = require('gulp-rename')
const header = require('gulp-header')
const pkg = require('./package.json')
const { finished } = require('stream/promises')
const concatStream = require('concat-stream')
const intoStream = require('into-stream')
const muxmlCore = require('muxml')

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

const MUXML_OPTS = {
  stripComments: false,
  stripCdata: false,
  stripInstruction: false,
  saxOptions: {
    trim: true,
    normalize: true
  }
}

/** muxml + concat-stream can yield a string; Vinyl requires Buffer | Stream | null */
function toVinylContents (data) {
  if (data == null) return Buffer.alloc(0)
  if (Buffer.isBuffer(data)) return data
  if (data instanceof Uint8Array) return Buffer.from(data)
  return Buffer.from(String(data), 'utf8')
}

/** Drop-in for gulp-muxml that satisfies Vinyl 2+ file.contents rules */
function prettyMuxml () {
  return through2.obj(function (file, enc, cb) {
    if (file.isNull()) return cb(null, file)
    if (file.isStream()) {
      file.contents = file.contents.pipe(muxmlCore(MUXML_OPTS))
      return cb(null, file)
    }
    if (!file.isBuffer()) return cb(null, file)

    const m = intoStream(file.contents).pipe(muxmlCore(MUXML_OPTS))
    m.on('error', cb)
    m.pipe(concatStream(function (data) {
      file.contents = toVinylContents(data)
      cb(null, file)
    }))
  })
}

/**
 * Gulp Tasks
 */

// Remove pre-existing content from output folders
const cleanDist = async function () {
  // Make sure this feature is activated before running
  if (!settings.clean) return

  const { deleteSync } = await getDel()
  deleteSync([paths.output])
}

// pretty print all xml listings
// articles not yet decided
const prettyXml = function () {
  return src(paths.xml.listings, { base: './' })
    .pipe(prettyMuxml())
    .pipe(dest('./'))
}

// Process, lint, and minify Sass files
const buildStyles = function () {
  if (!settings.styles) return Promise.resolve()

  return src(paths.styles.input)
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
const vendorFiles = async function () {
  if (!settings.vendor) return

  // TODO ensure each declared third-parrty dep has a corresponding command below
  // TODO modernizr@2 needs refactor via npm or gulp-modernizr

  await finished(src(['node_modules/bootstrap/dist/js/bootstrap.min.*', 'node_modules/@popperjs/core/dist/umd/popper.min.*', 'node_modules/@highlightjs/cdn-assets/highlight.min.js', 'node_modules/@highlightjs/cdn-assets/languages/xquery.min.js', 'node_modules/@highlightjs/cdn-assets/languages/dockerfile.min.js'])
    .pipe(dest(paths.scripts.output)))

  await finished(src(['node_modules/@highlightjs/cdn-assets/languages/xquery.min.js', 'node_modules/@highlightjs/cdn-assets/languages/dockerfile.min.js', 'node_modules/@highlightjs/cdn-assets/languages/apache.min.js', 'node_modules/@highlightjs/cdn-assets/languages/http.min.js', 'node_modules/@highlightjs/cdn-assets/languages/nginx.min.js'])
    .pipe(dest(paths.scripts.output)))

  await finished(src(['node_modules/bootstrap/dist/css/bootstrap.min.*', 'node_modules/@highlightjs/cdn-assets/styles/atom-one-dark.min.css'])
    .pipe(dest(paths.styles.output)))
}

/**
 * Export Tasks
 */

exports.default = series(
  cleanDist,
  vendorFiles,
  parallel(
    buildStyles,
    buildSVGs,
    prettyXml
  )
)
