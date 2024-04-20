<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

An interactive text widget that supports collapsible and expandable content.

## Features

There are number of properties that you can modify.

- text
- textStyle
- animationDuration
- seeMoreText
- seeMoreStyle
- seeLessText
- seeLessStyle
- trimLength

## Dart Code Usage

```
SeeMoreWidget(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
              textStyle: TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w400,
              ),
              animationDuration: Duration(milliseconds: 200),
              seeMoreText: "See More",
              seeMoreStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              seeLessText: "See Less",
              seeLessStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              trimLength: 240,
            ),
```

![video](https://github.com/igloodev/see_more/assets/35443097/f20a3f37-dba1-4267-a5db-c3df7cd36c52)


