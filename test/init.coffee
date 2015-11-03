Knex = require 'knex'
Bookshelf = require 'bookshelf'
Signals = require '../src/'

db = null
init = ->
    return db if db?

    knex = Knex
            client: 'sqlite'
            debug: process.env.BOOKSHELF_SIGNALS_TESTS_DEBUG?
            connection:
                filename: ':memory:'

    db = Bookshelf knex
    db.plugin Signals()
    db

truncate = co (tables...) -> yield (db.knex(table).truncate() for table in tables)

users = co ->
    init() unless db
    knex = db.knex
    yield knex.schema.dropTableIfExists 'users'
    yield knex.schema.createTable 'users', (table) ->
        table.increments('id').primary()
        table.string 'username', 255

module.exports =
    init: init
    truncate: truncate
    users: users
