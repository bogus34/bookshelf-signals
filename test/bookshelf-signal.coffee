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

    it 'filters events by class', co ->
        f1 = spy()
        f2 = spy()
        f3 = spy()

        db.on 'saving', User, f1
        db.on 'saving', db.Model, f2
        db.on 'saving', db.Collection, f3

        yield new User().save()
        f1.should.have.been.called()
        f2.should.have.been.called()
        f3.should.not.have.been.called()

    it 'reject save if callback is rejected', co ->
        f = spy -> throw new Error('blah')
        db.on 'saving', f

        yield new User().save().should.be.rejected
        f.should.have.been.called()

        db.off 'saving', f
        yield new User().save().should.be.fulfilled

    describe 'once', ->
        it "method 'once' doesn't unsubscribe callback if it was not called", co ->
            class User2 extends db.Model
                tableName: 'users'

            f = spy()
            db.once 'saving', User2, f

            yield new User().save().should.be.fulfilled
            f.should.not.have.been.called()
            yield [
                new User2().save().should.be.fulfilled
                new User2().save().should.be.fulfilled
            ]
            f.should.be.called.once


    describe 'off', ->
        it 'can unsubscribe handler and class pair', co ->
            f = spy()
            db.on 'saving', db.Model, f

            yield new User().save().should.be.fulfilled
            f.should.have.been.called()

            f.reset()
            db.off 'saving', db.Model, f

            yield new User().save().should.be.fulfilled
            f.should.not.have.been.called()

        it 'unsubscribes all filtered handlers if cls not passed', co ->
            f1 = spy()
            f2 = spy()
            db.on 'saving', User, f1
            db.on 'saving', db.Model, f1
            db.on 'saving', f1
            db.on 'saving', f2

            yield new User().save().should.be.fulfilled
            f1.should.have.been.called.exactly(3)
            f2.should.have.been.called.once

            f1.reset()
            f2.reset()
            db.off 'saving', f1

            yield new User().save().should.be.fulfilled
            f1.should.not.have.been.called()
            f2.should.have.been.called.once
