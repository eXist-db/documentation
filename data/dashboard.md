# Dashboard

## About the Dashboard

The eXist-db Dashboard is the central application launchpad and administration facility for eXist-db. Much like a tablet or smartphone home screen, the Dashboard displays a list of applications, or "apps".

The Dashboard supports both "apps" and "plugins". Apps are self-contained applications providing their own web GUI, while "plugins" run inside the Dashboard as simple, single-screen dialogs. Examples for apps are the eXist-db documentation, eXide, or the demo app. Examples for plugins are the package manager or the collection browser. Plugins are most suitable for administrative functions.

In addition to applications and plugins, the package repository does also provide library and resource packages. They do usually not provide a web GUI and are thus not visible on the Dashboard home screen. However, they will appear in the list of installed packages within the package manager. You can read more about the different types of packages in the [package repository documentation](repo.md).

## Login

To fully use the administration plugins, you need to be logged in as a dba user. You may access plugins as a non-dba user, but as soon as you want to apply changes, you will get a permission error.

You can log in by clicking on the link in the left corner of the Dashboard frame. If you are logged in as another user, click on the user name to log out.

## Using the Package Manager

The Package Manager lists all installed and available packages. If updates to installed packages are available, this is marked in red.

To filter the package list, select the corresponding radio buttons to see either installed or available packages. Detailed information about each package can be viewed by selecting the show details checkbox in the upper-right corner.

### Installing/Removing a Package

To install an app from the public repository, move your mouse over the app. You should see an install button if the app is not currently installed, or a remove button if it is.

### Updating a Package

Updates to already installed packages appear with the currently installed and the available version number in red. Another note is displayed if a package requires a certain version of eXist-db. If this is the case, please make sure you are on the correct version before you attempt to install it.

Clicking on the install button will update the package, removing the old one.

### Browser Caching

Some apps like eXide or the Dashboard rely on JavaScript libraries. After an update, your browser may still use the old libraries, which may affect the functionality of the app. You should at least reload any open page belonging to those apps. A corresponding warning will be shown during the update.

### Installing an Older Version

Sometimes you may want to go back to an older version of a package. To see all available versions, switch to the detail view, using the show details button. However, older versions will only be displayed for packages which are not installed, so you have to remove the corresponding package first.

### Uploading Your Own Packages

Instead of installing from the public repository, you can also upload a package to the server from your local disk. The package has to be in `.xar` format.

## Further Information for Developers

\[To be completed...\]

Plugins are loaded and unloaded on demand via dojo's AMD loader. They are modular, self-contained units. To add a new plugin, you need to provide an HTML and a `.js` file, which defines a subclass of the base plugin class. The source code for the dashboard is available on [GitHub](http://github.com/eXist-db/dashboard).
