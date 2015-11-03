Bookshelf = require 'bookshelf'
Signals = require '../src'
init = require './init'

describe 'Bookshelf signals', ->
    db = null
    User = null
    Users = null

    before co ->
        db = init.init()
        yield init.users()

    beforeEach ->
        class User extends db.Model
            tableName: 'users'

        class Users extends db.Collection
            model: User

    it 'trigger events on database object', co ->
        f = spy()
        db.on 'saving', f
        yield new User().save()
        f.should.have.been.called.once

    it "trigger events on custom hub", co ->
        hub =
            triggerThen: spy()
            trigger: ->

        db2 = Bookshelf db.knex
        db2.plugin Signals(hub)

        class User extends db2.Model
            tableName: 'users'

        yield new User().save()
        hub.triggerThen.should.have.been.called()

    it 'filters events by class'
    it "method 'once' doesn't unsubscribe callback if it was not called"
    it 'reject save if callback is rejected'
