bookshelf-signals
=================

The [Bookshelf](http://bookshelfjs.org/) plugin that translates bookshelf events to a central
hub. By default that hub is a bookshelf instance itself. That's useful if you want to subscribe to
an event but don't want to modify model or collection initializer.

Sample code:
------------

```coffee
Signals = require 'bookshelf-signals'
db = bookshelf(knex)
db.plugin Signals()

class User extend db.Model
  tabeName: 'users'

db.on 'saved', User, ->
  console.log 'user was saved!'
```

Plugin
------

```coffee
db.plugin Signals(hub)
```

Argument passed to plugin is a hub to that all bookshelf events will be translated. It should at least implement methods `trigger` and `triggerThen`. If undefined then events will be translated to bookshelf instance and required methods will be added to it.

Default implementation
----------------------

Default hub implementation has a behaviour different from EventEmitter. Its methods on, addListener, once, off, removeListener, removeAllListeners accepts class or model/collection name as a second parameter and performs events filtration according to it.

Methods:

- on(String event, [(Class|String) cls], Function handler)

  Subscribe to event with optional filtration by source class.

- addListener - alias for `on`

- removeListener(String event, [(Class|String) cls], Function handler)

  Unsubscribe from event. If class/name was used for subscription you have to use the same class/name to unsubscribe.

- off - alias for `removeListener`

- once(String event, [(Class|String) cls], handler)

  Subscribe to first event of that type and source class, if filtered.

- removeAllListeners([String event], [(Class|String) cls])

  Unsubscribe all listeners for that event and source class.
