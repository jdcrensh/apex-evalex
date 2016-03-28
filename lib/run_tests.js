/*jslint browser: true, regexp: true */
/*global require, process, console */

var Q = require('q');
var fs = require('fs');
var lo = require('lodash');
var jsforce = require('jsforce');
var restler = require('restler');

/** The salesforce client */
var sfdc_client = new jsforce.Connection({loginUrl : process.env.SFDC_URL});

/** A map of class Ids to class information */
var id_to_class_map = {};

/** A map of test class Ids to class information */
var test_class_map = {};

/**
* Log into the salsforce instance
*/
var sfdcLogin = function () {
	'use strict';

	var deferred = Q.defer();

	console.log('Logging in as ' + process.env.SFDC_USERNAME);

	sfdc_client.login(process.env.SFDC_USERNAME, process.env.SFDC_PASSWORD + process.env.SFDC_TOKEN, function (error, res) {
		if (error) {
			deferred.reject(new Error(error));
		} else {
			console.log('Logged in');
			deferred.resolve();
		}
	});

	return deferred.promise;
};

/**
* Builds a map of class id to class data
*/
var buildClassIdToClassDataMap = function () {
	'use strict';

	var class_data = {},
		deferred = Q.defer(),
		path_template = lo.template('src/classes/<%= Name %>.cls');

	console.log('Fetching class information');

	sfdc_client.sobject('ApexClass').find({}).execute(function (error, data) {
		if (error) {
			deferred.reject(new Error(error));
		} else {
			console.log('Got information about ' + lo.size(data) + ' classes');

			lo.forEach(data, function (row) {
				if (row.Body.indexOf('@isTest') === -1) {
					id_to_class_map[row.Id] = {
						name: path_template(row),
						source: row.Body,
						coverage: []
					};
				} else {
					test_class_map[row.Id] = {
						name: path_template(row),
						source: row.Body
					};
				}
			});

			deferred.resolve();
		}
	});

	return deferred.promise;
};

/**
* Runs all tests with the tooling api
*/
var runAllTests = function () {
	'use strict';

	var class_ids = lo.keys(test_class_map),
		deferred = Q.defer();

	sfdc_client.tooling.runTestsAsynchronous(class_ids, function (error, data) {
		if (error) {
			deferred.reject(new Error(error));
		} else {
			deferred.resolve(data);
		}
	});

	return deferred.promise;
};

/**
* Query the test results
*
* @param testRunId The id of the test run
* @param deferred The Q.defer instance
*/
var queryTestResults = function myself(testRunId, deferred) {
	'use strict';

	var isComplete = true;

	console.log('Waiting for tests');

	sfdc_client.query('select Id, Status, ApexClassId from ApexTestQueueItem where ParentJobId = \'' + testRunId + '\'', function (error, data) {
		if (error) {
			deferred.reject(new Error(error));
		} else {
			lo.each(data.records, function (row) {
				if (row.Status === 'Queued' || row.Status === 'Processing') {
					isComplete = false;
				}
			});

			if (isComplete) {
				deferred.resolve();
			} else {
				myself(testRunId, deferred);
			}
		}
	});
};

/**
* Waits until all tests are completed
*
* @param testRunId The id of the test run
*/
var waitUntilTestsComplete = function (testRunId) {
	'use strict';

	var deferred = Q.defer();

	queryTestResults(testRunId, deferred);

	return deferred.promise;
};

/**
* Gets the test data and builds an array of the number of times the line was tested
*/
var buildCoverallsCoverage = function () {
	'use strict';

	var max_line, coverage_size, class_id, i,
		deferred = Q.defer();

	console.log('Fetching code coverage information');

	sfdc_client.tooling.sobject('ApexCodeCoverage').find({}).execute(function (error, data) {
		if (error) {
			deferred.reject(new Error(error));
		} else {
			console.log('Got information about ' + lo.size(data) + ' tests');

			lo.forEach(data, function (row) {
				class_id = row.ApexClassOrTriggerId;

				if (lo.has(id_to_class_map, class_id)) {
					max_line = lo.max(lo.union(row.Coverage.coveredLines, row.Coverage.uncoveredLines));
					coverage_size = lo.size(id_to_class_map[class_id].coverage);

					if (max_line > coverage_size) {
						for (i = coverage_size; i <= max_line; i += 1) {
							id_to_class_map[class_id].coverage.push(null);
						}
					}

					lo.forEach(row.Coverage.coveredLines, function (line_number) {
						if (id_to_class_map[class_id].coverage[line_number - 1] === null) {
							id_to_class_map[class_id].coverage[line_number - 1] = 1;
						} else {
							id_to_class_map[class_id].coverage[line_number - 1] += 1;
						}
					});

					lo.forEach(row.Coverage.uncoveredLines, function (line_number) {
						if (id_to_class_map[class_id].coverage[line_number - 1] === null) {
							id_to_class_map[class_id].coverage[line_number - 1] = 0;
						}
					});
				}
			});

			deferred.resolve();
		}
	});

	return deferred.promise;
};

/**
* Posts the data to coveralls
*/
var postToCoveralls = function () {
	'use strict';

	var fs_stats, post_options,
		deferred = Q.defer(),
		coveralls_data = {
			repo_token: process.env.COVERALLS_REPO_TOKEN,
			service_name: 'travis-ci',
			service_job_id: process.env.TRAVIS_JOB_ID,
			source_files: lo.values(id_to_class_map)
		};

	console.log('Posting data to coveralls');

	fs.writeFile('/tmp/coveralls_data.json', JSON.stringify(coveralls_data), function (fs_error) {
		if (fs_error) {
			deferred.reject(new Error(fs_error));
		} else {
			fs_stats = fs.statSync('/tmp/coveralls_data.json');

			post_options = {
				multipart: true,
				data: {
					json_file: restler.file('/tmp/coveralls_data.json', null, fs_stats.size, null, 'application/json')
				}
			};

			restler.post('https://coveralls.io/api/v1/jobs', post_options).on("complete", function (data) {
				deferred.resolve();
			});
		}
	});

	return deferred.promise;
};

Q.fcall(sfdcLogin)
	.then(buildClassIdToClassDataMap)
	.then(runAllTests)
	.then(waitUntilTestsComplete)
	.then(buildCoverallsCoverage)
	.then(postToCoveralls)
	.catch(function (error) {
		'use strict';
		console.log(error);
	})
	.done(function () {
		'use strict';
	});
