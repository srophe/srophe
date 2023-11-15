'use strict'

const supertest = require('supertest')
const expect = require('chai').expect

let client = supertest.agent('http://localhost:8080')

describe('rest api returns', function () {
    it('404 from random page', function (done) {
      this.timeout(10000)
      client
        .get('/random')
        .expect(404)
        .end(function (err, res) {
          expect(res.status).to.equal(404)
          if (err) return done(err)
          done()
        })
    })

    it('200 from default rest endpoint', function (done) {
      client
        .get('/exist/rest/db/')
        .expect(200)
        .end(function (err, res) {
          expect(res.status).to.equal(200)
          if (err) return done(err)
          done()
        })
    })

    it('file index.html exists in application root', function (done) {
      client
        .get('/exist/rest/db/apps/srophe/index.html')
        .expect(200)
        .end(function (err, res) {
          expect(res.status).to.equal(200)
          if (err) return done(err)
          done()
        })
    })
  })