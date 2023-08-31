# vial-web

## Building

```
git clone https://github.com/vial-kb/vial-web.git
cd vial-web
git clone https://github.com/vial-kb/vial-gui.git
git clone https://github.com/vial-kb/via-keymap-precompiled.git
./fetch-emsdk.sh
./fetch-deps.sh
./build-deps.sh
cd src
./build.sh
```


## Docker build

```
git clone https://github.com/vial-kb/vial-web.git
cd vial-web

docker build -t localrun/vial-web .

# once build is complete
docker run --rm -d -p 8000:8000 localrun/vial-web

# open browser to http://localhost:8000

```
