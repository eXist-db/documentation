---
name: Bug report
about: Something isn't working with the app
title: "[BUG]"
labels: bug
assignees: duncdrum

---

> To be able to better understand you problem, please add as much information as possible to this ticket. Always test your bugs against the latest version of the documentation app that ships with the last stable release of exist-db. We cannot provide support for older versions here on GitHub. 

**Describe the bug**
A clear and concise description of what the bug is.

**Expected behavior**
A clear and concise description of what you expected to happen.

**To Reproduce**
> The *best* way is to provide an [SSCCE (Short, Self Contained, Correct (Compilable), Example)](http://sscce.org/). One type of SSCCE could be a small test which reproduces the issue and can be run without dependencies. 

To run unit tests locally: `mvn test`

**Unit Test**
[XQSuite - Annotation-based Test Framework for XQuery](http://exist-db.org/exist/apps/doc/xqsuite.xml) unit tests for xquery code are located at `src/main/xar-resources/modules/test-suite.xql`.
```Xquery
xquery version "3.1";

module namespace t="http://exist-db.org/xquery/test";
declare namespace test="http://exist-db.org/xquery/xqsuite";

<-- Adjust to your reported issue -->
declare
    %test:assertTrue
function t:test() {
    1 eq 1
};
```

[mocha](https://mochajs.org) unit tests for javascript are located at `src/test/mocha/test.js`

```javascript
const assert = require('assert')

// this is a dummy test 
describe('Array', function () {
  describe('#indexOf()', function () {
    it('should return -1 when the value is not present', function () {
      assert.strictEqual([1, 2, 3].indexOf(4), -1)
    })
  })
})
```

**Integration Test**
For UI and browser based testing we use [cypress.js](https://www.cypress.io). The tests are located at `src/test/cypress/integration/documentation_spec.js`.
To run this locally: `cypress open`

```javascript
// adjust as necessary
describe('The app', function() {
  it('should load', function() {
    // Go to app start page
    cy.visit('/app/index.html')
  })
```

If none of the above is working, please tell us the exact steps you took when you encountered the problem:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Context (please always complete the following information):**
- eXist-db Version: [e.g. 5.1.1]
- App Version: [e.g. 5.1.0]
- Browser Version: [e.g. Safari 13.0.4]
