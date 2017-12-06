param (
    [switch]$DryRun,
    [switch]$IncludeAdministrator,
    [switch]$Force
)

# Stop execution on all errors
$ErrorActionPreference = "Stop"

# Defaults
$id_offset = 300000
$login_shell = "/bin/bash"
$homedir_root = "/home/$($(Get-ADDomain).DNSRoot)"
$search_bases = @($(Get-ADDomain).DistinguishedName)

# Import config
$config = Get-Content -Raw -Path config.json | ConvertFrom-Json
if ($config.id_offset) {
    $id_offset = $config.id_offset
}
if ($config.login_shell) {
    $login_shell = $config.login_shell
}
if ($config.homedir_root) {
    $homedir_root = $config.homedir_root
}
if ($config.search_bases) {
    $search_bases = $config.search_bases
}

# Hard-coded variables
$user_posix_attrs = "uidNumber", "gidNumber", "unixHomeDirectory", "loginShell"
$group_posix_attrs = "gidNumber"
$administrator_sid_uid = 500


#
# User functions
#
function get_sid_uid ($ad_user) {
    return [int]"$($ad_user.SID)".split('-')[7]
}

function get_uid ($ad_user) {
    $sid_uid = get_sid_uid $ad_user
    return $id_offset + $sid_uid
}

function get_username ($ad_user) {
    return $ad_user.SamAccountName
}

function get_primary_group_id ($ad_user) {
    return $id_offset + [int]$ad_user.PrimaryGroupID
}

function get_homedir ($username) {
    return "${homedir_root}/${username}"
}

function update_user_attrs ($username, $attrs) {
    Write-Host "`nUpdating attributes for user '${username}'"
    Write-Host $($attrs | Out-String)
    if (-Not ($DryRun)) {
        Set-ADUser -Identity $username -Replace $attrs
    }
}

function clear_user_attrs ($username, $attrs) {
    Write-Host "`nClearing attributes for user '${username}'"
    Write-Host $($attrs | Out-String)
    if (-Not ($DryRun)) {
        Set-ADUser -Identity $username -Clear $attrs
    }
}

function get_missing_user_attrs ($ad_user) {
    $current_attrs = $ad_user | Select $user_posix_attrs
    $missing_attrs = @()

    foreach ($attr in $user_posix_attrs) {
        if (-Not ($current_attrs.$attr)) {
            $missing_attrs += $attr
        }
    }

    return $missing_attrs
}

function add_user_attributes ($search_base) {
    foreach ($ad_user in Get-ADUser -Filter * -SearchBase $search_base -Properties $(@("PrimaryGroupID") + $user_posix_attrs)) {
        $uid = get_uid $ad_user
        $gid = get_primary_group_id $ad_user
        if ($uid -eq $id_offset -Or $gid -eq $id_offset) {
            continue
        }

        if ($Force) {
            $missing_attrs = $user_posix_attrs
        } else {
            $missing_attrs = get_missing_user_attrs $ad_user
        }

        $username = get_username $ad_user
        $sid_uid = get_sid_uid $ad_user
        if ((-Not ($IncludeAdministrator)) -and ($sid_uid -eq $administrator_sid_uid)) {
            # Pipe via Select-Object to handle empty arrays
            if (Compare-Object @($missing_attrs | Select-Object) @($user_posix_attrs | Select-Object)) {
                clear_user_attrs $username $user_posix_attrs
            }
            continue
        }

        $new_attrs = @{}
        foreach ($attr in $missing_attrs) {
            switch ($attr) {
                "uidNumber" {
                    $new_attrs.$attr = $uid
                }
                "gidNumber" {
                    $new_attrs.$attr = $gid
                }
                "unixHomeDirectory" {
                    $new_attrs.$attr = get_homedir $username
                }
                "loginShell" {
                    $new_attrs.$attr = $login_shell
                }
            }
        }

        if ($new_attrs.Count -gt 0) {
            update_user_attrs $username $new_attrs
        }
    }
}

#
# Group functions
#
function get_sid_gid ($ad_group) {
    return [int]"$($ad_group.SID)".split('-')[7]
}

function get_gid ($ad_group) {
    $sid_gid = get_sid_gid $ad_group
    return $id_offset + $sid_gid
}

function get_groupname ($ad_group) {
    return $ad_group.SamAccountName
}

function update_group_attrs ($groupname, $attrs) {
    Write-Host "`nUpdating attributes for group '${groupname}'"
    Write-Host $($attrs | Out-String)
    if (-Not ($DryRun)) {
        Set-ADGroup -Identity $groupname -Replace $attrs
    }
}

function get_missing_group_attrs ($ad_group) {
    $current_attrs = $ad_group | Select $group_posix_attrs
    $missing_attrs = @()

    foreach ($attr in $group_posix_attrs) {
        if (-Not ($current_attrs.$attr)) {
            $missing_attrs += $attr
        }
    }

    return $missing_attrs
}

function add_group_attributes ($search_base) {
    foreach ($ad_group in Get-ADGroup -Filter * -SearchBase $search_base -Properties $group_posix_attrs) {
        $gid = get_gid $ad_group
        if ($gid -eq $id_offset) {
            continue
        }

        if ($Force) {
            $missing_attrs = $group_posix_attrs
        } else {
            $missing_attrs = get_missing_group_attrs $ad_group
        }

        $new_attrs = @{}
        foreach ($attr in $missing_attrs) {
            switch ($attr) {
                gidNumber {
                    $new_attrs.$attr = $gid
                }
            }
        }

        $groupname = get_groupname $ad_group
        if ($new_attrs.Count -gt 0) {
            update_group_attrs $groupname $new_attrs
        }
    }
}


#
# Run
#
foreach ($search_base in $search_bases) {
    Write-Host "Generating POSIX attributes for users in '${search_base}'"
    add_user_attributes $search_base

    Write-Host "Generating POSIX attributes for groups in '${search_base}'"
    add_group_attributes $search_base
}
