'use strict';

module.exports = function(config) {
  config.set({
    basePath: '.',
    frameworks: ['dart-unittest'],
    files: [
      'test/test_*.dart',
 //     'test/config/init_guinness.dart',
      {pattern: '**/*.dart', watched: true, included: false, served: true},
      {pattern: '**/*.html', served: true, included: false},
      'packages/browser/dart.js'
    ],
    autoWatch: true,
    plugins: [
      'karma-dart',
      'karma-chrome-launcher',
      'karma-firefox-launcher',
      'karma-script-launcher',
      'karma-junit-reporter'
    ],

    customLaunchers: {
      ChromeNoSandbox: { base: 'Chrome', flags: ['--no-sandbox'] }
    },

    karmaDartImports: {
 //     guinness: 'package:guinness/guinness_html.dart'
    },

    // If browser does not capture in given timeout [ms], kill it
    captureTimeout: 20000,
    // 5 minutes is enough time for dart2js to run on Travis...
    browserNoActivityTimeout: 300000,

    browsers: ['Dartium', 'Chrome', 'Firefox'],
    reports: ['junit'],

    junitReporter: {
      outputFile: 'test_out/unit.xml',
      suite: 'unit'
    }
  });
};
