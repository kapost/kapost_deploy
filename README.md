# KapostDeploy

[![Gem Version](https://badge.fury.io/rb/kapost_deploy.svg)](http://badge.fury.io/rb/kapost_deploy)
[![Code Climate GPA](https://codeclimate.com/github/kapost/kapost_deploy.svg)](https://codeclimate.com/github/kapost/kapost_deploy)
[![Code Climate Coverage](https://codeclimate.com/github/kapost/kapost_deploy/coverage.svg)](https://codeclimate.com/github/kapost/kapost_deploy)

<!-- Tocer[start]: Auto-generated, don't remove. -->

# Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Setup](#setup)
- [Tests](#tests)
- [Versioning](#versioning)
- [Contributions](#contributions)
- [License](#license)
- [History](#history)
- [Credits](#credits)

<!-- Tocer[finish]: Auto-generated, don't remove. -->

# Features

`KapostDeploy::Task.define` creates the following rake tasks to aid in the pipeline promotion deployment of Heroku applications

    [promote]
      Promotes a source environment to production

    [promote:before_promote]
      Executes application-defined before promotion code as defined in task config (See below)

    [promote:after_promote]
      Executes application-defined after promotion code as defined in task config (See below)

Simple Example:

    require "kapost_deploy/task"

    KapostDeploy::Task.define do |config|
      config.app = "cabbage-staging"
      config.to = "cabbage-production"
      config.pipeline = "cabbage"
      config.heroku_api_token = "123"

      config.after do
        puts "It's Miller time"
      end
    end

A slightly more complex example which will create 6 rake tasks: stage:before_stage, stage,
stage:after_stage, promote:before_promote, promote, promote:after_promote

    require "kapost_deploy/task"
    require "kapost_deploy/plugins/slack_after_promote"
    require "kapost_deploy/plugins/slack_github_diff"
    require "kapost_deploy/plugins/db_migrate"

    CONFIG = {
      slack_config: {
        webhook_url: "https://hooks.slack.com/services/34326/FDSJFH127/68357sdhfjhHSJGFNMDngsd",
        channel: "#danger",
        icon_url: "http://yourcompany.s3.amazonaws.com/logo.png"
      },
      git_config: {
        github_repo: "yourcompany/widget"
      }
    }.freeze

    KapostDeploy::Task.define(:stage) do |config|
      config.app = "cabbage-staging"
      config.to = "cabbage-sandbox"
      config.pipeline = "cabbage"
      config.heroku_api_token = "123"

      config.options = CONFIG

      config.after do
        sleep 60*2 wait for dynos to restart
        slack.notify "The eagle has landed. [Go validate](https://testbed.sandbox.com/dashboard)!"
        Launchy.open("https://testbed.sandbox.com/dashboard")
      end

      config.add_plugin(KapostDeploy::Plugins::DbMigrate)
    end

    KapostDeploy::Task.define do |config|
      config.app = "cabbage-sandboxc"
      config.to = "cabbage-production"
      config.pipeline = "cabbage"
      config.heroku_api_token = "123"

      config.options = CONFIG

      config.before do
        puts "Are you sure you did x, y, and z? yes/no: "
        confirm = gets.strip
        exit(1) unless confirm.downcase == "yes"
      end

      config.add_plugin(KapostDeploy::Plugins::SlackGithubDiff)
      config.add_plugin(KapostDeploy::Plugins::DbMigrate)
      config.add_plugin(KapostDeploy::Plugins::SlackAfterPromote)
    end

# Requirements

0. [MRI 2.3.0](https://www.ruby-lang.org)
0. [Heroku Toolbelt](https://github.com/heroku/heroku) installed

# Configuration Options

* `pipeline`: The application pipeline to promote
* `heroku_api_token`: Your platform api token. You can retrieve this using `heroku auth:token`
* `app`: The application to be promoted
* `to`: The downstream application(s) to receive the promotion. For multiple environments, use an array.
* `options`: An options hash containing plugin options:
  * `git_config`: If using github plugins, an options hash containing the following keys:
    * `github_repo`: The owner/repo string, such as `kapost/kapost_deploy`
  * `slack_config`: If using slack plugins, an options hash containing the following keys:
    * `webhook_url`: The webhook URL you added to your slack integrations
    * `username`: The apparent username of the notifier *defaults to "webhooks bot"*
    * `channel`: The channel name to post the notification to *defaults to "#general"*
    * `icon_url`: A URL for the icon image *optional*
    * `icon_emoji`: Emoji name to use instead of an icon *optional*

# Setup

To install, type the following:

    gem install kapost_deploy

Add the following to your Gemfile:

    gem "kapost_deploy"

# Tests

To test, run:

    bundle exec rake

# Versioning

Read [Semantic Versioning](http://semver.org) for details. Briefly, it means:

- Patch (x.y.Z) - Incremented for small, backwards compatible bug fixes.
- Minor (x.Y.z) - Incremented for new, backwards compatible public API enhancements and/or bug fixes.
- Major (X.y.z) - Incremented for any backwards incompatible public API changes.

# Contributions

Fork the project.
Make your feature addition or bug fix.
Do not bump the version number.
Send me a pull request. Bonus points for topic branches.

# License

MIT

Copyright (c) 2016 [Kapost](http://engineering.kapost.com).

# History

Read the [CHANGELOG](CHANGELOG.md) for details.
Built with [Gemsmith](https://github.com/bkuhlmann/gemsmith).

# Credits

Developed by [Brandon Croft](http://brandoncroft.com) at [brandon@kapost.com](mailto:brandon@kapost.com).
