const supertest = require('supertest')

// The client listening to the mock rest server
var client = supertest.agent('http://localhost:8080')

describe('running XQsuite test …', function () {
  this.timeout(95000)
  this.slow(60000)
  const runner = '/exist/rest/db/apps/doc/modules/test-runner.xql'

  it('returns 0 errors or failures', function (done) {
    client
      .get(runner)
      .set('Accept', 'application/json')
      .expect('content-type', /json/)
      .expect(200)
      .end(function (err, res) { // eslint-disable-line handle-callback-err
        console.info('response body: ' + JSON.stringify(res.body))
        if (err) return done(err);
        try {
          console.group()
          console.group()
          console.group()
          console.group()
          console.info(res.body.testsuite.tests + ' xqsuite tests:')
        } catch (err) {
          done(err)
        } finally {
          console.group()
          res.body.testsuite.testcase.forEach(function (entry) {
            if (entry.failure) {
              console.error([entry.name, entry.failure.message])
              process.exit(1)
            } else if (entry.error) {
              console.error([entry.name, entry.error.message])
              process.exit(1)
            } else (console.log(entry.name))
          })
          console.groupEnd()
        }
        console.groupEnd()
        console.groupEnd()
        console.groupEnd()
        console.groupEnd()
        done()
      })
  })
})
