const { defineConfig } = require('cypress')

module.exports = defineConfig({
  screenshotsFolder: 'target/cypress/reports/screenshots',
  videosFolder: 'target/cypress/reports/videos',
  fixturesFolder: 'src/test/cypress/fixtures',
  e2e: {
    setupNodeEvents (on, config) {
      // implement node event listeners here
    },
    baseUrl: 'http://localhost:8123',
    includeShadowDom: true,
    specPattern: 'src/test/cypress/e2e/**/*.cy.{js,jsx,ts,tsx}',
    supportFile: 'src/test/cypress/support/e2e.js'
  }
})
