AbstractCollection = require '../AbstractCollection'
DoodleModel        = require '../../models/doodle/DoodleModel'

class DoodlesCollection extends AbstractCollection

    model : DoodleModel

    getDoodleBySlug : (slug) =>

        doodle = @findWhere slug : slug

        if !doodle
            console.log "y u no doodle?"

        return doodle

    getDoodleByNavSection : (whichSection) =>

        section = @CD_CE().nav[whichSection]

        doodle = @findWhere slug : "#{section.sub}/#{section.ter}"

        doodle

    getPrevDoodle : (doodle) =>

        index = @indexOf doodle
        index--

        if index < 0
            return false
        else
            return @at index

    addNew : (doodles) =>

        for doodle in doodles
            if !@findWhere( index : doodle.index )
                @add doodle

        null

    getNextDoodle : =>

        for doodle in @models

            if !doodle.get('viewed')
                doodle.set('viewed', true)
                nextDoodle = doodle
                break

        if !nextDoodle
            nextDoodle = _.shuffle(@models)[0]

        nextDoodle

module.exports = DoodlesCollection
