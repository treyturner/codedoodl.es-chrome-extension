AbstractViewPage     = require '../AbstractViewPage'
CodeWordTransitioner = require '../../utils/CodeWordTransitioner'
MediaQueries         = require '../../utils/MediaQueries'

class DoodlePageView extends AbstractViewPage

	template : 'page-doodle'
	model    : null

	colourScheme : null
	refreshTimer : null


	MIN_PADDING_TOP    : 230
	MIN_PADDING_BOTTOM : 85

	preinitialize : ->

		@templateVars =
			refresh_btn_title : @CD_CE().locale.get "doodle_refresh_btn_title"
			random_btn_title  : @CD_CE().locale.get "doodle_random_btn_title"

	constructor : ->
		super()
		@init()

		return

	init : =>

		@$frame        = @$el.find('[data-doodle-frame]')
		@$infoContent  = @$el.find('[data-doodle-info]')
		@$instructions = @$el.find('[data-doodle-instructions]')

		@$refreshBtn = @$el.find('[data-doodle-refresh]')
		@$randomBtn  = @$el.find('[data-doodle-random]')

		@$showDoodleBtnPane = @$el.find('[data-show-doodle-btn-pane]')
		@$showDoodleBtn = @$el.find('[data-show-doodle-btn]')

		null

	setListeners : (setting) =>

		@CD_CE().appView[setting] @CD_CE().appView.EVENT_UPDATE_DIMENSIONS, @onResize

		@CD_CE().appView.header[setting] @CD_CE().appView.header.EVENT_DOODLE_INFO_OPEN, @onInfoOpen
		@CD_CE().appView.header[setting] @CD_CE().appView.header.EVENT_DOODLE_INFO_CLOSE, @onInfoClose

		@$el[setting] 'click', '[data-share-btn]', @onShareBtnClick
		# @$infoContent[setting] 'click', @onInfoContentClick

		@$refreshBtn[setting] 'click', @onRefreshBtnClick
		@$randomBtn[setting] 'click', @onRandomBtnClick

		null

	onResize : =>

		@setupInfoDims()

		null

	show : (cb) =>

		@model = @CD_CE().appData.activeDoodle

		@setupUI()

		super cb

		if @CD_CE().appData.OPTIONS.autoplay
			@showFrame false
		else
			@showShowDoodleBtn()

		null

	hide : (cb) =>

		@CD_CE().appView.header.hideDoodleInfo()

		super cb

		null

	setupUI : =>

		@$infoContent.html @getDoodleInfoContent()

		@$el.attr 'data-color-scheme', @model.get('colour_scheme')
		@$frame.attr('src', '').removeClass('show')

		@colourScheme = if @model.get('colour_scheme') is 'light' then 'black' else 'white'

		@setupInstructions()

		null

	setupInfoDims : =>

		@$doodleInfoContent = @$el.find('[data-doodle-info-content]')
		$inner = @$doodleInfoContent.find('.doodle-info-inner')
		@$doodleInfoContent.removeClass('enable-overflow').css top: ''
		$inner.css(maxHeight: '').attr 'tabindex', -1
		dims = @CD_CE().appView.dims
		narrow = dims.w <= 750 # Matches the Sass small breakpoint.
		@$infoContent.attr 'tabindex', if narrow then 0 else -1
		return if narrow

		# Keep the original placement, but reserve visible content in short windows.
		top = Math.min @MIN_PADDING_TOP, Math.max(60, dims.h - @MIN_PADDING_BOTTOM - 100)
		bounds = @$doodleInfoContent[0].getBoundingClientRect()
		if bounds.top < top or bounds.bottom > dims.h - @MIN_PADDING_BOTTOM
			@$doodleInfoContent.addClass('enable-overflow').css top: top
			$inner.css(maxHeight: Math.max(1, dims.h - top - @MIN_PADDING_BOTTOM)).attr 'tabindex', 0

		null

	showFrame : (removeEvent=true, delay=null) =>

		if removeEvent then @CD_CE().appView.transitioner?.off @CD_CE().appView.transitioner.EVENT_TRANSITIONER_OUT_DONE, @showFrame

		@$frame.attr 'src', "#{@CD_CE().DOODLES_URL}/#{@model.get('slug')}/index.html"
		@$frame.one 'load', => @showDoodle delay

		null

	showDoodle : (delay) =>

		@$frame.addClass('show')
		setTimeout =>
			blankInstructions = @model.get('instructions').split('').map(-> return ' ').join('')
			CodeWordTransitioner.to blankInstructions, @$instructions, @colourScheme
		, delay or 1000

		# allow frame to transition in and then focus it
		setTimeout =>
			# Opening information during loading must not lose keyboard focus later.
			@$frame[0].focus() if @$frame.hasClass('show') and !@$el.hasClass('show-info')
		, 500

		null

	hideDoodle : =>

		@$frame.removeClass('show')

		null

	setupInstructions : =>

		$newInstructions = @getInstructions()
		@$instructions.replaceWith $newInstructions
		@$instructions = $newInstructions

		null

	getInstructions : =>

		$instructionsEl = $('<span />')
		$instructionsEl
			.addClass('doodle-instructions')
			.attr('data-codeword', '')
			.attr('data-doodle-instructions', '')
			.text(@model.get('instructions').toLowerCase())

		console.log "@model.get('instructions').toLowerCase()"
		console.log @model.get('instructions').toLowerCase()

		colourScheme = if @model.get('colour_scheme') is 'light' then 'black' else 'white'
		CodeWordTransitioner.prepare $instructionsEl, @colourScheme

		console.log "$instructionsEl"
		console.log $instructionsEl

		$instructionsEl

	getDoodleInfoContent : =>

		doodleInfoVars =
			indexHTML                   : @model.get('indexHTML')
			thumb                       : @CD_CE().DOODLES_URL + '/' + @model.get('slug') + '/thumb.jpg'
			label_author                : @CD_CE().locale.get "doodle_label_author"
			content_author              : @model.getAuthorHtml()
			label_doodle_name           : @CD_CE().locale.get "doodle_label_doodle_name"
			content_doodle_name         : @model.get('name')
			label_doodle_instructions   : @CD_CE().locale.get 'doodle_label_instructions'
			content_doodle_instructions : @model.get('instructions') or @CD_CE().locale.get 'doodle_label_instructions_none'
			label_description           : @CD_CE().locale.get "doodle_label_description"
			content_description         : @model.get('description')
			label_tags                  : @CD_CE().locale.get "doodle_label_tags"
			content_tags                : @model.get('tags').join(', ')
			label_interaction           : @CD_CE().locale.get "doodle_label_interaction"
			content_interaction         : @_getInteractionContent()
			label_share                 : @CD_CE().locale.get "doodle_label_share"
			share_url                   : @CD_CE().SITE_URL + '/' + @model.get('id')
			share_url_text              : @CD_CE().SITE_URL.replace(/^https?:\/\//, '') + '/' + @model.get('id')
			mouse_enabled               : @model.get('interaction').mouse
			keyboard_enabled            : @model.get('interaction').keyboard
			touch_enabled               : @model.get('interaction').touch

		doodleInfoContent = @CD_CE().templates.get('doodle-info')(doodleInfoVars)

		doodleInfoContent

	_getInteractionContent : =>

		interactions = []

		if @model.get('interaction').mouse then interactions.push @CD_CE().locale.get "doodle_label_interaction_mouse"
		if @model.get('interaction').keyboard then interactions.push @CD_CE().locale.get "doodle_label_interaction_keyboard"
		if @model.get('interaction').touch then interactions.push @CD_CE().locale.get "doodle_label_interaction_touch"

		interactions.join(', ') or @CD_CE().locale.get "doodle_label_interaction_none"

	onInfoOpen : =>

		@setupInfoDims()

		@$el.addClass('show-info')

		null

	onInfoClose : =>

		@$el.removeClass('show-info')

		@$infoContent.scrollTop 0
		@$doodleInfoContent.find('.doodle-info-inner').scrollTop 0
		@$frame[0].focus() if @$frame.hasClass('show')

		null

	onShareBtnClick : (e) =>

		e.preventDefault()

		shareMethod = $(e.currentTarget).attr('data-share-btn')
		url         = if shareMethod is 'facebook' then @CD_CE().SITE_URL + '/' + @model.get('id') else ' '
		desc        = @getShareDesc()

		@CD_CE().share[shareMethod] url, desc

		null

	getShareDesc : =>

		vars =
			doodle_name   : @model.get 'name'
			doodle_author : if @model.get('author').twitter then "@#{@model.get('author').twitter}" else @model.get('author').name
			share_url     : @CD_CE().SITE_URL + '/' + @model.get('id')
			doodle_tags   : _.map(@model.get('tags'), (tag) -> '#' + tag).join(' ')

		desc = @supplantString @CD_CE().locale.get('doodle_share_text_tmpl'), vars, false

		desc.replace(/&nbsp;/g, ' ')

	onInfoContentClick : (e) =>

		if e.target is @$infoContent[0] then @CD_CE().appView.header.hideDoodleInfo()

		null

	onRefreshBtnClick : =>

		CodeWordTransitioner.in @$instructions, @colourScheme
		@hideDoodle()

		clearTimeout @refreshTimer
		@refreshTimer = setTimeout =>
			@showFrame false, 2000
		, 1000

		null

	onRandomBtnClick : =>

		window.location.reload()

		null

	showShowDoodleBtn : =>

		@$showDoodleBtn.text 'show `' + @model.get('author').name + ' \\ ' + @model.get('name') + '`'

		@$showDoodleBtnPane.addClass('show')
		@showDoodleBtnColour = if @model.get('colour_scheme') is 'light' then 'black' else 'white'

		CodeWordTransitioner.prepare @$showDoodleBtn, @showDoodleBtnColour

		@$showDoodleBtn.on 'mouseenter', @onShowDoodleBtnEnter
		@$showDoodleBtn.on 'mouseleave', @onShowDoodleBtnLeave
		@$showDoodleBtn.on 'click', @onShowDoodleBtnClick

		null

	onShowDoodleBtnEnter : (e) =>
		return unless window.matchMedia('(any-hover: hover) and (any-pointer: fine)').matches

		CodeWordTransitioner.scramble @$showDoodleBtn, @showDoodleBtnColour

		null

	onShowDoodleBtnLeave : (e) =>
		return unless window.matchMedia('(any-hover: hover) and (any-pointer: fine)').matches

		CodeWordTransitioner.unscramble @$showDoodleBtn, @showDoodleBtnColour

		null

	onShowDoodleBtnClick : =>

		@$showDoodleBtn.off 'mouseenter', @onShowDoodleBtnEnter
		@$showDoodleBtn.off 'mouseleave', @onShowDoodleBtnLeave

		emptyBtnText = @$showDoodleBtn.text().split('').map(-> return ' ').join('')
		CodeWordTransitioner.to emptyBtnText, @$showDoodleBtn, @showDoodleBtnColour + '-no-border'

		@$showDoodleBtnPane.addClass('hide')

		setTimeout =>
			@showFrame false
		, 300

		null

module.exports = DoodlePageView
