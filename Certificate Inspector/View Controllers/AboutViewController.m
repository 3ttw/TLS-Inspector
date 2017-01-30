#import "AboutViewController.h"
#import "RecentDomains.h"
@import GTAppLinks;

@interface AboutViewController ()

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *opensslVersionLabel;
@property (weak, nonatomic) IBOutlet UISwitch *recentSwitch;
- (IBAction)recentSwitch:(UISwitch *)sender;
@property (strong, nonatomic) UIHelper * helper;
@property (strong, nonatomic) GTAppLinks * appLinks;

@end

@implementation AboutViewController

static NSString * PROJECT_GITHUB_URL = @"https://github.com/certificate-helper/Certificate-Inspector/";
static NSString * PROJECT_URL = @"https://certificate-inspector.com/";
static NSString * PROJECT_CONTRIBUTE_URL = @"https://github.com/certificate-helper/Certificate-Inspector/blob/master/CONTRIBUTE.md";
static NSString * PROJECT_TESTFLIGHT_APPLICATION = @"https://ianspence.com/certificate-inspector-beta.html";

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.recentSwitch setOn:[RecentDomains sharedInstance].saveRecentDomains];
    NSDictionary * infoDictionary = [[NSBundle mainBundle] infoDictionary];
    self.versionLabel.text = format(@"%@ (%@)", [infoDictionary objectForKey:@"CFBundleShortVersionString"], [infoDictionary objectForKey:(NSString *)kCFBundleVersionKey]);
    NSArray<NSString *> * alphabet = @[
                                       @"a", @"b", @"c", @"d", @"e", @"f", @"g", @"h", @"i",
                                       @"j", @"k", @"l", @"m", @"n", @"o", @"p", @"q", @"r",
                                       @"s", @"t", @"u", @"v", @"w", @"x", @"y", @"z"
                                       ];
    NSMutableArray<NSString *> * components = [NSMutableArray arrayWithArray:[OPENSSL_VERSION componentsSeparatedByString:@"."]];
    NSString * letter = [alphabet objectAtIndex:[[components lastObject] integerValue]];
    [components replaceObjectAtIndex:components.count-1 withObject:letter];

    self.opensslVersionLabel.text = [components componentsJoinedByString:@"."];
    self.helper = [UIHelper sharedInstance];
    self.appLinks = [GTAppLinks new];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell.reuseIdentifier isEqualToString:@"tell_friends"]) {
        NSString * blurb = format(@"Easily view and inspect X509 certificates on your iOS device. %@", PROJECT_URL);
        UIActivityViewController *activityController = [[UIActivityViewController alloc]
                                                        initWithActivityItems:@[blurb]
                                                        applicationActivities:nil];
        activityController.popoverPresentationController.sourceView = [cell viewWithTag:1];
        [self presentViewController:activityController animated:YES completion:nil];
    } else if ([cell.reuseIdentifier isEqualToString:@"rate_app"]) {
        [self.appLinks showAppInAppStore:GTAppStoreIDCertificateInspector inViewController:self dismissed:^{
            //
        }];
    } else if ([cell.reuseIdentifier isEqualToString:@"submit_feedback"]) {

        [self.helper
         presentActionSheetInViewController:self
         attachToTarget:[ActionTipTarget targetWithView:[cell viewWithTag:1]]
         title:l(@"What kind of feedback would you like to submit?")
         subtitle:l(@"All feedback is appreciated!")
         cancelButtonTitle:l(@"Cancel")
         items:@[
                 l(@"Something I Like"),
                 l(@"Something I Don't Like"),
                 l(@"Request a Feature"),
                 l(@"Report a Bug"),
                 l(@"Something else"),
                 ]
         dismissed:^(NSInteger selectedIndex) {
             switch (selectedIndex) {
                 case 0:
                     open_url(nstrcat(PROJECT_GITHUB_URL, @"issues/new?labels=commendation"));
                     break;
                 case 1:
                     open_url(nstrcat(PROJECT_GITHUB_URL, @"issues/new?labels=complaint"));
                     break;
                 case 2:
                     open_url(nstrcat(PROJECT_GITHUB_URL, @"issues/new?labels=enhancement"));
                     break;
                 case 3:
                     open_url(nstrcat(PROJECT_GITHUB_URL, @"issues/new?labels=bug"));
                     break;
                 case 4: {
                     [self.appLinks
                      showEmailComposeSheetForApp:APP_NAME_CERTIFICATE_INSPECTOR
                      email:APP_SUPPORT_EMAIL_CERTIFICATE_INSPECTOR
                      inViewController:self dismissed:^{
                         //
                     }];
                     break;
                 } default:
                     break;
             }
         }];
    } else if ([cell.reuseIdentifier isEqualToString:@"contribute"]) {
        open_url(PROJECT_CONTRIBUTE_URL);
    } else if ([cell.reuseIdentifier isEqualToString:@"beta"]) {
        open_url(PROJECT_TESTFLIGHT_APPLICATION);
    }
}

- (IBAction)recentSwitch:(UISwitch *)sender {
    [RecentDomains sharedInstance].saveRecentDomains = sender.isOn;
}

@end
