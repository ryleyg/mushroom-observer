Mushroom Observer
=======

Last Revised: September 28, 2014

This README provides a quick overview of the tools used by Mushroom Observer 
(MO) and an overview of the other READMEs that accompany this file.  See
http://mushroomobserver.org/observer/intro for an introduction to the website
itself.

[![CodePolice][1]][2]

Tools
-----

Source code control: The source code for MO is currently managed using
subversion (http://subversion.apache.org).  Version 1.6.5 is known to work and
later versions are very likely to work.  Documentation is available at
http://svnbook.red-bean.com. The URL for the MO source repository is
http://svn.collectivesource.com/mushroom_sightings/. Following typical 
subversion conventions, the latest stable release is in the "trunk"
subdirectory.

The current code has only be run on Unix-based operating systems, in particular
Linux and MacOSX.  However, Rails and Mysql and everything else MO needs is 
available in Windows, so feel free to be the first to try it out!

You'll at very least need to install ruby (1.9.3: the code hasn't been tested
with 1.9), rails (2.1.1: we really need to upgrade to 2.3 or 3.0, but it's not
backwards compatible) and mysql (5.1.47 is known to work, but later ones 
probably will as well).  Fortunately these are all very popular so it's easy
to find pre-built binaries for most operating systems.  New developers have
reported being able to get the system up and running in under two hours.

Other READMEs
-------------

The following files should provide useful information for working with the
Mushroom Observer code base.  Note that we are not great at keeping these up
to date, so be sure to take them with a grain of salt proportional to the
Last Revised date.

README_CODE: Provides a snapshot of the major components of Mushroom Observer.

README_DEVELOPMENT_INSTALL: Describes the steps needed for a developer to get
the code running locally.  You are encouraged to update this document with
your own experience.

README_PRODUCTION_INSTALL: Describes the steps needed to setup our production
environment.

README_STANDARDS: The closest we have to coding standards.  Currently this is
*very* brief.

README_TRANSLATIONS: Details needed for translators to provide support in for
the site in a new language.
Copyright
---------

Code: [Nathan Wilson][3],[Jason Hollinger][4]

Copyright (c) 2014 [Marine Biological Laboratory][12]. See [LICENSE][13] for
further details.

[1]: https://codeclimate.com/github/EOL/taxon_reporter.png
[2]: https://codeclimate.com/github/EOL/taxon_reporter
[3]: https://github.com/mo-nathan
[4]: https://github.com/pellaea
[5]: https://github.com/JoeCohen
