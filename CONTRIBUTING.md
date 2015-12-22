# Contributing

> Please, take into account that TDJobs is governed by the Talos Digital's
[Project Governance policy](https://github.com/talosdigital/docs), to see how
you can manage your contribution and what to consider when contributing to this
project check the [Collaborator Guide](https://github.com/talosdigital/docs).

Thanks for your interest in TDJobs! You can contribute in many ways. Here are some of them:

## Reporting bugs and issues
Head over to [this repository's issues page](https://github.com/talosdigital/TDJobs/issues), and
open a new one! It's very helpful if you specify as much as you can about the environment you're
working on, and the steps to reproduce the issue!

## Submitting a pull request
- Fork the repository and create a feature branch for your contribution.
- Run ``rspec`` to check that all tests pass, prior to modifying anything.
- Install Yard ``gem install yard`` and generate the project's docs: ``yardoc``.
- All docs will be generated under ``/doc``. Alternatively, you can tell Yard to serve the files
for you: ``yard server``. Open your browser and navigate to localhost:8808. Ta-da!
- Write tests for the code you write, and check the code coverage report in
``/coverage/index.html``, generated when you run ``rspec`` and make sure you tested everything.
- Make sure everything's nice and clean with ``rake rubocop:check``. This helps the project
have a (closer to) consistent style across its codebase.
- Document your code with [Yard](http://www.rubydoc.info/gems/yard/).
- If applicable, document your changes in the [README](README.md). Use markdown to keep a neat
style. [Dillinger](http://dillinger.io/) is a nice editor, check it out!
- Submit a pull request!
