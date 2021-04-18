# ZPM Explorer
A graphic interface to explorer the applications inside InterSystems Package Manager

## Description
ZPM Explorer's idea is to make it easier for people to find out what ZPM offers. Every week, every day, a new app joins the ZPM world, so why not help developers and non-developers take advantage of this incredible world?!

## Prerequisites

Make sure you have [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) and [Docker desktop](https://www.docker.com/products/docker-desktop) installed.

## Installation 
Clone/git pull the repo into any local directory
```
$ git clone https://github.com/diashenrique/zpm-explorer.git
```

Open the terminal in this directory and run:

```
$ docker-compose build
```

3. Run the IRIS container with your project:

```
$ docker-compose up -d
```

## How to Test it

Open in the URL in browser: [http://localhost:52773/csp/irisapp/explorer.html](http://localhost:52773/csp/irisapp/explorer.html)

or using the VSCode link shortcurts:

![VS Code](https://raw.githubusercontent.com/diashenrique/zpm-explorer/master/images/vscode.png)

## How ZPM Explorer looks like

![ZPM Explorer](https://raw.githubusercontent.com/diashenrique/zpm-explorer/master/images/zpmexplorer.png)

### src folder
src/iris contains InterSystems IRIS Objectscript code
src/csp contains all the html,css,js files

### .vscode/settings.json

Settings file to let you immedietly code in VSCode with [VSCode ObjectScript plugin](https://marketplace.visualstudio.com/items?itemName=daimor.vscode-objectscript))

### .vscode/launch.json
Config file if you want to debug with VSCode ObjectScript

[Read about all the files in this artilce](https://community.intersystems.com/post/dockerfile-and-friends-or-how-run-and-collaborate-objectscript-projects-intersystems-iris)

## Dream team

- [Henrique Dias](https://community.intersystems.com/user/henrique-dias-2)
- [José Roberto Pereira](https://community.intersystems.com/user/jos%C3%A9-roberto-pereira-0)
  