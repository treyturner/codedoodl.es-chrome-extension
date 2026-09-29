AbstractView         = require '../AbstractView'
Router               = require '../../router/Router'
CodeWordTransitioner = require '../../utils/CodeWordTransitioner'

class Header extends AbstractView

	template : 'site-header'

	FIRST_HASHCHANGE : true
	DOODLE_INFO_OPEN : false

	EVENT_DOODLE_INFO_OPEN   : 'EVENT_DOODLE_INFO_OPEN'
	EVENT_DOODLE_INFO_CLOSE  : 'EVENT_DOODLE_INFO_CLOSE'
	EVENT_HOME_SCROLL_TO_TOP : 'EVENT_HOME_SCROLL_TO_TOP'

	preinitialize : ->

		@templateVars =
			home_label  : @CD_CE().locale.get('header_logo_label')
			close_label : @CD_CE().locale.get('header_close_label')
			info_label  : @CD_CE().locale.get('header_info_label')

	constructor : ->
		super()
		@init()

		@bindEvents()

		return

	init : =>

		@$logo     = @$el.find('.logo__link')
		@$infoBtn  = @$el.find('.info-btn')
		@$closeBtn = @$el.find('.close-btn')

		null

	bindEvents : =>

		@CD_CE().appView.on @CD_CE().appView.EVENT_PRELOADER_HIDE, @animateTextIn
		@CD_CE().router.on Router.EVENT_HASH_CHANGED, @onHashChange

		@$el.on 'mouseenter', '[data-codeword]', @onWordEnter
		@$el.on 'mouseleave', '[data-codeword]', @onWordLeave

		@$infoBtn.on 'click', @onInfoBtnClick
		@$closeBtn.on 'click', @onCloseBtnClick

		@CD_CE().appView.$window.on 'keyup', @onKeyup

		null

	onHashChange : (where) =>

		if @FIRST_HASHCHANGE
			@FIRST_HASHCHANGE = false

			colorScheme = @_getDoodleColourScheme()
			# CodeWordTransitioner.prepare [@$logo, @$infoBtn], @_getDoodleColourScheme()
			@$logo.add(@$infoBtn)
				.addClass(colorScheme)
				.attr('data-codeword-initial-state', colorScheme)
				.find('[data-codetext-char-state]')
					.attr('data-codetext-char-state', colorScheme)

			CodeWordTransitioner.out [@$closeBtn], colorScheme

			return
		
		@onAreaChange where

		null

	onAreaChange : (section) =>

		@activeSection = section
		
		colour = @getSectionColour section

		@$el.attr 'data-section', section

		CodeWordTransitioner.in @$logo, colour

		if section is @CD_CE().nav.sections.HOME
			CodeWordTransitioner.in [@$infoBtn], colour
			CodeWordTransitioner.out [@$closeBtn], colour
		else if section is 'doodle-info'
			CodeWordTransitioner.in [@$closeBtn], colour
			CodeWordTransitioner.in [@$infoBtn], 'red-active'

		null

	getSectionColour : (section, wordSection=null) =>

		section = section or @CD_CE().nav.current.area or 'home'

		if wordSection and section is wordSection
			if wordSection is 'doodle-info'
				return 'red-active'
			else
				return 'white-active'

		colour = switch section
			when 'home', 'doodle-info' then 'red'
			when @CD_CE().nav.sections.HOME then @_getDoodleColourScheme()
			else 'white'

		colour

	_getDoodleColourScheme : =>

		colour = if @CD_CE().appData.activeDoodle.get('colour_scheme') is 'light' then 'black' else 'white'

		colour

	animateTextIn : =>

		@onAreaChange @CD_CE().nav.current.area

		null

	onWordEnter : (e) =>
		return unless window.matchMedia('(any-hover: hover) and (any-pointer: fine)').matches

		$el = $(e.currentTarget)
		wordSection = $el.attr('data-word-section')

		CodeWordTransitioner.scramble $el, @getSectionColour(@activeSection, wordSection)

		null

	onWordLeave : (e) =>
		return unless window.matchMedia('(any-hover: hover) and (any-pointer: fine)').matches

		$el = $(e.currentTarget)
		wordSection = $el.attr('data-word-section')

		CodeWordTransitioner.unscramble $el, @getSectionColour(@activeSection, wordSection)

		null

	onInfoBtnClick : (e) =>

		e.preventDefault()

		return unless @CD_CE().nav.current.area is @CD_CE().nav.sections.HOME

		if !@DOODLE_INFO_OPEN
			@showDoodleInfo()
		else
			@hideDoodleInfo()

		null

	onCloseBtnClick : (e) =>

		if @DOODLE_INFO_OPEN
			e.preventDefault()
			e.stopPropagation()
			@hideDoodleInfo()

		null

	onKeyup : (e) =>

		if e.keyCode is 27 then @hideDoodleInfo()

		null

	showDoodleInfo : =>

		return unless !@DOODLE_INFO_OPEN

		@onAreaChange 'doodle-info'
		@trigger @EVENT_DOODLE_INFO_OPEN
		@DOODLE_INFO_OPEN = true

		null

	hideDoodleInfo : =>

		return unless @DOODLE_INFO_OPEN

		@onAreaChange @CD_CE().nav.current.area
		@trigger @EVENT_DOODLE_INFO_CLOSE
		@DOODLE_INFO_OPEN = false

		null

module.exports = Header
