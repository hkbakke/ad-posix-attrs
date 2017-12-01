# ad-posix-attrs
Adds POSIX attributes to AD

# Configuration
Put your configuration in `config.json` in the same folder as `add-attrs.ps1`. In many cases this can just be an empty file. There is an example configuration with default values in [config.json.example](src/config.json.example).

# Use
Run in dry-run mode until you are sure it does the right thing:
  .\add-attrs.ps1 -dry-run:$true
  
To write the POSIX attributes, just run:
  .\add-attrs.ps1
