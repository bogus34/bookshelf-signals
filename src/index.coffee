Events = require 'bookshelf/lib/base/events'

plugin = (hub) -> (db) ->
    class EventsHub extends Events
        on: (event, cls, handler) ->
            unless handler?
                handler = cls
                cls = null

            fn = if cls?
                (obj) ->
                    if typeof cls is 'string'
                        if obj instanceof db.Model
                            handler(arguments...) if obj instanceof db.model(cls)
                        else if obj instanceof db.Collection
                            handler(arguments...) if obj instanceof db.collection(cls)
                    else
                        handler(arguments...) if obj instanceof cls
            else
                handler

            super(event, fn)

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
