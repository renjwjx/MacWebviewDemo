//
//  ViewController.h
//  cert-ba
//
//  Created by jinren on 11/2/17.
//  Copyright © 2017 jinren. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface ViewController : NSViewController <WKNavigationDelegate, WKUIDelegate>
@property (weak) IBOutlet WKWebView *emWebView;


@end

