repo for data extraction from structured or semi-structured forms and documents

There are some requirements that are not committed in the git repo, in order to
communicate with external tools:

## wrgl

Install (and update) with this snippet:

```bash
sudo bash -c 'curl -L https://github.com/wrgl/wrgl/releases/latest/download/install.sh | bash'
```

There's no need to authenticate before hand, it will ask you for credentials
during push/pull as needed.

## dropbox

`share/creds/dropbox-auth-token.rds` should be a saved Dropbox authorization
token generated using the
[`rdrop2::drop_auth()`](https://github.com/karthik/rdrop2) from the
[rdrop2](https://github.com/karthik/rdrop2) R package.
