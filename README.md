# nix-keysmith

Nix Flake for [Keysmith](https://github.com/dfinity/keysmith).

## Usage

```
read -s seed
```

```
echo $seed | keysmith private-key -f=- -i=0 -o=identity-0.pem -p
```
