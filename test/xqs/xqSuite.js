'use strict'

const Mocha = require('mocha')
const http = require('http')
const expect = require('chai').expect
const xmldoc = require('xmldoc')


// Dynamically generate a mocha testsuite for xqsuite tests. Requires its own process, hence && in package.json
let Test = Mocha.Test

    let url = 'http://localhost:8080/exist/rest/db/apps/srophe/test/xqs/test-runner.xq'

http.get(url, (res) => {
  let data = ''

  // called when a data chunk is received.
  res.on('data', (chunk) => {
    data += chunk
  })

  // called when the complete response is received.
  res.on('end', () => {
    // NOTE(DP): XQTS errors on testsuite, will be returned as application/xml
    // The initial check will display the XQTS error, and run the test suite otherwise
    // see #800
    if (res.headers['content-type'].includes("application/json")) {
      let xqsReport = JSON.parse(data)
      let xqsPkg = xqsReport.testsuite.package
      let xqstCount = xqsReport.testsuite.tests
      let xqstCase = xqsReport.testsuite.testcase

      // TODO(DP): get rid of first "0 passing message"

      let mochaInstance = new Mocha()

      if (Array.isArray(xqsReport.testsuite)) {
        let xqsSuites = xqsReport.testsuite
        console.warn('support for multiple testsuites per run is experimental')
        xqsSuites.forEach((entry) => {
          xqsTests(mochaInstance, entry.package, entry.tests, entry.testcase)
        })
      } else {
        xqsTests(mochaInstance, xqsPkg, xqstCount, xqstCase)
      }
      // enable repeated runs
      // see https://github.com/mochajs/mocha/issues/995
      // see https://mochajs.org/api/mocha#unloadFiles
      let suiteRun = mochaInstance.cleanReferencesAfterRun(true).run()
      process.on('exit', () => {
        if (suiteRun.stats.failures > 0) { process.exit(1) } else { process.exit(0) }
      })
    }
    else {
      try { let doc = new xmldoc.XmlDocument(data)
      throw new Error(doc.childNamed("message").val) }
      catch (e) { console.log(e.message) }
    }
  })
}).on('error', (err) => {
  console.log('Error: ', err.message)
})

// TODO: mark %pending xqstests as pending in mocha report
function xqsTests (mochaInstance, xqsPkg, xqstCount, xqstCase) {
  let suiteInstance = Mocha.Suite.create(mochaInstance.suite, 'Xqsuite tests for ' + xqsPkg)

  if (xqstCase === undefined) {
    // if xqs contains 0 tests close open mocha instance
    mochaInstance.unloadFiles()
    suiteInstance.dispose()
    console.log('no test cases defined by suite ' + xqsPkg)
  } else if (Array.isArray(xqstCase)) {
    for (let i = 0; i < xqstCount; i++) {
      xqsResult(suiteInstance, xqstCase[i])
    }
  } else {
    xqsResult(suiteInstance, xqstCase)
  }
}

function xqsResult (suiteInstance, xqstCase) {
  suiteInstance.addTest(new Test('Test: ' + xqstCase.name, () => {
    switch (Object.prototype.hasOwnProperty.call(xqstCase, '') ){
      // Red xqs test: filter to dynamically ouput messages only when record contains them
      case 'failure':
        expect(xqstCase, 'Function ' + xqstCase.class + ' ' + xqstCase.failure.message).to.not.have.own.property('failure')
        break
      case 'error':
        expect(xqstCase, 'Function ' + xqstCase.class + ' ' + xqstCase.error.message).to.not.have.own.property('error')
        break
      // TODO: Blue xqs tests: pending not yet implemented
      case 'pending':
        Test.isPending(true)
        break
      // Green xqs tests: pass passing tests
      default:
        expect(xqstCase.failure).to.not.exist
        expect(xqstCase.error).to.not.exist
        break
    }
  }
  ))
}
