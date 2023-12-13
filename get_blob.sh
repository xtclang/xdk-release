curl -L -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/xtclang/xvm/git/blobs/175e5e72dfb5b689f606677fcb322775e91da81a |\
    jq -r '.content' |
    base64 --decode > nsis.tar.gz

  #{
  #"message": "Not Found",
  #"documentation_url": "https://docs.github.com/rest/git/blobs#get-a-blob"
#}
