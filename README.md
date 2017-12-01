# ad-posix-attrs
Adds [RFC2307](https://www.ietf.org/rfc/rfc2307.txt) POSIX attributes to Active Directory for existing users and groups.

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

    .\add-attrs.ps1 -dry-run:$true
  
To write the POSIX attributes, just run:

    .\add-attrs.ps1
