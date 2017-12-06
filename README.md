# ad-posix-attrs
Autogenerates [RFC2307](https://www.ietf.org/rfc/rfc2307.txt) POSIX attributes for existing Active Directory users and groups.

For users the following attributes are updated:
* uidNumber
* gidNumber
* unixHomeDirectory
* loginShell

For groups the following attributes are updated:
* gidNumber

# Configuration
Put your configuration in `config.json` in the same folder as `add-attrs.ps1`. In many cases this can just be an empty file. There is an example configuration with default values in [config.json.example](src/config.json.example).

# Use
Run in dry-run mode until you are sure it does the right thing:

    .\add-attrs.ps1 -DryRun:$true

To write the POSIX attributes, just run:

    .\add-attrs.ps1

# Note about the Administrator user
The Administrator user will by default be ignored, and any existing POSIX attributes cleared. This is to be compatible with the Administrator to root mapping in modern Samba Active Directory Domain Controllers. Administrator will not be mapped to root if it has a uidNumber set. However, if you only have Windows Active Directory Domain Controllers it may make sense to assign POSIX attributes to Administrator too, as this user is no more special to non-Windows hosts than any other domain user in behaviour or access levels. To do this set `-IgnoreAdministrator:$false`.
