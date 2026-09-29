class Templates

    constructor : (@templates, callback) ->
        callback?()

    get : (id) =>
        @templates[id]

module.exports = Templates
