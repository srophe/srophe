/* eslint-disable no-var */
'use strict'

const chai = require('chai')
const chaiXml = require('chai-xml')
const expect = require('chai').expect
const fs = require('fs-extra')
const glob = require('glob')
const xmldoc = require('xmldoc')
const assert = require('yeoman-assert')

// this is not equivalent to using a real xml parser
describe('file system checks', function () {

  describe('Consistent data in aux files', function () {
    it('should contain identical descriptions', function (done) {
      if (fs.existsSync('pom.xml')) {
        const build = fs.readFileSync('pom.xml', 'utf8')
        const parsed = new xmldoc.XmlDocument(build)
        var pomDesc = parsed.childNamed('description').val
      }

      if (fs.existsSync('package.json')) {
        const pkg = fs.readFileSync('package.json', 'utf8')
        const parsed = JSON.parse(pkg)
        var pkgDesc = parsed.description
      }

      expect(pkgDesc).to.equal(pomDesc)

      done()
    })

    it('should contain identical versions', function (done) {
      if (fs.existsSync('package.json')) {
        const pkg = fs.readFileSync('package.json', 'utf8')
        const parsed = JSON.parse(pkg)
        var pkgVer = parsed.version
      }

      if (fs.existsSync('pom.xml')) {
        const pom = fs.readFileSync('pom.xml', 'utf8')
        const parsed = new xmldoc.XmlDocument(pom)
        var pomVer = parsed.childNamed('version').val
      }

      expect(pkgVer).to.equal(pomVer)

      done()
    })

    it('should contain identical licenses', function (done) {
      if (fs.existsSync('package.json')) {
        const pkg = fs.readFileSync('package.json', 'utf8')
        const parsed = JSON.parse(pkg)
        var pkgLic = parsed.license
      }

      if (fs.existsSync('pom.xml')) {
        const pom = fs.readFileSync('pom.xml', 'utf8')
        const parsed = new xmldoc.XmlDocument(pom)
        var pomLic = parsed.childNamed('licenses').childNamed('license').childNamed('name').val
      }

      expect(pkgLic).to.equal(pomLic)

      done()
    })

    it('should contain identical titles', function (done) {
      if (fs.existsSync('pom.xml')) {
        const pom = fs.readFileSync('pom.xml', 'utf8')
        const parsed = new xmldoc.XmlDocument(pom)
        var pomTitle = parsed.childNamed('name').val
      }

      if (fs.existsSync('package.json')) {
        const pkg = fs.readFileSync('package.json', 'utf8')
        const parsed = JSON.parse(pkg)
        var pkgTitle = parsed.name
      }

      expect(pkgTitle).to.equal(pomTitle)

      if (fs.existsSync('target/classes/xar-resources/templates/page.html')) {
        const page = fs.readFileSync('target/classes/xar-resources/templates/page.html', 'utf8')
        const parsed = new xmldoc.XmlDocument(page)
        var pageTitle = parsed.descendantWithPath('head.title').val
      }

      expect(pageTitle).to.equal(pomTitle)

      done()
    })

    it('Readme should have latest meta-data', function (done) {
      const pkg = fs.readFileSync('package.json', 'utf8')
      const parsed = JSON.parse(pkg)

      if (fs.existsSync('README.md')) {
        assert.fileContent('README.md', '# ' + parsed.name)
        assert.fileContent('README.md', parsed.version)
        assert.fileContent('README.md', parsed.description)
      } else { this.skip() }
      done()
    })
  })
})
