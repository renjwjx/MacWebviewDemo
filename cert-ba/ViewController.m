//
//  ViewController.m
//  cert-ba
//
//  Created by jinren on 11/2/17.
//  Copyright © 2017 jinren. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    [self.emWebView.mainFrame loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://exp-e2.tlabs.de:8443/dGxhYnMuZGU/authorize?response_type=token&realm=local&client_id=C41eb54529dd9907e01d3744ead3a991ba9cc4c772b0497ebe8a103fa69fe81a8&device_id=8090A21C-2961-439C-9A8C-B2C1CFB6426C&email=mende.christian@tlabs.de"]]];

}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
