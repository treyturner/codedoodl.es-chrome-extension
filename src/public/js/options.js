// set available options and defaults here
var options = {
	option_autoplay: true,
	option_show_apps_btn: false
};

var checkboxes = $('input[type="checkbox"]');

function getOptions(callback) {

	chrome.storage.sync.get(null, function(cachedData) {

		for (var key in cachedData) {
			if (key.match(/^option_/)) {
				options[key] = cachedData[key];
			}
		}

		callback();

	});

}

function updateCheckboxes() {

	checkboxes.each(function(i, el) {

		el.checked = options[el.name];

	});

}

function onCheckboxChange() {

	var newOption = {};
	newOption[this.name] = this.checked;

	chrome.storage.sync.set(newOption);

}

checkboxes.on('change', onCheckboxChange);

getOptions(updateCheckboxes);
