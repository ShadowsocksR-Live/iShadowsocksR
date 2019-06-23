[![donate button](https://img.shields.io/badge/$-donate-ff69b4.svg?maxAge=2592000&amp;style=flat)](https://github.com/haxpor/donate)

![GPLv3 License](https://img.shields.io/badge/License-GPLv3-blue.svg)

# iShadowsocksR 

## Important

Please read [this](https://github.com/ShadowsocksR-Live/iShadowsocksR/blob/master/ADHERE_LICENSE.md) first before you do anything with this project.  
In short, you need to respect to license of the project. You cannot copy the source code and publish to App Store.

---

## What is it?

iShadowsocksR is an iOS client that implements custom proxies with the leverage of Network Extension framework introduced by Apple since iOS 9.

Currently, iShadowsocksR is compatible with following proxies:

- [Shadowsocks](https://shadowsocks.org)
- [ShadowsocksR](https://github.com/breakwa11/shadowsocks-rss)

[Subscribe Telegram Channel](https://telegram.me/potatso) to get updates of Potatso.  
[Join Telegram Group](https://telegram.me/joinchat/BT0c4z49OGNZXwl9VsO0uQ) to chat with users.

Original Author: [@icodesign](https://twitter.com/icodesign_me)  
Swift 3 Maintainer: [@haxpor](https://twitter.com/haxpor)

## Project Info

iShadowsocksR has in total 25 (2 as submodules dependencies as used as local file in Cocoapod) dependencies as following

* 15 Cocoapod dependencies
* 10 submodules dependencies

The project is tested with Xcode `10.1 (10B61)` on iOS `12.1.4 (16D57)` device with cocoapod version `1.7.0`+.
If you experienced an expected issue, try to use those versions, if still experience the problem please file the issue.

## How to Build Project

Perform the following steps to be able to build the project.
Be warned that you **should not** call `pod update` as newer version of pod frameworks that iShadowsocksR depends on might break building process and there will be errors.

```
git clone https://github.com/ShadowsocksR-Live/iShadowsocksR.git
cd iShadowsocksR
git submodule update --init --recursive    # update git submodules
sudo gem install cocoapods
pod install                                # pull down dependencies into our project
cd Library/openssl
./build-libssl.sh --version=1.1.0f         # build OpenSSL library
```
Then open `iShadowsocksR.xcworkspace` with `Xcode` to Build and Run the project. Done.

## Tips

- If you are a China mainland developer, maybe you should set your git with proxy, such as SOCKS5 etc., or you can not pull some submodules because of `GFW`. Like this:
```
# Enable Proxy settings
git config --global http.proxy socks5://127.0.0.1:1080
git config --global https.proxy socks5://127.0.0.1:1080

# Disable Proxy settings
git config --global --unset-all http.proxy
git config --global --unset-all https.proxy
```
- You must have an Apple Developer account with an annual fee of $99.
- To compile the app running on your iOS device smoothly, you must search the project for the `com.ssrlive.issr` identifier string and replace it with your own identifier string.


## How To Contribute

Clone the project, make some changes or add a new feature, then make a pull request.

## Acknowlegements

We use the following services or open-source libraries. So we'd like show them highest respect and thank for bringing those great projects:

### Services

- [realm](https://realm.io/)

### Open-source Libraries

- [KissXML](https://github.com/robbiehanson/KissXML)
- [MMWormhole](https://github.com/mutualmobile/MMWormhole)
- [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket)
- [Cartography](https://github.com/robb/Cartography)
- [AsyncSwift](https://github.com/duemunk/Async)
- [Appirater](https://github.com/arashpayan/appirater)
- [Eureka](https://github.com/xmartlabs/Eureka)
- [MBProgressHUD](https://github.com/matej/MBProgressHUD)
- [CallbackURLKit](https://github.com/phimage/CallbackURLKit)
- [ISO8601DateFormatter](https://github.com/boredzo/iso-8601-date-formatter)
- [Alamofire](https://github.com/Alamofire/Alamofire)
- [ObjectMapper](https://github.com/Hearst-DD/ObjectMapper)
- [CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack)
- [AlamofireObjectMapper](https://github.com/tristanhimmelman/AlamofireObjectMapper)
- [YAML.framework](https://github.com/mirek/YAML.framework)
- [tun2socks-iOS](https://github.com/shadowsocks/tun2socks-iOS)
- [shadowsocks-libev](https://github.com/shadowsocks/shadowsocks-libev)
- [Antinat](http://antinat.sourceforge.net/)
- [Privoxy](https://www.privoxy.org/)

### Also we'd like to thank people that helped with the project

- [@Blankwonder](https://twitter.com/Blankwonder)
- [@龙七](#)
- [@haxpor](https://twitter.com/haxpor)
- TestFlight Users and [Telegram Group](https://telegram.me/joinchat/BT0c4z49OGNZXwl9VsO0uQ) users.

### Donate
- [@liqianyu](https://twitter.com/liqianyu)
- [@anonymous](#) x2

## Notice

Read more from [here](https://github.com/ShadowsocksR-Live/iShadowsocksR/blob/master/ADHERE_LICENSE.md).

## Support Us

The development covers a lot of complicated work, costing not only money but also time.
These are the way to support

- [Download Potatso from Apple Store](https://itunes.apple.com/app/apple-store/id1070901416?pt=2305194&ct=potatso.github&mt=8). (**Recommended**) 
- Donate with Alipay to original author. (Account: **leewongstudio.com@gmail.com**)
- Donate to swift3 maintainer (WeChat: http://imgur.com/lsAao62, or PayPal: haxpor@gmail.com)

## License

**You cannot just copy the project, and publish to App Store.**  Please read [this](https://github.com/ShadowsocksR-Live/iShadowsocksR/blob/master/ADHERE_LICENSE.md) first.

--

To be compatible with those libraries using GPL, we're distributing with GPLv3 license.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.

