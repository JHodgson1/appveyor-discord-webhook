# Author: Sankarsan Kampa (a.k.a. k3rn31p4nic)
# License: MIT

$STATUS=$args[0]
$WEBHOOK_URL=$args[1]

if (!$WEBHOOK_URL) {
  Write-Output "WARNING!!"
  Write-Output "You need to pass the WEBHOOK_URL environment variable as the second argument to this script."
  Write-Output "For details & guide, visit: https://github.com/DiscordHooks/appveyor-discord-webhook"
  Exit
}

Write-Output "[Webhook]: Sending webhook to Discord..."

Switch ($STATUS) {
  "success" {
    $EMBED_COLOR=1357344
    $STATUS_MESSAGE="Build passed!"
    
    # set to orange for non-main-releases
    if (!($env:CONFIGURATION -eq "Release")) {
      $EMBED_COLOR=12495189
    }
    Break
  }
  "failure" {
    $EMBED_COLOR=12916741
    $STATUS_MESSAGE="Build failed! :("
    Break
  }
  default {
    Write-Output "Default!"
    Break
  }
}
$AVATAR="https://avatars3.githubusercontent.com/u/35406737"

if (!$env:APPVEYOR_REPO_COMMIT) {
  $env:APPVEYOR_REPO_COMMIT="$(git log -1 --pretty="%H")"
}

$AUTHOR_NAME="$(git log -1 "$env:APPVEYOR_REPO_COMMIT" --pretty="%aN")"
$COMMITTER_NAME="$(git log -1 "$env:APPVEYOR_REPO_COMMIT" --pretty="%cN")"
$COMMIT_SUBJECT="$(git log -1 "$env:APPVEYOR_REPO_COMMIT" --pretty="%s")"
$COMMIT_MESSAGE="$(git log -1 "$env:APPVEYOR_REPO_COMMIT" --pretty="%b")"

if ($AUTHOR_NAME -eq $COMMITTER_NAME) {
  $CREDITS="$AUTHOR_NAME authored & committed"
}
else {
  $CREDITS="$AUTHOR_NAME authored & $COMMITTER_NAME committed"
}

if ($env:APPVEYOR_PULL_REQUEST_NUMBER) {
  $COMMIT_SUBJECT="PR #$env:APPVEYOR_PULL_REQUEST_NUMBER - $env:APPVEYOR_PULL_REQUEST_TITLE"
  $URL="https://github.com/$env:APPVEYOR_REPO_NAME/pull/$env:APPVEYOR_PULL_REQUEST_NUMBER"
}
else {
  $URL=""
}

$BUILD_VERSION = [uri]::EscapeDataString($env:APPVEYOR_BUILD_VERSION)
$TIMESTAMP="$(Get-Date -format s)Z"

if ($env:CONFIGURATION -eq "Release") {
  $CONTENT = "<@&836968319935709256>"
}

$WEBHOOK_DATA="{
  ""username"": """",
  ""avatar_url"": ""$AVATAR"",
  ""content"": ""$CONTENT"",
  ""embeds"": [ {
    ""color"": $EMBED_COLOR,
    ""author"": {
      ""name"": ""Job #$env:APPVEYOR_JOB_NUMBER (Build #$env:APPVEYOR_BUILD_NUMBER) $STATUS_MESSAGE - $env:APPVEYOR_REPO_NAME"",
      ""url"": ""https://ci.appveyor.com/project/$env:APPVEYOR_ACCOUNT_NAME/$env:APPVEYOR_PROJECT_SLUG/build/$BUILD_VERSION"",
      ""icon_url"": ""$AVATAR""
    },
    ""title"": ""$COMMIT_SUBJECT"",
    ""url"": ""$URL"",
    ""description"": ""$COMMIT_MESSAGE $CREDITS"",
    ""fields"": [
      {
        ""name"": ""Commit"",
        ""value"": ""[``$($env:APPVEYOR_REPO_COMMIT.substring(0, 7))``](https://github.com/$env:APPVEYOR_REPO_NAME/commit/$env:APPVEYOR_REPO_COMMIT)"",
        ""inline"": true
      },
      {
        ""name"": ""Branch"",
        ""value"": ""[``$env:APPVEYOR_REPO_BRANCH``](https://github.com/$env:APPVEYOR_REPO_NAME/tree/$env:APPVEYOR_REPO_BRANCH)"",
        ""inline"": true
      },
      {
        ""name"": ""Configuration"",
        ""value"": ""[``$env:CONFIGURATION``](https://ci.appveyor.com/project/$env:APPVEYOR_ACCOUNT_NAME/$env:APPVEYOR_PROJECT_SLUG/build/job/$env:APPVEYOR_JOB_ID)"",
        ""inline"": true
      }
    ],
    ""timestamp"": ""$TIMESTAMP""
  } ]
}"

if ($env:CONFIGURATION -eq "Release") {
  $WEBHOOK_DATA.CONTENT = "<@&836968319935709256>"
}

Invoke-RestMethod -Uri "$WEBHOOK_URL" -Method "POST" -UserAgent "AppVeyor-Webhook" `
  -ContentType "application/json" -Header @{"X-Author"="k3rn31p4nic#8383"} `
  -Body $WEBHOOK_DATA

Write-Output "[Webhook]: Successfully sent the webhook."
