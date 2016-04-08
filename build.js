var runTests = require('sfdc-travisci-coveralls');

runTests({
	loginUrl: process.env.SFDC_LOGINURL,
	username: process.env.SFDC_USERNAME,
	password: process.env.SFDC_PASSWORD,
	securityToken: process.env.SFDC_TOKEN,
	travisJobId: process.env.TRAVIS_JOB_ID,
	coverallsRepoToken: process.env.COVERALLS_REPO_TOKEN
}, function (err) {
	throw err;
}, function (data) {
	console.log('done.');
});

