Events = require 'bookshelf/lib/base/events'

plugin = (hub) -> (db) ->
    class EventsHub extends Events
        constructor: ->
            @_handlersWithFilter = []

        addListener: (event, cls, handler) ->
            unless handler?
                handler = cls
                cls = null

            if cls?
                fn = (obj) ->
                    if typeof cls is 'string'
                        if obj instanceof db.Model
                            handler(arguments...) if obj instanceof db.model(cls)
                        else if obj instanceof db.Collection
                            handler(arguments...) if obj instanceof db.collection(cls)
                    else
                        handler(arguments...) if obj instanceof cls
                @_handlersWithFilter.push [cls, handler, fn]
            else
                fn = handler

            super(event, fn)

        on: EventsHub::addListener

        removeListener: (event, cls, handler) ->
            unless handler?
                handler = cls
                cls = null

            if cls
                fn = @_popHandler(cls, handler)
                super(event, fn) if fn
            else
                fns = @_popAllHandlers(handler)
                fns.push handler
                super(event, fn) for fn in fns

        off: EventsHub::removeListener

        once: (event, cls, handler) ->
            once = =>
                @off event, cls, once
                handler(arguments...)
            @on event, cls, once

        removeAllListeners: (event, cls) ->
            unless event
                @_handlersWithFilter = []
                return super()

            unless cls
                # remove unused handlers
                listeners = @listeners event
                @_handlersWithFilter = (x for x in @_handlersWithFilter when x[2] not in listeners)
                return super(event)

            for listener in @listeners(event)
                i = @_findListener(cls, listener)[0]
                unless i is -1
                    @_handlersWithFilter.splice i, 1
                    @removeListener(event, listener)

            undefined

        _findHandler: (cls, handler) ->
            for [cls_, handler_, fn], i in @_handlersWithFilter
                return [i, fn] if cls is cls_ and handler is handler_
            [-1, null]

        _findListener: (cls, fn) ->
            for [cls_, handler, fn_], i in @_handlersWithFilter
                return [i, handler] if cls is cls_ and fn is fn_
            [-1, null]

        _popHandler: (cls, handler) ->
            [i, fn] = @_findHandler(cls, handler)
            if fn?
                @_handlersWithFilter.splice i, 1
            fn

        _popAllHandlers: (handler) ->
            swap = []
            result = []
            for [cls_, handler_, fn] in @_handlersWithFilter
                if handler is handler_
                    result.push fn
                else
                    swap.push [cls_, handler_, fn]
            @_handlersWithFilter = swap
            result

    unless hub?
        hub = new EventsHub()
        db._eventsHub = hub
        for method in ['on', 'addListener', 'off', 'removeListener', 'removeAllListeners',
            'trigger', 'emmit', 'triggerThen', 'emmitThen', 'once']
            do (method) ->
                db[method] = -> hub[method].apply(hub, arguments)

    for base in [db.Model, db.Collection]
        do (base) ->
            oldTriggerThen = base::triggerThen
            base::triggerThen = (args...) ->
                oldTriggerThen.apply(this, arguments)
                .then -> hub.triggerThen args...

            oldTrigger = base::trigger
            base::trigger = (args...) ->
                oldTrigger.apply(this, arguments)
                hub.trigger args...

module.exports = plugin
