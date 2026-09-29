AbstractData      = require './data/AbstractData'
DoodlesCollection = require './collections/doodles/DoodlesCollection'

# Apply publication choices to old caches as well as older API responses.
UNPUBLISHED_SLUGS = ['samsy/fury-ribbons', 'samsy/boobs']

class AppData extends AbstractData

    DOODLE_CACHE_DURATION : 24 * 60 * 60 * 1000

    constructor : (@callback) ->
        super()
        @OPTIONS = autoplay: true, show_apps_btn: false
        @doodles = new DoodlesCollection
        @checkDoodleCache()

    checkDoodleCache : =>
        # Only preferences sync between browsers. Catalogue/rotation are device-local.
        chrome.storage.sync.get ['option_autoplay', 'option_show_apps_btn'], (options) =>
            for key, value of options
                @OPTIONS[key.replace(/^option_/, '')] = value if typeof value is 'boolean'

            chrome.storage.local.get ['doodles', 'lastUpdated'], (cache) =>
                cachedDoodles = if @validDoodles(cache.doodles) then @publishedDoodles(cache.doodles) else []
                if Array.isArray(cache.doodles) and cachedDoodles.length isnt cache.doodles.length
                    chrome.storage.local.set doodles: cachedDoodles
                @lastUpdated = cache.lastUpdated or 0
                if cachedDoodles.length and 0 <= Date.now() - @lastUpdated < @DOODLE_CACHE_DURATION
                    @useDoodles cachedDoodles
                else
                    @fetchDoodles cachedDoodles

    publishedDoodles : (doodles) ->
        doodles.filter (doodle) -> doodle.slug not in UNPUBLISHED_SLUGS

    validDoodles : (doodles) =>
        Array.isArray(doodles) and doodles.length > 0 and doodles.every (doodle) ->
            doodle and typeof doodle.id is 'string' and
                typeof doodle.slug is 'string' and /^[a-zA-Z0-9_-]+\/[a-zA-Z0-9_-]+$/.test(doodle.slug) and
                typeof doodle.name is 'string' and typeof doodle.author?.name is 'string' and
                Array.isArray(doodle.tags) and typeof doodle.instructions is 'string'

    fetchDoodles : (cachedDoodles) =>
        $.ajax
            url: window.config.API_HOST + '/api/doodles'
            dataType: 'json'
            timeout: 15000
        .done (data) =>
            return @onFetchFailed(cachedDoodles) unless @validDoodles(data?.doodles)
            published = @publishedDoodles(data.doodles)
            return @onFetchFailed(cachedDoodles) unless published.length
            viewed = {}
            (viewed[doodle.id] = !!doodle.viewed) for doodle in cachedDoodles
            doodles = _.shuffle(published)
            (doodle.viewed = viewed[doodle.id] or false) for doodle in doodles
            @lastUpdated = Date.now()
            @useDoodles doodles
        .fail => @onFetchFailed cachedDoodles

    onFetchFailed : (cachedDoodles) =>
        if cachedDoodles.length
            @useDoodles cachedDoodles
        else
            $('#preloader').hide()
            $('[data-load-error]').prop('hidden', false)
            $('[data-retry]').one 'click', -> window.location.reload()

    useDoodles : (doodles) =>
        @doodles.reset doodles
        @activeDoodle = @doodles.getNextDoodle()
        chrome.storage.local.set
            lastUpdated: @lastUpdated
            doodles: @doodles.toJSON()
        @callback?()

module.exports = AppData
