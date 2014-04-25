# translomato-ios

Quick readme:

This project is a hack to use Google Spreadsheets as a repository of string localization in iOS apps.

This is meant to aid app localization. On app startup you will get an alert to pick which sheet to use from the document, to enable faster testing.

Warning! Use this only in development, be sure to persist your strings to the appropriate .strings file before publishing.

![](https://cld.pt/dl/download/81f0c551-3485-4a84-82a1-638d3c514612/translomato-example2.png)

## Usage:

1. Create a google spreadsheet. The first line is ignored. Each of the other lines are a string localization. The first column is the key and the second column the value. Each sheet should be a different language.
1. The spreadsheet must be published: File > Publish to the web.
1. Add the .h and .m files to your project
1. Include the .h the .pch file.
1. In the app delegate, wrap your application:didFinishLaunchingWithOptions: method with TMATO_BEGIN/TMATO_END macros. The parameter to TMATO_BEGIN() is the document key (get it from the document URL).
1. Use NSLocalizedString as usual.

~~~
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.

    TMATO_BEGIN(@"1jfZGfZQVCjtE1t6-IXx4QI4gC50uXX_xexgdfJO8XFI");

    NSLog(@"hello: %@", NSLocalizedString(@"hello", @""));
    NSLog(@"bye: %@", NSLocalizedString(@"bye", @""));

    TMATO_END;
    return YES;
}
~~~

![](https://cld.pt/dl/download/7b2141d1-a5fd-41bf-a6e5-e112f6f1b3bc/translomato-example1.png)

## Where next?

Nothing more for now, but we have a lot of ideas to implement here.

1. A web app to better manage the strings
2. Plural/gender handling
3. Realtime updates (instead of just on app startup)
4. Debug console
5. Better integration
6. Images/plist/xml/json file editing (so you can tweak some app parameters)
