repo for data extraction from structured or semi-structured forms and documents

There are some requirements that are not committed in the git repo, in order to
communicate with external tools:

## wrgl

[Install](https://www.wrgl.co/doc/guides/installation) wrgl binary and authenticate with

```bash
wrgl credentials authenticate https://hub.wrgl.co/api
```

## dropbox

`share/creds/dropbox-auth-token.rds` should be a saved Dropbox authorization
token generated using the
[`rdrop2::drop_auth()`](https://github.com/karthik/rdrop2) from the
[rdrop2](https://github.com/karthik/rdrop2) R package.
