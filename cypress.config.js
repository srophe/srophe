const { defineConfig } = require('cypress')

module.exports = defineConfig({
  screenshotsFolder: 'reports/screenshots',
  videosFolder: 'reports/videos',
  fixturesFolder: 'test/cypress/fixtures',
  e2e: {
    setupNodeEvents (on, config) {
      // implement node event listeners here
    },
    baseUrl: 'http://localhost:8080',
    includeShadowDom: true,
    specPattern: 'test/cypress/e2e/**/*.cy.{js,jsx,ts,tsx}',
    supportFile: 'test/cypress/support/e2e.js'
  }
})
