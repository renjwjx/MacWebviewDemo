//
//  ViewController.m
//  cert-ba
//
//  Created by jinren on 11/2/17.
//  Copyright © 2017 jinren. All rights reserved.
//

#import "ViewController.h"
#import <Security/SecCertificate.h>
#import <Security/SecBase.h>
#import <WebKit/WebKit.h>
#import <SecurityInterface/SFCertificateTrustPanel.h>
#import <SecurityInterface/SFChooseIdentityPanel.h>



#define  SSO32_URL @"https://quxie-cucm105-2-pub.jabberqa.cisco.com:8443/ssosp/oauth/authorize?scope=UnifiedCommunications:readwrite&response_type=token&client_id=C41eb54529dd9907e01d3744ead3a991ba9cc4c772b0497ebe8a103fa69fe81a8"
#define CUSTOMER_EDGE @"https://exp-e2.tlabs.de:8443/dGxhYnMuZGU/authorize?response_type=token&realm=local&client_id=C41eb54529dd9907e01d3744ead3a991ba9cc4c772b0497ebe8a103fa69fe81a8&device_id=8090A21C-2961-439C-9A8C-B2C1CFB6426C&email=mende.christian@tlabs.de"


#define CUSTOMER_IDP @"https://sts.tlabs.de:49443/adfs/ls/?SAMLRequest=Ad4BIf48c2FtbHA6QXV0aG5SZXF1ZXN0IHhtbG5zOnNhbWxwPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6cHJvdG9jb2wiIEFzc2VydGlvbkNvbnN1bWVyU2VydmljZVVSTD0iaHR0cHM6Ly9leHAtZTIudGxhYnMuZGU6ODQ0My9kR3hoWW5NdVpHVS9mZWRsZXQiIERlc3RpbmF0aW9uPSJodHRwczovL3N0cy50bGFicy5kZS9hZGZzL2xzLyIgSUQ9ImlkLWY3OGRlZjAzLWNhNmQtNGFlMC04YzIxLTMwODg1YjBiOTkxZSIgSXNzdWVJbnN0YW50PSIyMDE3LTExLTIyVDEyOjU5OjIzWiIgUHJvdG9jb2xCaW5kaW5nPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6YmluZGluZ3M6SFRUUC1QT1NUIiBWZXJzaW9uPSIyLjAiPjxzYW1sOklzc3VlciB4bWxuczpzYW1sPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6YXNzZXJ0aW9uIj50bGFicy5kZS0tMkRGQUZFQTNDQTdBRDJCMjwvc2FtbDpJc3N1ZXI%2BPC9zYW1scDpBdXRoblJlcXVlc3Q%2B&SigAlg=http%3A%2F%2Fwww.w3.org%2F2001%2F04%2Fxmldsig-more%23rsa-sha256&Signature=ZA%2FQAs7m3LgHZmkyQ8iNWZ87XXLHN783RGf0rd63uOsFtyTJsqLOC%2FqL2S5Mo7aZdWQbdc8pPZr7YEg5yG4zxk7Au0c%2F8%2F7KxGsZjQ6UjzsowHeYPaxddKugenYzqK307xcnwM8Byo9F3rwJ9cF64FiDyXzWiTXJ7drqgJt4hufVBXDj9xlRnDJWaXu1nfbeXu2G%2BAvFwNA%2F2GO5c02UR8SRVbi69e%2FQLtvF7dhnejorggBvjrjbc66vtzWZC4aqu4jNtDpHSYCyrBplVzdMbfiRWkUkYkW0%2BReLOlXqkY5fFI5whQ56OEixWU6bwcHPd3MLWPcML%2BsdggmHzO5slw%3D%3D"

#define TEST_WEB @"https://www.google.com"
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    WKWebViewConfiguration* config = [[WKWebViewConfiguration alloc] init];
//    self.emWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, 500, 500) configuration:config];
    self.emWebView.navigationDelegate = self;
    self.emWebView.UIDelegate = self;
    // Do any additional setup after loading the view.
    [self.emWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:CUSTOMER_EDGE]]];


}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    NSString *authMethod = [[challenge protectionSpace] authenticationMethod];
    NSLog(@"receive Challenge:%@", authMethod);
    __block NSURLCredential *credential = nil;
    NSURLSessionAuthChallengeDisposition challengeType = NSURLSessionAuthChallengePerformDefaultHandling;
    
    if ([authMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        challengeType = NSURLSessionAuthChallengeUseCredential;
    } else if([authMethod isEqualToString:NSURLAuthenticationMethodClientCertificate])
    {
        credential = [self selectCredentialForCert];
        // TODO: server trust SecTrustRef
    
        challengeType = NSURLSessionAuthChallengeUseCredential;
        NSLog(@"certificate for client");
    }
    completionHandler(challengeType,credential);
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation
{
    NSLog(@"redirect: %@",webView.URL);
}


- (void)logMessageForStatus:(OSStatus)status
               functionName:(NSString *)functionName
{
    CFStringRef errorMessage;
    errorMessage = SecCopyErrorMessageString(status, NULL);
    NSLog(@"error after %@: %@", functionName, (__bridge NSString *)errorMessage);
    CFRelease(errorMessage);
}


- (NSURLCredential*)selectCredentialForCert
{
    CFArrayRef latestIdentities;
    CFArrayRef latestCertificates;
    SecIdentityRef identity = nil;
    NSURLCredential *credential = nil;
    NSMutableDictionary *filterDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             (__bridge id)kSecClassIdentity, kSecClass,
                                             kSecMatchLimitAll,              kSecMatchLimit,
                                             kCFBooleanTrue,                 kSecReturnRef,
                                             kCFBooleanTrue,                 kSecAttrCanVerify,
                                             //                                             kCFBooleanTrue,                 kSecMatchTrustedOnly,
                                             nil];
    
    OSStatus err = SecItemCopyMatching((__bridge CFDictionaryRef)(filterDictionary), (CFTypeRef *) &latestIdentities);
    
    SFChooseIdentityPanel *identityPanel = [SFChooseIdentityPanel sharedChooseIdentityPanel];
    [identityPanel setInformativeText:NSLocalizedString(@"A certificate to validate your identity is required. Select a certificate to use when you connect.", @"Label: Description for authentication dialog")];
    [identityPanel setAlternateButtonTitle:NSLocalizedString(@"Cancel", @"Button Title: Cancel")];
    
    if([identityPanel runModalForIdentities:(__bridge NSArray*)latestIdentities message:NSLocalizedString(@"Select a certificate", @"Label: Title for authentication dialog")])
    {
        // create an nsurlcredential with a certificate the user selected in the identity dialog
        identity = [identityPanel identity];
        credential = [NSURLCredential credentialWithIdentity:identity
                                                certificates:nil
                                                 persistence:NSURLCredentialPersistenceForSession];
    }
    return credential;
}

- (NSURLCredential*)createCredentialForCert
{
        
    CFArrayRef latestIdentities;
    CFArrayRef latestCertificates;
    SecIdentityRef identity = nil;
    NSURLCredential *credential = nil;
    NSMutableDictionary *filterDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             (__bridge id)kSecClassIdentity, kSecClass,
                                             kSecMatchLimitAll,              kSecMatchLimit,
                                             kCFBooleanTrue,                 kSecReturnRef,
                                             kCFBooleanTrue,                 kSecAttrCanVerify,
//                                             kCFBooleanTrue,                 kSecMatchTrustedOnly,
                                             nil];

    OSStatus err = SecItemCopyMatching((__bridge CFDictionaryRef)(filterDictionary), (CFTypeRef *) &latestIdentities);
    
    if(err == errSecSuccess)
    {
        SecCertificateRef certiforIdenti;
        CFStringRef commonName = NULL;
        NSArray* identis = (__bridge NSArray*)latestIdentities;
        for (id identi in identis) {
            SecIdentityRef idCert = (__bridge SecIdentityRef)identi;
            SecIdentityCopyCertificate(idCert, &certiforIdenti);
            SecCertificateCopyCommonName(certiforIdenti, &commonName);
            NSString* name = (__bridge NSString*)commonName;
            if ([name isEqualToString:@"Cisco.Test"]) {
                NSArray* certiArray = [NSArray arrayWithObjects:(__bridge id _Nonnull)(certiforIdenti), nil];
                credential = [NSURLCredential credentialWithIdentity:idCert
                                                        certificates:certiArray
                                                     persistence:NSURLCredentialPersistenceForSession];
                break;
            }
        }

    }
    return credential;
}

@end
