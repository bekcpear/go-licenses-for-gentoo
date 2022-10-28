
**Prepare**

```bash
# 1. install go-licenses
go install github.com/google/go-licenses@latest

# 2. add the "${GOPATH}/bin" to PATH variable
#    or change the `_go_licenses_cmd` variable in golic.sh to "${GOPATH}/bin/go-licenses"
```

**Generate LICENSE**

```bash
./golic.sh /path/to/go-module-proj
# you may need to specify https_proxy:
# https_proxy="socks5://127.0.0.1:1080" ./golic.sh /path/to/go-module-proj
```
